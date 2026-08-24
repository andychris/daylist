import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/day_rings.dart';
import 'day_cell_painter.dart';

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.rings,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DayRings rings;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      // A future day hasn't happened yet — nothing to show detail for.
      onTap: isFuture
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: DayCellPainter(
                progressFraction: rings.progressFraction,
                consistencyFraction: rings.consistencyFraction,
                ringColor: colorScheme.primary,
                trackColor: colorScheme.surfaceContainerHighest,
                tintColor: colorScheme.primary,
                isToday: isToday,
                isFuture: isFuture,
              ),
              size: Size.infinite,
            ),
            Text(
              '${rings.date.day}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isFuture
                    ? colorScheme.outline.withValues(alpha: 0.4)
                    : null,
              ),
            ),
            if (!isFuture)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rings.hasGoal
                        ? colorScheme.primary
                        : Colors.transparent,
                    border: rings.hasGoal
                        ? null
                        : Border.all(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
