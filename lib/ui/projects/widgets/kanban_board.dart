import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/checklist_repository.dart';
import '../../../domain/models/checklist_item.dart';
import '../../../providers/checklist_providers.dart';
import '../../../providers/section_providers.dart';
import '../../edit_task/edit_task_page.dart';
import '../../home/widgets/checklist_item_tile.dart';

const _columnWidth = 260.0;

/// A section column per [Section] plus a "No Section" column, each holding
/// its tasks as long-press-draggable cards. Dropping a card on a column
/// (anywhere in it — see [DragTarget]) moves that task to the end of that
/// section via [ChecklistRepository.moveTaskToSection].
class KanbanBoard extends ConsumerWidget {
  const KanbanBoard({
    super.key,
    required this.projectId,
    required this.tasks,
    required this.today,
  });

  final int projectId;
  final List<ChecklistItem> tasks;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsForProjectProvider(projectId));
    final repository = ref.read(checklistRepositoryProvider);

    return sectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Something went wrong: $error')),
      data: (sections) {
        final noSection = tasks.where((t) => t.sectionId == null).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KanbanColumn(
                title: 'No section',
                sectionId: null,
                tasks: noSection,
                repository: repository,
                today: today,
              ),
              for (final section in sections)
                _KanbanColumn(
                  title: section.name,
                  sectionId: section.id,
                  tasks: tasks.where((t) => t.sectionId == section.id).toList(),
                  repository: repository,
                  today: today,
                ),
              _AddSectionColumn(projectId: projectId),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.title,
    required this.sectionId,
    required this.tasks,
    required this.repository,
    required this.today,
  });

  final String title;
  final int? sectionId;
  final List<ChecklistItem> tasks;
  final ChecklistRepository repository;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<ChecklistItem>(
      onAcceptWithDetails: (details) {
        if (details.data.sectionId == sectionId) return;
        repository.moveTaskToSection(taskId: details.data.id, sectionId: sectionId);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: _columnWidth,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '$title (${tasks.length})',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              for (final task in tasks)
                _KanbanCard(task: task, repository: repository, today: today),
              // Fills the rest of the column so a drop anywhere below the
              // last card (or on an empty column) still hits this target.
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.task,
    required this.repository,
    required this.today,
  });

  final ChecklistItem task;
  final ChecklistRepository repository;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ChecklistItemTile(
        item: task,
        onToggle: () => repository.toggleCompletion(
          taskId: task.id,
          localDate: today,
          isCurrentlyDone: task.isDoneToday,
        ),
        onTap: () => Navigator.of(context).push(EditTaskPage.route(task)),
      ),
    );

    return LongPressDraggable<ChecklistItem>(
      data: task,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: _columnWidth - 16, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}

class _AddSectionColumn extends ConsumerWidget {
  const _AddSectionColumn({required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: _columnWidth,
      child: OutlinedButton.icon(
        onPressed: () => _showAddSectionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add section'),
      ),
    );
  }

  Future<void> _showAddSectionDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. "In Progress"'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref
          .read(sectionRepositoryProvider)
          .addSection(name: name, projectId: projectId);
    }
  }
}
