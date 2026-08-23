import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/checklist_repository.dart';
import '../domain/models/checklist_item.dart';
import 'database_provider.dart';
import 'date_provider.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(ref.watch(databaseProvider));
});

final todayChecklistProvider = StreamProvider<List<ChecklistItem>>((ref) {
  final today = ref.watch(currentLocalDateProvider);
  return ref.watch(checklistRepositoryProvider).watchChecklistForDate(today);
});
