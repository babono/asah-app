import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum Tone { primary, warning, danger, info, neutral, accent }

extension ToneColors on Tone {
  Color get fg => switch (this) {
        Tone.primary => AppColors.primary,
        Tone.warning => AppColors.warning,
        Tone.danger => AppColors.danger,
        Tone.info => AppColors.info,
        Tone.neutral => AppColors.textSecondary,
        Tone.accent => AppColors.onAccent,
      };
  Color get bg => switch (this) {
        Tone.primary => AppColors.primarySoft,
        Tone.warning => AppColors.warningSoft,
        Tone.danger => AppColors.dangerSoft,
        Tone.info => AppColors.infoSoft,
        Tone.neutral => AppColors.track,
        Tone.accent => AppColors.accent,
      };
}

/// Small rounded status label ("Due 09:00", "Behind", "Not assigned").
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = Tone.primary, this.icon, this.small = false});
  final String label;
  final Tone tone;
  final IconData? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 3 : 4),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: tone.fg), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(fontSize: small ? 11 : 12, fontWeight: FontWeight.w700, color: tone.fg),
          ),
        ],
      ),
    );
  }
}

/// Thin rounded progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.background = AppColors.track,
    this.height = 6,
  });
  final double value;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1).toDouble(),
        minHeight: height,
        color: color,
        backgroundColor: background,
      ),
    );
  }
}

/// 44x44 rounded square with an icon, used at the start of task cards.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.tone = Tone.primary, this.size = 44});
  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 22, color: tone.fg),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.tone = Tone.primary, this.size = 44});
  final String name;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
      child: Text(letter, style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w800, color: tone.fg)),
    );
  }
}

/// A stat tile ("9/12 Checklists done").
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.alert = false});
  final String value;
  final String label;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: alert ? AppColors.dangerSoft : AppColors.surface,
        border: Border.all(color: alert ? AppColors.dangerBorder : AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: alert ? AppColors.danger : AppColors.text)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: alert ? AppColors.dangerDark : AppColors.textSecondary)),
        ],
      ),
    );
  }
}
