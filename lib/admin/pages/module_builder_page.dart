import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../core/media/media_repository.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/format.dart';
import '../../features/session/session_provider.dart';
import '../widgets/admin_widgets.dart';
import 'modules_page.dart';
import 'users_page.dart';

class _ModuleData {
  _ModuleData(this.module, this.versions, this.targets, this.blocks, this.quiz, this.questions, this.rubric);
  final Map<String, dynamic> module;
  final List<Map<String, dynamic>> versions; // newest first
  final Set<String> targets;
  final List<Map<String, dynamic>> blocks;
  final Map<String, dynamic>? quiz;
  final List<Map<String, dynamic>> questions; // with question_options
  final List<Map<String, dynamic>> rubric;

  Map<String, dynamic> get version => versions.first;
  String get status => version['status'] as String;
  bool get editable => status == 'draft' || status == 'changes_requested';
}

final _moduleProvider = FutureProvider.family<_ModuleData, String>((ref, id) async {
  final db = ref.watch(supabaseProvider);
  final module = await db.from('modules').select('id, category, archived_at, created_by').eq('id', id).single();
  final versions = ((await db
          .from('module_versions')
          .select()
          .eq('module_id', id)
          .order('version', ascending: false)) as List)
      .cast<Map<String, dynamic>>();
  final v = versions.first['id'] as String;
  final results = await Future.wait<dynamic>([
    db.from('module_target_positions').select('position_id').eq('module_id', id),
    db.from('content_blocks').select('id, sort, type, title, body, media_file_id, media_files(status, duration_seconds, mime_type)').eq('module_version_id', v).order('sort'),
    db.from('quizzes').select().eq('module_version_id', v).maybeSingle(),
    db.from('rubric_criteria').select().eq('module_version_id', v).order('sort'),
  ]);
  final quiz = results[2] as Map<String, dynamic>?;
  var questions = <Map<String, dynamic>>[];
  if (quiz != null) {
    final qq = await db
        .from('quiz_questions')
        .select('sort, questions(id, prompt, explanation, question_options(id, label, is_correct, sort))')
        .eq('quiz_id', quiz['id'])
        .order('sort');
    questions = (qq as List).map((r) => Map<String, dynamic>.from(r['questions'] as Map)).toList();
  }
  return _ModuleData(
    module,
    versions,
    (results[0] as List).map((r) => r['position_id'] as String).toSet(),
    (results[1] as List).cast<Map<String, dynamic>>(),
    quiz,
    questions,
    (results[3] as List).cast<Map<String, dynamic>>(),
  );
});

/// Module builder: details, target positions, content blocks (video, SOP
/// card, PDF), quiz from the question bank, practical rubric, review (T1-T5).
class ModuleBuilderPage extends ConsumerWidget {
  const ModuleBuilderPage({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_moduleProvider(moduleId));
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(message: friendlyError(e), onRetry: () => ref.invalidate(_moduleProvider(moduleId))),
      data: (d) => _Builder(data: d),
    );
  }
}

class _Builder extends ConsumerStatefulWidget {
  const _Builder({required this.data});
  final _ModuleData data;

  @override
  ConsumerState<_Builder> createState() => _BuilderState();
}

class _BuilderState extends ConsumerState<_Builder> {
  late final _title = TextEditingController(text: v['title'] as String?);
  late final _category = TextEditingController(text: d.module['category'] as String?);
  late final _summary = TextEditingController(text: v['summary'] as String?);
  late final _minutes = TextEditingController(text: v['estimated_minutes']?.toString());
  late final _certDays = TextEditingController(text: v['certificate_valid_days']?.toString());
  late String? _prerequisite = v['prerequisite_module_id'] as String?;
  late bool _retraining = (v['requires_retraining'] as bool?) ?? false;
  bool _busy = false;

  _ModuleData get d => widget.data;
  Map<String, dynamic> get v => d.version;
  String get versionId => v['id'] as String;
  SupabaseClient get db => ref.read(supabaseProvider);

  void _reload() {
    ref.invalidate(_moduleProvider(d.module['id'] as String));
    ref.invalidate(modulesListProvider);
  }

  Future<void> _act(Future<void> Function() action, [String? ok]) async {
    setState(() => _busy = true);
    final done = await runAction(context, action, success: ok);
    if (mounted) setState(() => _busy = false);
    if (done) _reload();
  }

