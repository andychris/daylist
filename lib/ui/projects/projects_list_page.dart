import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/project_node.dart';
import '../../providers/project_providers.dart';
import '../theme/hex_color.dart';
import 'project_detail_page.dart';

class ProjectsListPage extends ConsumerWidget {
  const ProjectsListPage({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const ProjectsListPage(),
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
    final tree = ref.watch(projectTreeProvider);
    final flat = flattenProjectTree(tree);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: flat.isEmpty
          ? const Center(child: Text('No projects yet. Tap + to add one!'))
          : ListView(
              children: [
                for (final node in flat)
                  Padding(
                    padding: EdgeInsets.only(left: node.depth * 16.0),
                    child: ListTile(
                      leading: Icon(
                        Icons.circle,
                        size: 14,
                        color: colorFromHex(node.project.colorHex),
                      ),
                      title: Text(node.project.name),
                      trailing: node.project.isFavorite
                          ? const Icon(Icons.star, size: 18)
                          : null,
                      onTap: () => Navigator.of(
                        context,
                      ).push(ProjectDetailPage.route(node.project)),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddProjectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Project name'),
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
      await ref.read(projectRepositoryProvider).addProject(name: name);
    }
  }
}
