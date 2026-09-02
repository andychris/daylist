import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/section_repository.dart';
import '../domain/models/section.dart';
import 'database_provider.dart';

final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  return SectionRepository(ref.watch(databaseProvider));
});

final sectionsForProjectProvider = StreamProvider.family<List<Section>, int>((
  ref,
  projectId,
) {
  return ref.watch(sectionRepositoryProvider).watchSectionsForProject(projectId);
});
