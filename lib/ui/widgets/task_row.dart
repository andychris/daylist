import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/checklist_item.dart';
import '../home/widgets/checklist_item_tile.dart';
import '../edit_task/edit_task_page.dart';

/// How long a just-completed row shows checked + struck through before the
/// real DB write lands — long enough to register as a deliberate
/// confirmation, short enough not to feel like a delay. Matters most for a
/// one-off task, which archives (and so disappears from this list) on
/// completion — without this, it would vanish the instant it's tapped.
const completionAnimationDelay = Duration(milliseconds: 400);

/// One swipeable task row shared by Today/Upcoming/Inbox: swipe right to
/// reschedule (opens a date picker; the list itself drops the row once its
/// due date moves elsewhere), swipe left to delete (archives, with an Undo
/// snackbar).
class TaskRow extends StatefulWidget {
  const TaskRow({
    super.key,
    required this.item,
    required this.today,
    required this.repository,
  });

  final ChecklistItem item;
  final DateTime today;
  final ChecklistRepository repository;

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  bool _pendingComplete = false;

  Future<void> _handleToggle() async {
    if (widget.item.isDoneToday) {
      // Un-checking: instant, same as Todoist — only completing shows the
      // brief confirmation state.
      await widget.repository.toggleCompletion(
        taskId: widget.item.id,
        localDate: widget.today,
        isCurrentlyDone: true,
      );
      return;
    }

    if (_pendingComplete) return; // already mid-animation; ignore a repeat tap
    setState(() => _pendingComplete = true);
    await Future.delayed(completionAnimationDelay);
    if (!mounted) return;
    await widget.repository.toggleCompletion(
      taskId: widget.item.id,
      localDate: widget.today,
      isCurrentlyDone: false,
    );
    // No need to reset _pendingComplete: for a recurring task the stream's
    // next `widget.item` already has isDoneToday true (matches); for a
    // one-off task this row is about to be removed from its parent list
    // entirely (the task got archived), so there's nothing left to reset.
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final today = widget.today;
    final repository = widget.repository;
    final displayItem = _pendingComplete
        ? item.copyWith(isDoneToday: true)
        : item;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          HapticFeedback.mediumImpact();
          await repository.archiveTask(item.id);
          if (context.mounted) showUndoSnackBar(context, repository, item);
          return true;
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: item.dueDate ?? today,
          firstDate: DateTime(today.year - 1),
          lastDate: DateTime(today.year + 5),
        );
        if (picked != null) {
          await repository.updateTask(taskId: item.id, dueDate: Value(picked));
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.event_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      child: ChecklistItemTile(
        item: displayItem,
        onToggle: () {
          HapticFeedback.selectionClick();
          _handleToggle();
        },
        onTap: () => Navigator.of(context).push(EditTaskPage.route(item)),
      ),
    );
  }
}

void showUndoSnackBar(
  BuildContext context,
  ChecklistRepository repository,
  ChecklistItem item,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('"${item.title}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => repository.restoreTask(item.id),
        ),
      ),
    );
}
