/// Task priority, highest (P1) to lowest (P4). Enum member names are
/// persisted in the database (see TaskPriorityConverter); do not rename
/// existing values without a migration.
enum TaskPriority { p1, p2, p3, p4 }
