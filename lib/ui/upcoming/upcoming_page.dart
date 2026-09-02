import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/checklist_providers.dart';
import '../../providers/date_provider.dart';
import '../home/widgets/add_task_sheet.dart';
import '../widgets/task_row.dart';

/// Non-recurring tasks due on a future day, grouped by that day.
class UpcomingPage extends ConsumerWidget {
  const UpcomingPage({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const UpcomingPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(groupedTasksProvider);
    final repository = ref.read(checklistRepositoryProvider);
    final today = ref.watch(currentLocalDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming')),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Something went wrong: $error')),
        data: (grouped) {
          if (grouped.upcoming.isEmpty) {
            return const Center(child: Text('Nothing scheduled ahead.'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final entry in grouped.upcoming.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    DateFormat.MMMEd().format(entry.key),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (final item in entry.value)
                  TaskRow(item: item, today: today, repository: repository),
              ],
            ],
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
