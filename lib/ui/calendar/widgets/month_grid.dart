import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/models/day_rings.dart';
import 'day_cell.dart';

const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.monthAnchor,
    required this.rings,
    required this.today,
    required this.onDayTap,
  });

  final DateTime monthAnchor;
  final List<DayRings> rings;
  final DateTime today;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final daysInMonth = DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    // DateTime.weekday: Monday=1..Sunday=7; %7 turns that into a Sunday-first
    // offset (Sunday=0..Saturday=6) matching _weekdayLabels.
    final leadingBlanks = monthStart.weekday % 7;

    final ringsByDate = {for (final r in rings) r.date: r};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: _weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();

            final day = index - leadingBlanks + 1;
            final date = DateTime(monthAnchor.year, monthAnchor.month, day);
            final dayRings = ringsByDate[date];
            if (dayRings == null) return const SizedBox.shrink();

            return DayCell(
                  rings: dayRings,
                  isToday: date == today,
                  isFuture: date.isAfter(today),
                  onTap: () => onDayTap(date),
                )
                .animate(delay: (12 * index).ms)
                .fadeIn(duration: 200.ms)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  duration: 200.ms,
                  curve: Curves.easeOut,
                );
          },
        ),
      ],
    );
  }
}
