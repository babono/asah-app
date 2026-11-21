import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../utils/errors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Large header at the top of a tab (Today, My trainees...).
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    this.overline,
    required this.title,
    this.caption,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 16),
  });
  final EdgeInsetsGeometry padding;
  final String? overline;
  final String title;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null)
                  Text(overline!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (caption != null) ...[
                  const SizedBox(height: 4),
                  Text(caption!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Two-line app bar title ("Opening checklist" / "3 of 12 done · Due 09:00").
class TwoLineTitle extends StatelessWidget {
  const TwoLineTitle(this.title, this.subtitle, {super.key});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Text(subtitle!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text, this.danger = false});
  final IconData icon;
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? AppColors.danger : AppColors.info;
    final bg = danger ? AppColors.dangerSoft : AppColors.infoSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg))),
        ],
      ),
    );
  }
}

/// Bottom action area with a top border, like the design's sticky footers.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// Pass / Redo, Yes / No style toggle buttons.
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.negative = false,
    this.compact = false,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool negative;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final on = negative ? AppColors.danger : AppColors.primary;
    final onBg = negative ? AppColors.dangerSoft : AppColors.primarySoft;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? onBg : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 999 : 12),
          side: BorderSide(color: selected ? on : AppColors.inputBorder, width: 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 999 : 12)),
          onTap: onTap,
          child: Container(
            height: compact ? 40 : 48,
            constraints: BoxConstraints(minWidth: compact ? 64 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w700,
                color: selected ? on : (compact ? AppColors.textSecondary : AppColors.textStrong),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.text,
    ));
}

/// Runs an action with a busy flag and shows its error as a snackbar.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (context.mounted && success != null) showSnack(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showSnack(context, friendlyError(e), error: true);
    return false;
  }
}

Future<bool> confirmDialog(BuildContext context, {required String title, String? message, String? confirm}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirm ?? context.l10n.ok)),
      ],
    ),
  );
  return ok ?? false;
}

/// Prompt for a short text (reasons, notes).
Future<String?> promptText(BuildContext context,
    {required String title, String? hint, bool required = true, int maxLines = 3}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
        TextButton(
          onPressed: () {
            final v = controller.text.trim();
            if (required && v.isEmpty) return;
            Navigator.pop(ctx, v);
          },
          child: Text(context.l10n.ok),
        ),
      ],
    ),
  );
  return result;
}
