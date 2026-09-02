import 'project_view_type.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.isFavorite,
    required this.parentProjectId,
    required this.sortOrder,
    required this.viewType,
  });

  final int id;
  final String name;
  final String colorHex;
  final bool isFavorite;

  /// Null for a top-level project.
  final int? parentProjectId;
  final double sortOrder;
  final ProjectViewType viewType;
}