  Future<void> _saveDetails() => _act(() async {
        await db.from('modules').update({'category': _category.text.trim()}).eq('id', d.module['id']);
        await db.from('module_versions').update({
          'title': _title.text.trim(),
          'summary': _summary.text.trim().isEmpty ? null : _summary.text.trim(),
          'estimated_minutes': int.tryParse(_minutes.text.trim()),
          'certificate_valid_days': int.tryParse(_certDays.text.trim()),
          'prerequisite_module_id': _prerequisite,
          'requires_retraining': _retraining,
        }).eq('id', versionId);
      }, 'Saved');

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(requireSessionProvider);
    final me = session.profile.id;
    final canAuthor = session.hasGroup('module.author');
    final canReview = session.hasGroup('module.review');
    final editable = d.editable && canAuthor;
    final published = d.versions.where((x) => x['status'] == 'published').firstOrNull;

    final actions = <Widget>[
      StatusChip(d.status),
      if (editable) AdminButton('Save details', onPressed: _busy ? null : _saveDetails),
      if (editable)
        AdminButton('Submit for review',
            primary: true,
            onPressed: _busy
                ? null
                : () => _act(() async {
                      await _saveDetailsSilently();
                      await db.rpc('submit_module_for_review', params: {'p_version': versionId});
                    }, 'Sent to the training manager')),
      if (d.status == 'in_review' && canReview && v['author_id'] != me) ...[
        AdminButton('Request changes', onPressed: _busy ? null : () => _review(false)),
        AdminButton('Approve and publish', primary: true, onPressed: _busy ? null : () => _review(true)),
      ],
      if (d.status == 'in_review' && v['author_id'] == me)
        const Pill('Waiting for a training manager', tone: Tone.info),
      if ((d.status == 'published' || d.status == 'retired') && canAuthor)
        AdminButton('New version', icon: Icons.copy_all_outlined, primary: true, onPressed: _busy ? null : _newVersion),
    ];

