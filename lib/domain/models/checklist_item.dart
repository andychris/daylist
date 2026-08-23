class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.title,
    required this.isDoneToday,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final bool isDoneToday;
  final double sortOrder;

  ChecklistItem copyWith({bool? isDoneToday}) => ChecklistItem(
    id: id,
    title: title,
    isDoneToday: isDoneToday ?? this.isDoneToday,
    sortOrder: sortOrder,
  );
}
