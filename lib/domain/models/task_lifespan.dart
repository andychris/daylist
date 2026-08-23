class TaskLifespan {
  const TaskLifespan({
    required this.id,
    required this.createdAt,
    required this.archivedAt,
  });

  final int id;
  final DateTime createdAt;
  final DateTime? archivedAt;
}
