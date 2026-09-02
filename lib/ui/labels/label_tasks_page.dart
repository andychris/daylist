import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/label.dart';
import '../../providers/checklist_providers.dart';
import '../../providers/date_provider.dart';
import '../../providers/label_providers.dart';
import '../widgets/task_row.dart';

class LabelTasksPage extends ConsumerWidget {
  const LabelTasksPage({super.key, required this.label});

  final Label label;

  static Route<void> route(Label label) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          LabelTasksPage(label: label),
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
    final tasksAsync = ref.watch(todayChecklistProvider);
    final pairsAsync = ref.watch(allTaskLabelPairsProvider);
    final repository = ref.read(checklistRepositoryProvider);
    final today = ref.watch(currentLocalDateProvider);

    return Scaffold(
      appBar: AppBar(title: Text('@${label.name}')),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Something went wrong: $error')),
        data: (tasks) {
          final pairs = pairsAsync.valueOrNull ?? const {};
          final labeled = tasks
              .where((t) => (pairs[t.id] ?? const {}).contains(label.id))
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          if (labeled.isEmpty) {
            return const Center(child: Text('No tasks with this label.'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final item in labeled)
                TaskRow(item: item, today: today, repository: repository),
            ],
          );
        },
      ),
    );
  }
}
