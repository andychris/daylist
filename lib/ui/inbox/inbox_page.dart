import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/checklist_providers.dart';
import '../../providers/date_provider.dart';
import '../home/widgets/add_task_sheet.dart';
import '../widgets/task_row.dart';

/// Tasks with no due date and no recurrence — added but not yet scheduled
/// into a day.
class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const InboxPage(),
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
      appBar: AppBar(title: const Text('Inbox')),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Something went wrong: $error')),
        data: (grouped) {
          if (grouped.inbox.isEmpty) {
            return const Center(child: Text('Inbox is empty.'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final item in grouped.inbox)
                TaskRow(item: item, today: today, repository: repository),
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