    return AdminPage(
      breadcrumb: 'Learning modules / ${_title.text}',
      title: '${v['title']} · v${v['version']}',
      subtitle: published != null && published['id'] != v['id'] ? 'Staff currently learn v${published['version']}.' : null,
      actions: actions,
      children: [
        if (d.status == 'changes_requested' && v['review_comment'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InfoBanner(icon: Icons.rate_review_outlined, text: 'Changes requested: ${v['review_comment']}', danger: true),
          ),
        AdminSection(
          child: _DetailsForm(
            enabled: editable,
            title: _title,
            category: _category,
            summary: _summary,
            minutes: _minutes,
            certDays: _certDays,
            prerequisite: _prerequisite,
            moduleId: d.module['id'] as String,
            onPrerequisite: (x) => setState(() => _prerequisite = x),
            retraining: _retraining,
            onRetraining: (x) => setState(() => _retraining = x),
            showRetraining: (v['version'] as int) > 1,
          ),
        ),
        AdminSection(title: 'Positions', child: _Targets(data: d, enabled: canAuthor, onChanged: _reload)),
        AdminSection(
          title: 'Content',
          child: _Blocks(data: d, enabled: editable, onChanged: _reload),
        ),
        AdminSection(title: 'Quiz', child: _QuizEditor(data: d, enabled: editable, onChanged: _reload)),
        AdminSection(title: 'Practical test', child: _RubricEditor(data: d, enabled: editable, onChanged: _reload)),
        AdminSection(
          title: 'Versions',
          child: Column(
            children: [
              for (final x in d.versions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('v${x['version']} · ${x['title']}'),
                  subtitle: Text([
                    if (x['published_at'] != null) 'Published ${Fmt.day(DateTime.parse(x['published_at'] as String))}',
                    if (x['requires_retraining'] == true) 'retraining',
                    if (x['review_comment'] != null) '“${x['review_comment']}”',
                  ].join(' · ')),
                  trailing: StatusChip(x['status'] as String),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveDetailsSilently() async {
    await db.from('modules').update({'category': _category.text.trim()}).eq('id', d.module['id']);
    await db.from('module_versions').update({
      'title': _title.text.trim(),
      'summary': _summary.text.trim().isEmpty ? null : _summary.text.trim(),
      'estimated_minutes': int.tryParse(_minutes.text.trim()),
      'certificate_valid_days': int.tryParse(_certDays.text.trim()),
      'prerequisite_module_id': _prerequisite,
      'requires_retraining': _retraining,
    }).eq('id', versionId);
  }

  Future<void> _review(bool approve) async {
    String? comment;
    if (!approve) {
      comment = await promptText(context, title: 'What should the author change?');
      if (comment == null) return;
    } else {
      final go = await confirmDialog(context,
          title: 'Publish ${v['title']}?',
          message: _retraining
              ? 'Staff with this module open move to this version. It is marked "retraining needed", so people who finished the old version get it again.'
              : 'Staff with this module open move to this version.',
          confirm: 'Publish');
      if (!go) return;
    }
    await _act(
      () => db.rpc('review_module_version', params: {'p_version': versionId, 'p_approve': approve, 'p_comment': comment}),
      approve ? 'Published' : 'Sent back to the author',
    );
  }

  /// Copies the latest version (blocks, quiz, rubric) into a new draft (T5).
  Future<void> _newVersion() => _act(() async {
        final me = ref.read(requireSessionProvider).profile.id;
        final next = (v['version'] as int) + 1;
        final created = await db
            .from('module_versions')
            .insert({
              'module_id': d.module['id'],
              'version': next,
              'status': 'draft',
              'title': v['title'],
              'summary': v['summary'],
              'prerequisite_module_id': v['prerequisite_module_id'],
              'estimated_minutes': v['estimated_minutes'],
              'certificate_valid_days': v['certificate_valid_days'],
              'author_id': me,
            })
            .select('id')
            .single();
        final nv = created['id'] as String;
        if (d.blocks.isNotEmpty) {
          await db.from('content_blocks').insert([
            for (final b in d.blocks)
              {'module_version_id': nv, 'sort': b['sort'], 'type': b['type'], 'title': b['title'], 'body': b['body'], 'media_file_id': b['media_file_id']},
          ]);
        }
        if (d.rubric.isNotEmpty) {
          await db.from('rubric_criteria').insert([
            for (final r in d.rubric) {'module_version_id': nv, 'title': r['title'], 'description': r['description'], 'sort': r['sort']},
          ]);
        }
        if (d.quiz != null) {
          final q = d.quiz!;
          final nq = await db
              .from('quizzes')
              .insert({
                'module_version_id': nv,
                'pass_mark_pct': q['pass_mark_pct'],
                'max_attempts': q['max_attempts'],
                'time_limit_seconds': q['time_limit_seconds'],
                'question_count': q['question_count'],
                'randomize': q['randomize'],
              })
              .select('id')
              .single();
          if (d.questions.isNotEmpty) {
            await db.from('quiz_questions').insert([
              for (var i = 0; i < d.questions.length; i++) {'quiz_id': nq['id'], 'question_id': d.questions[i]['id'], 'sort': i},
            ]);
          }
        }
      }, 'Draft v${(v['version'] as int) + 1} created');
}

class _DetailsForm extends ConsumerWidget {
  const _DetailsForm({
    required this.enabled,
    required this.title,
    required this.category,
    required this.summary,
    required this.minutes,
    required this.certDays,
    required this.prerequisite,
    required this.moduleId,
    required this.onPrerequisite,
    required this.retraining,
    required this.onRetraining,
    required this.showRetraining,
  });

  final bool enabled;
  final TextEditingController title, category, summary, minutes, certDays;
  final String? prerequisite;
  final String moduleId;
  final ValueChanged<String?> onPrerequisite;
  final bool retraining;
  final ValueChanged<bool> onRetraining;
  final bool showRetraining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modules = ref.watch(modulesListProvider).value ?? [];
    final others = {
      for (final m in modules)
        if (m['id'] != moduleId && latestVersion(m) != null) m['id'] as String: latestVersion(m)!['title'] as String,
    };
    Widget field(Widget w) => SizedBox(width: 340, child: w);
    return AbsorbPointer(
      absorbing: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: Wrap(
          spacing: 20,
          runSpacing: 16,
          children: [
            field(FormText('Title', title)),
            field(FormText('Category', category)),
            SizedBox(width: 700, child: FormText('Summary', summary, maxLines: 2)),
            field(DropdownButtonFormField<String?>(
              initialValue: others.containsKey(prerequisite) ? prerequisite : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Prerequisite'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final e in others.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: onPrerequisite,
            )),
            SizedBox(width: 160, child: FormText('Minutes', minutes, number: true)),
            SizedBox(width: 160, child: FormText('Certificate days', certDays, number: true, hint: 'empty = none')),
            if (showRetraining)
              SizedBox(
                width: 520,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: retraining,
                  onChanged: (x) => onRetraining(x ?? false),
                  title: const Text('Retraining needed'),
                  subtitle: const Text('People who finished an earlier version get this one again when it is published.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Targets extends ConsumerWidget {
  const _Targets({required this.data, required this.enabled, required this.onChanged});
  final _ModuleData data;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positions = ref.watch(positionsProvider).value ?? [];
    final db = ref.read(supabaseProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in positions)
              FilterChip(
                label: Text(p.name),
                selected: data.targets.contains(p.id),
                onSelected: !enabled
                    ? null
                    : (on) async {
                        final ok = await runAction(context, () async {
                          if (on) {
                            await db.from('module_target_positions').insert({'module_id': data.module['id'], 'position_id': p.id});
                          } else {
                            await db.from('module_target_positions').delete().eq('module_id', data.module['id']).eq('position_id', p.id);
                          }
                        });
                        if (ok) onChanged();
                      },
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Who the module is for. Add it to a learning path to assign it.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Blocks extends ConsumerStatefulWidget {
  const _Blocks({required this.data, required this.enabled, required this.onChanged});
  final _ModuleData data;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  ConsumerState<_Blocks> createState() => _BlocksState();
}

class _BlocksState extends ConsumerState<_Blocks> {
  String? _uploading;

  SupabaseClient get db => ref.read(supabaseProvider);
  String get versionId => widget.data.version['id'] as String;
  int get nextSort => widget.data.blocks.fold<int>(0, (m, b) => (b['sort'] as int) > m ? b['sort'] as int : m) + 1;

  Future<void> _addFile(String type) async {
    final f = await FilePicker.pickFile(
      type: type == 'video' ? FileType.video : FileType.custom,
      allowedExtensions: type == 'video' ? null : ['pdf'],
    );
    if (f == null || !mounted) return;
    final title = await promptText(context, title: 'Title for this ${type == 'video' ? 'video' : 'PDF'}', required: false);
    if (!mounted) return;
    setState(() => _uploading = f.name);
    final media = ref.read(mediaRepositoryProvider);
    final ok = await runAction(context, () async {
      final mediaId = type == 'video'
          ? await media.uploadVideo(f.xFile, kind: 'training_video')
          : await media.uploadTrainingFile(await f.readAsBytes(), fileName: f.name, kind: 'training_document');
      await db.from('content_blocks').insert({
        'module_version_id': versionId,
        'sort': nextSort,
        'type': type,
        'title': (title ?? '').isEmpty ? f.name : title,
        'media_file_id': mediaId,
      });
    }, success: type == 'video' ? 'Uploaded. Cloudflare is processing the video.' : 'PDF added');
    if (mounted) setState(() => _uploading = null);
    if (ok) widget.onChanged();
  }

  Future<void> _editSop([Map<String, dynamic>? b]) async {
    final title = TextEditingController(text: b?['title'] as String?);
    final body = TextEditingController(text: b?['body'] as String?);
    PlatformFile? image;
    final ok = await showFormDialog(context,
        title: b == null ? 'SOP card' : 'Edit SOP card',
        width: 640,
        fields: [
          FormText('Title', title),
          FormText('Steps (Markdown: 1. Step one, **bold**)', body, maxLines: 12),
          StatefulBuilder(
            builder: (context, setState) => OutlinedButton.icon(
              onPressed: () async {
                final p = await FilePicker.pickFile(type: FileType.image);
                setState(() => image = p);
              },
              icon: const Icon(Icons.image_outlined),
              label: Text(image?.name ?? (b?['media_file_id'] != null ? 'Replace photo' : 'Add a photo (optional)')),
            ),
          ),
        ],
        onSave: () async {
          String? mediaId = b?['media_file_id'] as String?;
          if (image != null) {
            mediaId = await ref
                .read(mediaRepositoryProvider)
                .uploadTrainingFile(await image!.readAsBytes(), fileName: image!.name, kind: 'training_image');
          }
          final row = {'title': title.text.trim(), 'body': body.text, 'media_file_id': mediaId};
          if (b == null) {
            await db.from('content_blocks').insert({...row, 'module_version_id': versionId, 'sort': nextSort, 'type': 'sop_card'});
          } else {
            await db.from('content_blocks').update(row).eq('id', b['id']);
          }
        });
    if (ok) widget.onChanged();
  }

  /// Swap two blocks; (version, sort) is unique, so park one first.
  Future<void> _move(int i, int delta) async {
    final blocks = widget.data.blocks;
    final j = i + delta;
    if (j < 0 || j >= blocks.length) return;
    final a = blocks[i], b = blocks[j];
    final ok = await runAction(context, () async {
      await db.from('content_blocks').update({'sort': -1}).eq('id', a['id']);
      await db.from('content_blocks').update({'sort': a['sort']}).eq('id', b['id']);
      await db.from('content_blocks').update({'sort': b['sort']}).eq('id', a['id']);
    });
    if (ok) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.data.blocks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) _blockRow(i, blocks[i]),
        if (_uploading != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Text('Uploading $_uploading…'),
            ]),
          ),
        if (widget.enabled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 10, runSpacing: 10, children: [
              AdminButton('Video', icon: Icons.videocam_outlined, onPressed: _uploading == null ? () => _addFile('video') : null),
              AdminButton('SOP card', icon: Icons.notes_rounded, onPressed: () => _editSop()),
              AdminButton('PDF', icon: Icons.picture_as_pdf_outlined, onPressed: _uploading == null ? () => _addFile('document') : null),
            ]),
          ),
      ],
    );
  }

  Widget _blockRow(int i, Map<String, dynamic> b) {
    final type = b['type'] as String;
    final media = b['media_files'] as Map<String, dynamic>?;
    final detail = switch (type) {
      'video' => [
          'Video',
          if (media?['duration_seconds'] != null) Fmt.duration(media!['duration_seconds'] as int),
          if (media?['status'] != null && media!['status'] != 'ready') media['status'],
        ].join(' · '),
      'document' => 'PDF',
      _ => 'SOP card · ${(b['body'] as String? ?? '').split('\n').where((l) => l.trim().isNotEmpty).length} lines'
          '${b['media_file_id'] != null ? ' · photo' : ''}',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AppColors.inputBorder, width: 1.5), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(switch (type) { 'video' => Icons.videocam_outlined, 'document' => Icons.picture_as_pdf_outlined, _ => Icons.notes_rounded },
              size: 20, color: AppColors.textStrong),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: b['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: '  ·  $detail', style: const TextStyle(color: AppColors.textSecondary)),
            ])),
          ),
          if (widget.enabled) ...[
            IconButton(tooltip: 'Move up', onPressed: () => _move(i, -1), icon: const Icon(Icons.arrow_upward, size: 18)),
            IconButton(tooltip: 'Move down', onPressed: () => _move(i, 1), icon: const Icon(Icons.arrow_downward, size: 18)),
            if (type == 'sop_card')
              IconButton(tooltip: 'Edit', onPressed: () => _editSop(b), icon: const Icon(Icons.edit_outlined, size: 18)),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
              onPressed: () async {
                final ok = await runAction(context, () => db.from('content_blocks').delete().eq('id', b['id']));
                if (ok) widget.onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizEditor extends ConsumerWidget {
  const _QuizEditor({required this.data, required this.enabled, required this.onChanged});
  final _ModuleData data;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(supabaseProvider);
    final quiz = data.quiz;
    if (quiz == null) {
      return Row(children: [
        const Expanded(child: Text('No quiz. Add one to check understanding (multiple choice, graded on the server).')),
        if (enabled)
          AdminButton('Add quiz', icon: Icons.add, onPressed: () async {
            final ok = await runAction(context, () => db.from('quizzes').insert({'module_version_id': data.version['id']}));
            if (ok) onChanged();
          }),
      ]);
    }

    Future<void> settings() async {
      final pass = TextEditingController(text: '${quiz['pass_mark_pct']}');
      final attempts = TextEditingController(text: quiz['max_attempts']?.toString() ?? '');
      final count = TextEditingController(text: quiz['question_count']?.toString() ?? '');
      final limit = TextEditingController(text: quiz['time_limit_seconds'] == null ? '' : '${(quiz['time_limit_seconds'] as int) ~/ 60}');
      var randomize = quiz['randomize'] as bool;
      final ok = await showFormDialog(context,
          title: 'Quiz settings',
          fields: [
            FormText('Pass mark (%)', pass, number: true),
            FormText('Number of tries (empty = unlimited)', attempts, number: true),
            FormText('Questions per attempt (empty = all)', count, number: true),
            FormText('Time limit in minutes (empty = none)', limit, number: true),
            FormCheck('Random question and answer order', initial: randomize, onChanged: (v) => randomize = v),
          ],
          onSave: () => db.from('quizzes').update({
                'pass_mark_pct': int.parse(pass.text.trim()),
                'max_attempts': int.tryParse(attempts.text.trim()),
                'question_count': int.tryParse(count.text.trim()),
                'time_limit_seconds': int.tryParse(limit.text.trim()) == null ? null : int.parse(limit.text.trim()) * 60,
                'randomize': randomize,
              }).eq('id', quiz['id']));
      if (ok) onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: Text(
              '${data.questions.length} questions · pass mark ${quiz['pass_mark_pct']}% · '
              '${quiz['max_attempts'] == null ? 'unlimited tries' : '${quiz['max_attempts']} tries'}'
              '${quiz['randomize'] == true ? ' · random order' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (enabled) TextButton(onPressed: settings, child: const Text('Settings')),
        ]),
        const SizedBox(height: 8),
        for (final q in data.questions)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['prompt'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      for (final o in ((q['question_options'] as List).cast<Map<String, dynamic>>()
                        ..sort((a, b) => (a['sort'] as int).compareTo(b['sort'] as int))))
                        Text('${o['is_correct'] == true ? '✓' : '·'}  ${o['label']}',
                            style: TextStyle(
                                color: o['is_correct'] == true ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: o['is_correct'] == true ? FontWeight.w700 : FontWeight.w400)),
                    ],
                  ),
                ),
                if (enabled) ...[
                  IconButton(
                      tooltip: 'Edit', icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _editQuestion(context, ref, q)),
                  IconButton(
                    tooltip: 'Remove from quiz',
                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
                    onPressed: () async {
                      final ok = await runAction(
                          context, () => db.from('quiz_questions').delete().eq('quiz_id', quiz['id']).eq('question_id', q['id']));
                      if (ok) onChanged();
                    },
                  ),
                ],
              ],
            ),
          ),
        if (enabled)
          Wrap(spacing: 10, children: [
            AdminButton('New question', icon: Icons.add, onPressed: () => _editQuestion(context, ref)),
            AdminButton('From question bank', icon: Icons.inventory_2_outlined, onPressed: () => _fromBank(context, ref)),
          ]),
      ],
    );
  }

  /// Question with options; exactly one correct answer.
  Future<void> _editQuestion(BuildContext context, WidgetRef ref, [Map<String, dynamic>? q]) async {
    final db = ref.read(supabaseProvider);
    final me = ref.read(requireSessionProvider).profile.id;
    final prompt = TextEditingController(text: q?['prompt'] as String?);
    final existing = ((q?['question_options'] as List?) ?? []).cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['sort'] as int).compareTo(b['sort'] as int));
    final options = [
      for (final o in existing) TextEditingController(text: o['label'] as String),
      for (var i = existing.length; i < 4; i++) TextEditingController(),
    ];
    var correct = existing.indexWhere((o) => o['is_correct'] == true);
    if (correct < 0) correct = 0;

