import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/widgets.dart';

export '../../core/widgets/widgets.dart';

/// Page frame for the admin web: breadcrumb, title, actions, content.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    this.breadcrumb,
    this.subtitle,
    this.actions = const [],
    required this.children,
  });

  final String title;
  final String? breadcrumb;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          runSpacing: 12,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (breadcrumb != null)
                  Text(breadcrumb!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ],
            ),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

/// White section card with a heading.
class AdminSection extends StatelessWidget {
  const AdminSection({super.key, this.title, this.trailing, required this.child, this.padding = const EdgeInsets.all(24)});
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || trailing != null) ...[
            Row(
              children: [
                if (title != null)
                  Expanded(child: Text(title!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Compact buttons for the web (the phone theme makes buttons full width).
class AdminButton extends StatelessWidget {
  const AdminButton(this.label, {super.key, this.onPressed, this.icon, this.primary = false, this.danger = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      foregroundColor: danger ? const WidgetStatePropertyAll(AppColors.danger) : null,
    );
    final child = icon == null
        ? Text(label)
        : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)]);
    return primary
        ? FilledButton(style: style, onPressed: onPressed, child: child)
        : OutlinedButton(style: style, onPressed: onPressed, child: child);
  }
}

/// Table with the design's header style; scrolls sideways on narrow screens.
class AdminTable extends StatelessWidget {
  const AdminTable({super.key, required this.columns, required this.rows, this.minWidth = 640});
  final List<String> columns;
  final List<DataRow> rows;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: c.maxWidth < minWidth ? minWidth : c.maxWidth),
          child: DataTable(
            headingTextStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.textSecondary),
            dataTextStyle: const TextStyle(fontSize: 14, color: AppColors.text),
            dividerThickness: 1,
            horizontalMargin: 12,
            columnSpacing: 24,
            showCheckboxColumn: false,
            columns: [for (final c in columns) DataColumn(label: Text(c.toUpperCase()))],
            rows: rows,
          ),
        ),
      ),
    );
  }
}

/// Builds a page body from a FutureProvider value.
class AdminAsync<T> extends ConsumerWidget {
  const AdminAsync({super.key, required this.value, required this.builder, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: builder,
      loading: () => const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorState(message: friendlyError(e), onRetry: onRetry),
    );
  }
}

/// A form dialog: fields stacked, Save returns true.
Future<bool> showFormDialog(
  BuildContext context, {
  required String title,
  required List<Widget> fields,
  String save = 'Save',
  Future<void> Function()? onSave,
  double width = 520,
}) async {
  var busy = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: 14), child: f)],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: busy
                ? null
                : () async {
                    if (onSave == null) return Navigator.pop(ctx, true);
                    setState(() => busy = true);
                    try {
                      await onSave();
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (ctx.mounted) showSnack(ctx, friendlyError(e), error: true);
                      setState(() => busy = false);
                    }
                  },
            child: Text(save),
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}

/// Labelled text field for dialogs and forms.
class FormText extends StatelessWidget {
  const FormText(this.label, this.controller, {super.key, this.hint, this.maxLines = 1, this.number = false});
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final bool number;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: 1,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true, signed: true) : null,
        decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: maxLines > 1),
      );
}

/// Dropdown that keeps its own selection, for use inside dialogs.
class FormSelect<T> extends StatefulWidget {
  const FormSelect(this.label, {super.key, required this.items, required this.initial, required this.onChanged});
  final String label;
  final Map<T, String> items;
  final T? initial;
  final ValueChanged<T?> onChanged;

  @override
  State<FormSelect<T>> createState() => _FormSelectState<T>();
}

class _FormSelectState<T> extends State<FormSelect<T>> {
  late T? _value = widget.items.containsKey(widget.initial) ? widget.initial : null;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        initialValue: _value,
        isExpanded: true,
        decoration: InputDecoration(labelText: widget.label),
        items: [for (final e in widget.items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
        onChanged: (v) {
          setState(() => _value = v);
          widget.onChanged(v);
        },
      );
}

/// Checkbox row that keeps its own state, for dialogs.
class FormCheck extends StatefulWidget {
  const FormCheck(this.label, {super.key, required this.initial, required this.onChanged});
  final String label;
  final bool initial;
  final ValueChanged<bool> onChanged;

  @override
  State<FormCheck> createState() => _FormCheckState();
}

class _FormCheckState extends State<FormCheck> {
  late bool _v = widget.initial;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(widget.label),
        value: _v,
        onChanged: (v) {
          setState(() => _v = v ?? false);
          widget.onChanged(_v);
        },
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      'published' => ('Published', Tone.primary),
      'in_review' => ('In review', Tone.info),
      'changes_requested' => ('Changes requested', Tone.danger),
      'retired' => ('Retired', Tone.neutral),
      'draft' => ('Draft', Tone.warning),
      'archived' => ('Archived', Tone.neutral),
      'active' => ('Active', Tone.primary),
      'inactive' => ('Inactive', Tone.neutral),
      'open' => ('Open', Tone.danger),
      'fixed' => ('Check fix', Tone.info),
      'closed' => ('Closed', Tone.primary),
      _ => (status, Tone.neutral),
    };
    return Pill(label, tone: tone, small: true);
  }
}
