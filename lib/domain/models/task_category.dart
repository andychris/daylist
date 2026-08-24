/// Fixed, built-in task categories — not user-editable. Enum member names
/// are persisted in the database (see TaskCategoryConverter); do not rename
/// existing values without a migration.
enum TaskCategory { personal, work, health, errands, shopping, other }
