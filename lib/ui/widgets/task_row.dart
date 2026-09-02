import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/checklist_item.dart';
import '../home/widgets/checklist_item_tile.dart';
import '../edit_task/edit_task_page.dart';

/// One swipeable task row shared by Today/Upcoming/Inbox: swipe right to
/// reschedule (opens a date picker; the list itself drops the row once its
/// due date moves elsewhere), swipe left to delete (archives, with an Undo
/// snackbar).
class TaskRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        item: item,
        onToggle: () {
          HapticFeedback.selectionClick();
          repository.toggleCompletion(
            taskId: item.id,
            localDate: today,
            isCurrentlyDone: item.isDoneToday,
          );
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
