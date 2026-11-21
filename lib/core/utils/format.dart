import 'package:intl/intl.dart';

/// Date and time formatting in the active locale.
class Fmt {
  Fmt._();

  static String time(DateTime d) => DateFormat.Hm().format(d.toLocal());
  static String day(DateTime d) => DateFormat.MMMd().format(d.toLocal());
  static String dayTime(DateTime d) => DateFormat('d MMM, HH:mm').format(d.toLocal());
  static String weekday(DateTime d) => DateFormat.EEEE().format(d.toLocal());
  static String fullDate(DateTime d) => DateFormat.yMMMMd().format(d.toLocal());

  static String duration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String pct(num? v) => v == null ? '–' : '${v.round()}%';

  static String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Monday of the week containing [d] (mentor check-ins are one per week).
  static DateTime weekStart(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.first[0].toUpperCase();
  }
}

DateTime? parseTs(Object? v) => v == null ? null : DateTime.parse(v as String);
num? asNum(Object? v) => v is num ? v : (v is String ? num.tryParse(v) : null);
