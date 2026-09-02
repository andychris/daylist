import '../models/task_priority.dart';

/// A parsed filter query's AST — see `filter_parser.dart` for the grammar
/// and `filter_evaluator.dart` for how a node is matched against a task.
sealed class FilterNode {
  const FilterNode();
}

class FilterAnd extends FilterNode {
  const FilterAnd(this.left, this.right);
  final FilterNode left;
  final FilterNode right;
}

class FilterOr extends FilterNode {
  const FilterOr(this.left, this.right);
  final FilterNode left;
  final FilterNode right;
}

class FilterNot extends FilterNode {
  const FilterNot(this.operand);
  final FilterNode operand;
}

class FilterPriority extends FilterNode {
  const FilterPriority(this.priority);
  final TaskPriority priority;
}

class FilterToday extends FilterNode {
  const FilterToday();
}

class FilterOverdue extends FilterNode {
  const FilterOverdue();
}

/// Due at some point from today through 6 days from now (Todoist's "Next 7
/// days"), or overdue — see `filter_evaluator.dart` for the exact rule
/// covering recurring tasks.
class FilterNext7Days extends FilterNode {
  const FilterNext7Days();
}

class FilterNoDate extends FilterNode {
  const FilterNoDate();
}

class FilterProject extends FilterNode {
  const FilterProject(this.name);
  final String name;
}

class FilterLabel extends FilterNode {
  const FilterLabel(this.name);
  final String name;
}
