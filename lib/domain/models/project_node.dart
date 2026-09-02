import 'project.dart';

/// One node of a project tree built in-memory from a flat [Project] list
/// (nested projects don't need recursive SQL at this app's scale — see
/// [buildProjectTree]).
class ProjectNode {
  const ProjectNode({
    required this.project,
    required this.depth,
    required this.children,
  });

  final Project project;

  /// 0 for a top-level project, 1 for its direct children, etc.
  final int depth;
  final List<ProjectNode> children;
}

/// Builds the parent/child project tree (top-level projects first, each
/// sorted by `sortOrder`, same for their children).
List<ProjectNode> buildProjectTree(List<Project> flat) {
  final byParent = <int?, List<Project>>{};
  for (final project in flat) {
    byParent.putIfAbsent(project.parentProjectId, () => []).add(project);
  }
  for (final siblings in byParent.values) {
    siblings.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<ProjectNode> build(int? parentId, int depth) => [
    for (final project in byParent[parentId] ?? const <Project>[])
      ProjectNode(
        project: project,
        depth: depth,
        children: build(project.id, depth + 1),
      ),
  ];

  return build(null, 0);
}

/// Depth-first flattening of a project tree — handy for a simple indented
/// list (e.g. a project picker) rather than a nested widget tree.
List<ProjectNode> flattenProjectTree(List<ProjectNode> roots) {
  final result = <ProjectNode>[];
  void visit(ProjectNode node) {
    result.add(node);
    node.children.forEach(visit);
  }

  roots.forEach(visit);
  return result;
}
