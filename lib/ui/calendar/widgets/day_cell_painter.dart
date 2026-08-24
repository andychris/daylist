import 'dart:math';

import 'package:flutter/material.dart';

/// Paints a day cell's background consistency tint and progress ring in one
/// pass. Deliberately a CustomPainter rather than stacked
/// CircularProgressIndicators — a month grid renders ~30-42 of these at
/// once, and a single static paint per cell is far cheaper than that many
/// indicator RenderObjects.
class DayCellPainter extends CustomPainter {
  DayCellPainter({
    required this.progressFraction,
    required this.consistencyFraction,
    required this.ringColor,
    required this.trackColor,
    required this.tintColor,
    required this.isToday,
    required this.isFuture,
  });

  final double progressFraction;
  final double? consistencyFraction;
  final Color ringColor;
  final Color trackColor;
  final Color tintColor;
  final bool isToday;
  final bool isFuture;

  @override
  void paint(Canvas canvas, Size size) {
    // A future day hasn't happened yet — no tint/ring/today-outline to show.
    if (isFuture) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final tintOpacity = ((consistencyFraction ?? 0) * 0.4).clamp(0.0, 0.4);
    if (tintOpacity > 0) {
      canvas.drawRRect(rrect, Paint()..color = tintColor.withValues(alpha: tintOpacity));
    }

    if (isToday) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final center = rect.center;
    final cellRadius = size.shortestSide / 2;
    final strokeWidth = cellRadius * 0.16;
    final ringRadius = cellRadius - strokeWidth - 2;

    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progressFraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -pi / 2,
        2 * pi * progressFraction.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DayCellPainter oldDelegate) {
    return oldDelegate.progressFraction != progressFraction ||
        oldDelegate.consistencyFraction != consistencyFraction ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.tintColor != tintColor ||
        oldDelegate.isToday != isToday ||
        oldDelegate.isFuture != isFuture;
  }
}
