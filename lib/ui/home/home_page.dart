import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/checklist_item.dart';
import '../../providers/checklist_providers.dart';
import '../../providers/date_provider.dart';
import '../calendar/calendar_page.dart';
import '../inbox/inbox_page.dart';
import '../upcoming/upcoming_page.dart';
import '../widgets/task_row.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/completion_celebration.dart';
import 'widgets/progress_ring.dart';
import 'widgets/streak_badge.dart';
import 'widgets/todays_events_panel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(groupedTasksProvider);
    final repository = ref.read(checklistRepositoryProvider);
    final today = ref.watch(currentLocalDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_outlined),
            tooltip: 'Inbox',
            onPressed: () => Navigator.of(context).push(InboxPage.route()),
          ),
          IconButton(
            icon: const Icon(Icons.upcoming_outlined),
            tooltip: 'Upcoming',
            onPressed: () => Navigator.of(context).push(UpcomingPage.route()),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendar',
            onPressed: () =>
                Navigator.of(context).push(CalendarPage.route()),
          ),
        ],
      ),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Something went wrong: $error')),
        data: (grouped) {
          final onPlate = [...grouped.overdue, ...grouped.dueToday];
          final total = onPlate.length;
          final completed = onPlate.where((i) => i.isDoneToday).length;

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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: TodaysEventsPanel(),
                ),
                const Divider(height: 1),
                Expanded(
                  child: total == 0
                      ? const Center(
                          child: Text('Nothing due today. Tap + to add a task!'),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 88),
                          children: [
                            if (grouped.overdue.isNotEmpty)
                              _TaskSection(
                                title: 'Overdue',
                                items: grouped.overdue,
                                today: today,
                                repository: repository,
                              ),
                            if (grouped.dueToday.isNotEmpty)
                              _TaskSection(
                                title: 'Today',
                                items: grouped.dueToday,
                                today: today,
                                repository: repository,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTaskSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.items,
    required this.today,
    required this.repository,
  });

  final String title;
  final List<ChecklistItem> items;
  final DateTime today;
  final ChecklistRepository repository;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        '$title (${items.length})',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      initiallyExpanded: true,
      shape: const Border(),
      childrenPadding: EdgeInsets.zero,
      children: [
        for (var i = 0; i < items.length; i++)
          TaskRow(item: items[i], today: today, repository: repository)
              .animate(delay: (30 * i).ms)
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.06, duration: 200.ms, curve: Curves.easeOut),
      ],
    );
  }
}
