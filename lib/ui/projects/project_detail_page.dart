import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/project.dart';
import '../../domain/models/project_view_type.dart';
import '../../providers/checklist_providers.dart';
import '../../providers/date_provider.dart';
import '../../providers/project_providers.dart';
import '../home/widgets/add_task_sheet.dart';
import '../widgets/task_row.dart';
import 'widgets/kanban_board.dart';

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.project});

  final Project project;

  static Route<void> route(Project project) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ProjectDetailPage(project: project),
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
    // Watched live (not the possibly-stale [project] passed in) so the
    // List/Board toggle below updates immediately.
    final live = ref.watch(projectByIdProvider)[project.id] ?? project;
    final tasksAsync = ref.watch(todayChecklistProvider);
    final repository = ref.read(checklistRepositoryProvider);
    final today = ref.watch(currentLocalDateProvider);
    final isBoard = live.viewType == ProjectViewType.board;

    return Scaffold(
      appBar: AppBar(
        title: Text(live.name),
        actions: [
          IconButton(
            icon: Icon(isBoard ? Icons.view_list_outlined : Icons.view_column_outlined),
            tooltip: isBoard ? 'Switch to list' : 'Switch to board',
            onPressed: () => ref
                .read(projectRepositoryProvider)
                .updateProject(
                  id: live.id,
                  viewType: isBoard
                      ? ProjectViewType.list
                      : ProjectViewType.board,
                ),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Something went wrong: $error')),
        data: (tasks) {
          final projectTasks = tasks.where((t) => t.projectId == live.id).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          if (isBoard) {
            return KanbanBoard(projectId: live.id, tasks: projectTasks, today: today);
          }

          if (projectTasks.isEmpty) {
            return const Center(child: Text('No tasks yet. Tap + to add one!'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final item in projectTasks)
                TaskRow(item: item, today: today, repository: repository),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddTaskSheet.show(context, initialProjectId: live.id),
        child: const Icon(Icons.add),
      ),
    );
  }
}
