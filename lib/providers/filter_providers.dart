import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/filter_repository.dart';
import '../domain/filters/filter_evaluator.dart';
import '../domain/models/saved_filter.dart';
import 'database_provider.dart';
import 'date_provider.dart';
import 'label_providers.dart';
import 'project_providers.dart';

final filterRepositoryProvider = Provider<FilterRepository>((ref) {
  return FilterRepository(ref.watch(databaseProvider));
});

final allFiltersProvider = StreamProvider<List<SavedFilter>>((ref) {
  return ref.watch(filterRepositoryProvider).watchFilters();
});

/// The lookups a [FilterEvalContext] needs, assembled from whatever's
/// already loaded elsewhere (projects, labels, task-label pairs) — so
/// evaluating a filter doesn't require any query of its own.
final filterEvalContextProvider = Provider<FilterEvalContext>((ref) {
  final today = ref.watch(currentLocalDateProvider);
  final projects = ref.watch(allProjectsProvider).valueOrNull ?? const [];
  final labels = ref.watch(allLabelsProvider).valueOrNull ?? const [];
  final labelIdsByTaskId =
      ref.watch(allTaskLabelPairsProvider).valueOrNull ?? const {};

  return FilterEvalContext(
    today: today,
    projectNameById: {for (final p in projects) p.id: p.name},
    labelIdsByTaskId: labelIdsByTaskId,
    labelNameById: {for (final l in labels) l.id: l.name},
  );
});
