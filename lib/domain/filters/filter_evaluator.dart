import '../due_logic.dart';
import '../models/checklist_item.dart';
import '../task_grouping.dart';
import 'filter_node.dart';

/// The lookups [evaluateFilter] needs beyond what's on [ChecklistItem]
/// itself (that model carries ids, not the project/label *names* a filter
/// query is written against).
class FilterEvalContext {
  const FilterEvalContext({
    required this.today,
    required this.projectNameById,
    required this.labelIdsByTaskId,
    required this.labelNameById,
  });

  final DateTime today;
  final Map<int, String> projectNameById;
  final Map<int, Set<int>> labelIdsByTaskId;
  final Map<int, String> labelNameById;
}

/// Whether [task] matches [node] under [ctx] — see `filter_parser.dart` for
/// how a query string becomes a [FilterNode] tree.
bool evaluateFilter(FilterNode node, ChecklistItem task, FilterEvalContext ctx) {
  switch (node) {
    case FilterAnd(:final left, :final right):
      return evaluateFilter(left, task, ctx) && evaluateFilter(right, task, ctx);
    case FilterOr(:final left, :final right):
      return evaluateFilter(left, task, ctx) || evaluateFilter(right, task, ctx);
    case FilterNot(:final operand):
      return !evaluateFilter(operand, task, ctx);
    case FilterPriority(:final priority):
      return task.priority == priority;
    case FilterToday():
      return classifyDueBucket(task, ctx.today) == DueBucket.dueToday;
    case FilterOverdue():
      return classifyDueBucket(task, ctx.today) == DueBucket.overdue;
    case FilterNext7Days():
      return _isDueWithinNext7Days(task, ctx.today);
    case FilterNoDate():
      return task.dueDate == null && task.recurrenceRule == null;
    case FilterProject(:final name):
      final taskProjectName = task.projectId == null
          ? null
          : ctx.projectNameById[task.projectId];
      return taskProjectName != null &&
          taskProjectName.toLowerCase() == name.toLowerCase();
    case FilterLabel(:final name):
      final labelIds = ctx.labelIdsByTaskId[task.id] ?? const <int>{};
      return labelIds.any(
        (id) => (ctx.labelNameById[id] ?? '').toLowerCase() == name.toLowerCase(),
      );
  }
}

/// Due today, overdue, or due within the next 6 days — Todoist's "Next 7
/// days" (today counts as day 1). A recurring task counts if its rule
/// matches any day in that window.
bool _isDueWithinNext7Days(ChecklistItem task, DateTime today) {
  final windowEnd = today.add(const Duration(days: 6));

  if (task.recurrenceRule != null) {
    for (
      var day = today;
      !day.isAfter(windowEnd);
      day = day.add(const Duration(days: 1))
    ) {
      if (matchesRecurrence(task.recurrenceRule!, day, task.createdAt)) {
        return true;
      }
    }
    return false;
  }

  if (task.dueDate == null) return false;
  final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
  return !due.isAfter(windowEnd);
}
