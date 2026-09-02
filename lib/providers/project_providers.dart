import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/project_repository.dart';
import '../domain/models/project.dart';
import '../domain/models/project_node.dart';
import 'database_provider.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(databaseProvider));
});

final allProjectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchProjects();
});

/// Nested parent/child project tree, built from [allProjectsProvider].
final projectTreeProvider = Provider<List<ProjectNode>>((ref) {
  final projects = ref.watch(allProjectsProvider).valueOrNull ?? const [];
  return buildProjectTree(projects);
});

/// Lookup table for resolving a task's `projectId` to its [Project] (e.g.
/// for a project color dot/name badge on a task row).
final projectByIdProvider = Provider<Map<int, Project>>((ref) {
  final projects = ref.watch(allProjectsProvider).valueOrNull ?? const [];
  return {for (final p in projects) p.id: p};
});
