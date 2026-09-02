class Section {
  const Section({
    required this.id,
    required this.name,
    required this.projectId,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final int projectId;
  final double sortOrder;
}
