import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/label_repository.dart';
import '../domain/models/label.dart';
import 'database_provider.dart';

final labelRepositoryProvider = Provider<LabelRepository>((ref) {
  return LabelRepository(ref.watch(databaseProvider));
});

final allLabelsProvider = StreamProvider<List<Label>>((ref) {
  return ref.watch(labelRepositoryProvider).watchLabels();
});

final taskLabelsProvider = StreamProvider.family<List<Label>, int>((
  ref,
  taskId,
) {
  return ref.watch(labelRepositoryProvider).watchLabelsForTask(taskId);
});