    final ok = await showFormDialog(context,
        title: q == null ? 'New question' : 'Edit question',
        width: 600,
        fields: [
          FormText('Question', prompt, maxLines: 2),
          StatefulBuilder(
            builder: (context, setState) => RadioGroup<int>(
              groupValue: correct,
              onChanged: (v) => setState(() => correct = v ?? 0),
              child: Column(children: [
                for (var i = 0; i < options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Radio<int>(value: i),
                      Expanded(child: FormText('Answer ${i + 1}${i == correct ? ' (correct)' : ''}', options[i])),
                    ]),
                  ),
              ]),
            ),
          ),
          const Text('Pick the correct answer. Empty answers are left out. Staff never see which one is correct.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
        onSave: () async {
          final labels = [for (var i = 0; i < options.length; i++) (i: i, text: options[i].text.trim())]
              .where((o) => o.text.isNotEmpty)
              .toList();
          if (labels.length < 2) throw Exception('Add at least two answers');
          if (!labels.any((o) => o.i == correct)) throw Exception('The correct answer is empty');
          String qid;
          if (q == null) {
            final row = await db.from('questions').insert({'prompt': prompt.text.trim(), 'topic': data.module['category'], 'created_by': me}).select('id').single();
            qid = row['id'] as String;
            await db.from('quiz_questions').insert({'quiz_id': data.quiz!['id'], 'question_id': qid, 'sort': data.questions.length});
          } else {
            qid = q['id'] as String;
            await db.from('questions').update({'prompt': prompt.text.trim()}).eq('id', qid);
            await db.from('question_options').delete().eq('question_id', qid);
          }
          await db.from('question_options').insert([
            for (var k = 0; k < labels.length; k++)
              {'question_id': qid, 'label': labels[k].text, 'is_correct': labels[k].i == correct, 'sort': k},
          ]);
        });
    if (ok) onChanged();
  }

  Future<void> _fromBank(BuildContext context, WidgetRef ref) async {
    final db = ref.read(supabaseProvider);
    final have = data.questions.map((q) => q['id']).toSet();
    final rows = ((await db.from('questions').select('id, prompt, topic').isFilter('archived_at', null).order('topic')) as List)
        .cast<Map<String, dynamic>>()
        .where((q) => !have.contains(q['id']))
        .toList();
    if (!context.mounted) return;
    final picked = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Question bank'),
          content: SizedBox(
            width: 600,
            height: 480,
            child: rows.isEmpty
                ? const Text('No other questions in the bank yet.')
                : ListView(children: [
                    for (final q in rows)
                      CheckboxListTile(
                        value: picked.contains(q['id']),
                        title: Text(q['prompt'] as String),
                        subtitle: q['topic'] == null ? null : Text(q['topic'] as String),
                        onChanged: (v) => setState(() => v == true ? picked.add(q['id'] as String) : picked.remove(q['id'])),
                      ),
                  ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Add ${picked.length}'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || picked.isEmpty || !context.mounted) return;
    final done = await runAction(
        context,
        () => db.from('quiz_questions').insert([
              for (final (k, id) in picked.indexed) {'quiz_id': data.quiz!['id'], 'question_id': id, 'sort': data.questions.length + k},
            ]));
    if (done) onChanged();
  }
}

class _RubricEditor extends ConsumerWidget {
  const _RubricEditor({required this.data, required this.enabled, required this.onChanged});
  final _ModuleData data;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(supabaseProvider);
    Future<void> edit([Map<String, dynamic>? r]) async {
      final title = TextEditingController(text: r?['title'] as String?);
      final description = TextEditingController(text: r?['description'] as String?);
      final ok = await showFormDialog(context,
          title: r == null ? 'Rubric line' : 'Edit rubric line',
          fields: [FormText('What the mentor checks', title, hint: 'e.g. Grip and balance'), FormText('How to judge it (optional)', description, maxLines: 2)],
          onSave: () async {
            final row = {'title': title.text.trim(), 'description': description.text.trim().isEmpty ? null : description.text.trim()};
            if (r == null) {
              await db.from('rubric_criteria').insert({...row, 'module_version_id': data.version['id'], 'sort': data.rubric.length});
            } else {
              await db.from('rubric_criteria').update(row).eq('id', r['id']);
            }
          });
      if (ok) onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data.rubric.isEmpty
              ? 'No practical test. Add rubric lines and the trainee records a video in the app; their mentor scores each line pass or redo.'
              : '${data.rubric.length} rubric lines · recorded in the app · scored by the mentor',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        for (final r in data.rubric)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
            title: Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: r['description'] == null ? null : Text(r['description'] as String),
            trailing: enabled
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => edit(r)),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      onPressed: () async {
                        final ok = await runAction(context, () => db.from('rubric_criteria').delete().eq('id', r['id']));
                        if (ok) onChanged();
                      },
                    ),
                  ])
                : null,
          ),
        if (enabled) Align(alignment: Alignment.centerLeft, child: AdminButton('Add rubric line', icon: Icons.add, onPressed: () => edit())),
      ],
    );
  }
}
