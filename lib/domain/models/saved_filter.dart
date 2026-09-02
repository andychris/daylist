class SavedFilter {
  const SavedFilter({
    required this.id,
    required this.name,
    required this.query,
    required this.colorHex,
    required this.sortOrder,
  });

  final int id;
  final String name;

  /// A `filter_parser.dart`-compatible query string, e.g.
  /// `p1 & (today | overdue) & !#Work`.
  final String query;
  final String colorHex;
  final double sortOrder;
}
