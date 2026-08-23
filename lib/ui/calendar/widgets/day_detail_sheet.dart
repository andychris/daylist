import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/day_rings.dart';
import '../../../providers/history_providers.dart';
import '../../home/widgets/animated_checkbox.dart';
import 'labeled_ring.dart';

class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({super.key, required this.rings});

  final DayRings rings;

  static Future<void> show(BuildContext context, DayRings rings) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayDetailSheet(rings: rings),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemsAsync = ref.watch(dayDetailProvider(rings.date));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(rings.date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                LabeledRing(
                  label: 'Goal',
                  fraction: rings.hasGoal ? 1 : 0,
                  centerText: rings.hasGoal ? '✓' : '–',
                  color: colorScheme.primary,
                ),
                LabeledRing(
                  label: 'Progress',
                  fraction: rings.progressFraction,
                  centerText: '${rings.completed}/${rings.totalActive}',
                  color: colorScheme.primary,
                ),
                LabeledRing(
                  label: '7-day avg',
                  fraction: rings.consistencyFraction,
                  centerText: rings.consistencyFraction == null
                      ? '–'
                      : '${(rings.consistencyFraction! * 100).round()}%',
                  color: colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            itemsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Something went wrong: $error'),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No tasks that day.'),
                  );
                }
                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              AnimatedCheckbox(checked: item.isDoneToday),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    decoration: item.isDoneToday
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: item.isDoneToday
                                        ? colorScheme.outline
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
