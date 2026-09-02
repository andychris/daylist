import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/filters/filter_parser.dart';
import '../../domain/models/project_node.dart';
import '../../providers/filter_providers.dart';
import '../../providers/label_providers.dart';
import '../../providers/project_providers.dart';
import '../../providers/theme_mode_provider.dart';
import '../calendar/calendar_page.dart';
import '../filters/filter_results_page.dart';
import '../inbox/inbox_page.dart';
import '../labels/label_tasks_page.dart';
import '../projects/project_detail_page.dart';
import '../theme/hex_color.dart';
import '../upcoming/upcoming_page.dart';

/// The app's global navigation drawer — fixed Today/Inbox/Upcoming/Calendar
/// destinations, expandable Projects/Labels/Filters, and a theme toggle.
/// Only [HomePage] shows it (opened via its app-bar menu icon); the
/// AppBar icon shortcuts to Inbox/Upcoming/Projects/Calendar stay too —
/// this complements rather than replaces them.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectTree = ref.watch(projectTreeProvider);
    final labelsAsync = ref.watch(allLabelsProvider);
    final filtersAsync = ref.watch(allFiltersProvider);
    final themeMode = ref.watch(themeModeProvider);

    void closeDrawer() => Navigator.pop(context);
    void go(Route<void> route) {
      Navigator.pop(context);
      Navigator.of(context).push(route);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'daylist',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.today_outlined),
              title: const Text('Today'),
              onTap: closeDrawer,
            ),
            ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Inbox'),
              onTap: () => go(InboxPage.route()),
            ),
            ListTile(
              leading: const Icon(Icons.upcoming_outlined),
              title: const Text('Upcoming'),
              onTap: () => go(UpcomingPage.route()),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Calendar'),
              onTap: () => go(CalendarPage.route()),
            ),
            const Divider(),
            ExpansionTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Projects'),
              children: [
                for (final node in flattenProjectTree(projectTree))
                  Padding(
                    padding: EdgeInsets.only(left: node.depth * 16.0),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.circle,
                        size: 12,
                        color: colorFromHex(node.project.colorHex),
                      ),
                      title: Text(node.project.name),
                      onTap: () => go(ProjectDetailPage.route(node.project)),
                    ),
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.add),
                  title: const Text('Add project'),
                  onTap: () => _showAddProjectDialog(context, ref),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Labels'),
              children: [
                for (final label in labelsAsync.valueOrNull ?? const [])
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.circle,
                      size: 12,
                      color: colorFromHex(label.colorHex),
                    ),
                    title: Text(label.name),
                    onTap: () => go(LabelTasksPage.route(label)),
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.add),
                  title: const Text('Add label'),
                  onTap: () => _showAddLabelDialog(context, ref),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.filter_alt_outlined),
              title: const Text('Filters'),
              children: [
                for (final filter in filtersAsync.valueOrNull ?? const [])
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.filter_alt_outlined,
                      size: 16,
                      color: colorFromHex(filter.colorHex),
                    ),
                    title: Text(filter.name),
                    onTap: () => go(FilterResultsPage.route(filter)),
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.add),
                  title: const Text('Add filter'),
                  onTap: () => _showAddFilterDialog(context, ref),
                ),
              ],
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              value: themeMode == ThemeMode.dark,
              onChanged: (value) => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
            ),
          ],
        ),
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

  Future<void> _showAddLabelDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Label name'),
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
      await ref.read(labelRepositoryProvider).addLabel(name: name);
    }
  }

  Future<void> _showAddFilterDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final queryController = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => _AddFilterDialog(
        nameController: nameController,
        queryController: queryController,
      ),
    );
    if (result != null) {
      await ref
          .read(filterRepositoryProvider)
          .addFilter(name: result.$1, query: result.$2);
    }
  }
}

class _AddFilterDialog extends StatefulWidget {
  const _AddFilterDialog({
    required this.nameController,
    required this.queryController,
  });

  final TextEditingController nameController;
  final TextEditingController queryController;

  @override
  State<_AddFilterDialog> createState() => _AddFilterDialogState();
}

class _AddFilterDialogState extends State<_AddFilterDialog> {
  String? _error;

  void _submit() {
    final name = widget.nameController.text.trim();
    final query = widget.queryController.text.trim();
    if (name.isEmpty || query.isEmpty) {
      setState(() => _error = 'Name and query are both required.');
      return;
    }
    try {
      parseFilterQuery(query);
    } on FilterParseException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    Navigator.pop(context, (name, query));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New filter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.queryController,
            decoration: const InputDecoration(
              labelText: 'Query',
              hintText: 'p1 & (today | overdue) & !#Work',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
