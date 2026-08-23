import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/history_repository.dart';
import '../domain/calendar_rings.dart';
import '../domain/date_utils.dart';
import '../domain/models/checklist_item.dart';
import '../domain/models/day_rings.dart';
import '../domain/models/task_lifespan.dart';
import 'database_provider.dart';

const _consistencyLookbackDays = 6;

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(databaseProvider));
});

DateTime _monthStartOf(DateTime monthAnchor) =>
    DateTime(monthAnchor.year, monthAnchor.month, 1);

DateTime _monthEndOf(DateTime monthAnchor) =>
    DateTime(monthAnchor.year, monthAnchor.month + 1, 0);

final _monthTaskLifespansProvider =
    StreamProvider.autoDispose.family<List<TaskLifespan>, DateTime>((
      ref,
      monthAnchor,
    ) {
      final monthStart = _monthStartOf(monthAnchor);
      final monthEnd = _monthEndOf(monthAnchor);
      return ref
          .watch(historyRepositoryProvider)
          .watchTaskLifespans(
            rangeStart: addDays(monthStart, -_consistencyLookbackDays),
            rangeEnd: monthEnd,
          );
    });

final _monthCompletionCountsProvider =
    StreamProvider.autoDispose.family<Map<String, int>, DateTime>((
      ref,
      monthAnchor,
    ) {
      final monthStart = _monthStartOf(monthAnchor);
      final monthEnd = _monthEndOf(monthAnchor);
      return ref
          .watch(historyRepositoryProvider)
          .watchCompletionCounts(
            rangeStart: addDays(monthStart, -_consistencyLookbackDays),
            rangeEnd: monthEnd,
          );
    });

/// Ring values for every day in the month containing [monthAnchor].
///
/// [monthAnchor] must be normalized to the 1st of the month (no time
/// component) — the family key is compared for exact equality, so an
/// un-normalized DateTime (e.g. `DateTime.now()`) would silently miss the
/// provider cache and open a duplicate live subscription.
final monthRingsProvider = Provider.autoDispose
    .family<AsyncValue<List<DayRings>>, DateTime>((ref, monthAnchor) {
      final tasksAsync = ref.watch(_monthTaskLifespansProvider(monthAnchor));
      final countsAsync = ref.watch(
        _monthCompletionCountsProvider(monthAnchor),
      );

      if (tasksAsync.isLoading || countsAsync.isLoading) {
        return const AsyncValue.loading();
      }
      if (tasksAsync.hasError) {
        return AsyncValue.error(tasksAsync.error!, tasksAsync.stackTrace!);
      }
      if (countsAsync.hasError) {
        return AsyncValue.error(countsAsync.error!, countsAsync.stackTrace!);
      }

      return AsyncValue.data(
        computeMonthRings(
          monthAnchor: monthAnchor,
          tasks: tasksAsync.value!,
          completedCountsByDate: countsAsync.value!,
        ),
      );
    });

final dayDetailProvider = StreamProvider.autoDispose
    .family<List<ChecklistItem>, DateTime>((ref, date) {
      return ref
          .watch(historyRepositoryProvider)
          .watchChecklistForHistoricalDate(date);
    });
