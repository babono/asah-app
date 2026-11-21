import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The ASAH mark: an "A" on an amber tile, and the wordmark.
class AsahMark extends StatelessWidget {
  const AsahMark({super.key, this.size = 44, this.background = AppColors.accent, this.foreground = AppColors.primary});
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.28)),
      child: CustomPaint(painter: _APainter(foreground)),
    );
  }
}

class _APainter extends CustomPainter {
  _APainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(5 * s + size.width * 0.0, 20 * s)
      ..lineTo(12 * s, 4 * s)
      ..lineTo(19 * s, 20 * s)
      ..moveTo(8 * s, 13 * s)
      ..lineTo(16 * s, 13 * s);
    canvas.save();
    canvas.translate(size.width * 0.5 - 12 * s * 0.75, size.height * 0.5 - 12 * s * 0.75);
    canvas.scale(0.75);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_APainter old) => old.color != color;
}

class AsahWordmark extends StatelessWidget {
  const AsahWordmark({super.key, this.light = true});
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AsahMark(),
        const SizedBox(width: 10),
        Text('ASAH',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2.2, color: light ? Colors.white : AppColors.text)),
      ],
    );
  }
}
