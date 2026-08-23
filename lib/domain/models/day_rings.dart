class DayRings {
  const DayRings({
    required this.date,
    required this.hasGoal,
    required this.totalActive,
    required this.completed,
    required this.progressFraction,
    required this.consistencyFraction,
  });

  /// Local-midnight date this ring set describes.
  final DateTime date;

  /// Goal ring: whether any task was active this day.
  final bool hasGoal;

  final int totalActive;
  final int completed;

  /// Progress ring: completed/totalActive, 0.0 if totalActive == 0.
  final double progressFraction;

  /// Consistency ring: trailing 7-day (this day + 6 before) average of
  /// progressFraction, counting only days where totalActive > 0. Null if no
  /// such day exists in the window — distinct from "0%", so the UI can
  /// render an empty/dim ring instead of a misleadingly bad score.
  final double? consistencyFraction;
}
