import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/checklist_item.dart';
import '../../providers/checklist_providers.dart';
import '../../providers/date_provider.dart';
import '../calendar/calendar_page.dart';
import '../edit_task/edit_task_page.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/checklist_item_tile.dart';
import 'widgets/completion_celebration.dart';
import 'widgets/progress_ring.dart';
import 'widgets/streak_badge.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(todayChecklistProvider);
    final repository = ref.read(checklistRepositoryProvider);
    final today = ref.watch(currentLocalDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () =>
                Navigator.of(context).push(CalendarPage.route()),
          ),
        ],
      ),
      body: checklistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Something went wrong: $error')),
        data: (items) {
          final total = items.length;
          final completed = items.where((i) => i.isDoneToday).length;

          return CompletionCelebration(
            allDone: total > 0 && completed == total,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Today',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const StreakBadge(),
                        ],
                      ),
                      ProgressRing(completed: completed, total: total),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text('No tasks yet. Tap + to add one!'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) async {
                                HapticFeedback.mediumImpact();
                                await repository.archiveTask(item.id);
                                if (context.mounted) {
                                  _showUndoSnackBar(context, repository, item);
                                }
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                child: Icon(
                                  Icons.delete,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),
                              child:
                                  ChecklistItemTile(
                                        item: item,
                                        onToggle: () {
                                          HapticFeedback.selectionClick();
                                          repository.toggleCompletion(
                                            taskId: item.id,
                                            localDate: today,
                                            isCurrentlyDone: item.isDoneToday,
                                          );
                                        },
                                        onTap: () => Navigator.of(
                                          context,
                                        ).push(EditTaskPage.route(item)),
                                      )
                                      .animate(
                                        delay: (40 * index).ms,
                                      )
                                      .fadeIn(duration: 250.ms)
                                      .slideY(
                                        begin: 0.08,
                                        duration: 250.ms,
                                        curve: Curves.easeOut,
                                      ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTaskSheet.show(context, repository: repository),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showUndoSnackBar(
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
}
