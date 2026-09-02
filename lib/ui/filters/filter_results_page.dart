import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/filters/filter_evaluator.dart';
import '../../domain/filters/filter_node.dart';
import '../../domain/filters/filter_parser.dart';
import '../../domain/models/saved_filter.dart';
import '../../providers/checklist_providers.dart';
import '../../providers/date_provider.dart';
import '../../providers/filter_providers.dart';
import '../widgets/task_row.dart';

class FilterResultsPage extends ConsumerWidget {
  const FilterResultsPage({super.key, required this.filter});

  final SavedFilter filter;

  static Route<void> route(SavedFilter filter) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          FilterResultsPage(filter: filter),
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
    final evalContext = ref.watch(filterEvalContextProvider);
    final repository = ref.read(checklistRepositoryProvider);
    final today = ref.watch(currentLocalDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(filter.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete filter',
            onPressed: () async {
              await ref.read(filterRepositoryProvider).deleteFilter(filter.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Something went wrong: $error')),
        data: (tasks) {
          final node = _tryParse(filter.query);
          if (node == null) {
            return const Center(child: Text('This filter\'s query is invalid.'));
          }

          final matched = tasks
              .where((t) => evaluateFilter(node, t, evalContext))
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          if (matched.isEmpty) {
            return const Center(child: Text('No matching tasks.'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final item in matched)
                TaskRow(item: item, today: today, repository: repository),
            ],
          );
        },
      ),
    );
  }
}

FilterNode? _tryParse(String query) {
  try {
    return parseFilterQuery(query);
  } on FilterParseException {
    return null;
  }
}
