import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/label.dart';
import '../../../domain/models/project.dart';
import '../../../domain/models/task_priority.dart';
import '../../../domain/quick_add/parsed_quick_add_result.dart';
import '../../../domain/quick_add/task_input_parser.dart';
import '../../../providers/checklist_providers.dart';
import '../../../providers/label_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../../providers/project_providers.dart';
import '../../widgets/priority_picker.dart';
import '../../widgets/project_picker.dart';
import '../../widgets/quick_add_text_controller.dart';

/// Quick-add: type e.g. "Ship release p1 #Work @urgent tomorrow at 5pm" and
/// it's parsed live into priority/project/labels/due date/time/recurrence
/// (see [parseQuickAddInput]) — the pickers below are a manual fallback/
/// override for anything not (or not yet) typed.
class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key, this.initialProjectId});

  /// Pre-selects a project (e.g. opened from within that project's page)
  /// rather than defaulting to Inbox.
  final int? initialProjectId;

  static Future<void> show(BuildContext context, {int? initialProjectId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTaskSheet(initialProjectId: initialProjectId),
    );
  }

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _controller = QuickAddTextController();
  ParsedQuickAddResult _parsed = parseQuickAddInput('', now: DateTime.now());

  TaskPriority? _priorityOverride;
  late int? _projectIdOverride = widget.initialProjectId;
  late bool _projectTouched = widget.initialProjectId != null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_reparse);
  }

  void _reparse() {
    setState(() {
      _parsed = parseQuickAddInput(_controller.text, now: DateTime.now());
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_reparse);
    _controller.dispose();
    super.dispose();
  }

  Project? _findProjectByName(List<Project> projects, String name) {
    for (final project in projects) {
      if (project.name.toLowerCase() == name.toLowerCase()) return project;
    }
    return null;
  }

  Label? _findLabelByName(List<Label> labels, String name) {
    for (final label in labels) {
      if (label.name.toLowerCase() == name.toLowerCase()) return label;
    }
    return null;
  }

  Future<void> _submit() async {
    final parsed = _parsed;
    if (parsed.cleanedTitle.isEmpty) return;

    if (parsed.dueTimeMinuteOfDay != null) {
      // Ask lazily, only now that a typed time actually needs a real
      // reminder to fire — not up front at app launch.
      final gateway = ref.read(notificationsGatewayProvider);
      await gateway.requestPermission();
      await gateway.requestExactAlarmPermission();
    }

    final projectRepository = ref.read(projectRepositoryProvider);
    final labelRepository = ref.read(labelRepositoryProvider);
    final existingProjects = ref.read(allProjectsProvider).valueOrNull ?? const [];
    final existingLabels = ref.read(allLabelsProvider).valueOrNull ?? const [];

    int? projectId;
    if (_projectTouched) {
      projectId = _projectIdOverride;
    } else if (parsed.projectName != null) {
      final match = _findProjectByName(existingProjects, parsed.projectName!);
      projectId =
          match?.id ??
          await projectRepository.addProject(name: parsed.projectName!);
    }

    final labelIds = <int>[];
    for (final name in parsed.labelNames) {
      final match = _findLabelByName(existingLabels, name);
      labelIds.add(match?.id ?? await labelRepository.addLabel(name: name));
    }

    final priority =
        _priorityOverride ?? parsed.priority ?? TaskPriority.p4;

    final taskId = await ref
        .read(checklistRepositoryProvider)
        .addTask(
          title: parsed.cleanedTitle,
          priority: priority,
          projectId: projectId,
          dueDate: parsed.dueDate,
          recurrenceRule: parsed.recurrenceRule,
          reminderMinuteOfDay: parsed.dueTimeMinuteOfDay,
        );

    if (taskId != null && labelIds.isNotEmpty) {
      await labelRepository.setTaskLabels(taskId, labelIds);
    }

    if (mounted) Navigator.of(context).pop();
  }

  String? _scheduleDescription() {
    final parts = <String>[];
    if (_parsed.recurrenceRule != null) {
      parts.add(_describeRecurrence(_parsed.recurrenceRule!));
    } else if (_parsed.dueDate != null) {
      parts.add(DateFormat.MMMEd().format(_parsed.dueDate!));
    }
    if (_parsed.dueTimeMinuteOfDay != null) {
      final h = _parsed.dueTimeMinuteOfDay! ~/ 60;
      final m = _parsed.dueTimeMinuteOfDay! % 60;
      parts.add(
        TimeOfDay(hour: h, minute: m).format(context),
      );
    }
    return parts.isEmpty ? null : parts.join(' at ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final projectsAsync = ref.watch(allProjectsProvider);
    final projects = projectsAsync.valueOrNull ?? const [];
    final resolvedProject = _parsed.projectName == null
        ? null
        : _findProjectByName(projects, _parsed.projectName!);
    final effectiveProjectId = _projectTouched
        ? _projectIdOverride
        : resolvedProject?.id;
    final willCreateProject =
        !_projectTouched &&
        _parsed.projectName != null &&
        resolvedProject == null;

    final scheduleDescription = _scheduleDescription();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New task', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. "Ship release p1 #Work @urgent tomorrow at 5pm"',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (scheduleDescription != null || willCreateProject || _parsed.labelNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (scheduleDescription != null)
                      Chip(
                        avatar: const Icon(Icons.event_outlined, size: 16),
                        label: Text(scheduleDescription),
                      ),
                    if (willCreateProject)
                      Chip(
                        avatar: const Icon(Icons.add_circle_outline, size: 16),
                        label: Text('New project "${_parsed.projectName}"'),
                      ),
                    for (final name in _parsed.labelNames)
                      Chip(
                        avatar: Icon(
                          _findLabelByName(
                                ref.watch(allLabelsProvider).valueOrNull ??
                                    const [],
                                name,
                              ) ==
                              null
                              ? Icons.add_circle_outline
                              : Icons.label_outline,
                          size: 16,
                        ),
                        label: Text('@$name'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text('Priority', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              PriorityPicker(
                value: _priorityOverride ?? _parsed.priority ?? TaskPriority.p4,
                onChanged: (p) => setState(() => _priorityOverride = p),
              ),
              const SizedBox(height: 16),
              ProjectPicker(
                value: effectiveProjectId,
                onChanged: (id) => setState(() {
                  _projectTouched = true;
                  _projectIdOverride = id;
                }),
              ),
              if (willCreateProject)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Typed "#${_parsed.projectName}" — will create this project, '
                    'or pick an existing one above.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Add task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _describeRecurrence(String rule) {
  if (rule == 'daily') return 'Every day';
  if (rule == 'weekdays') return 'Every weekday';
  if (rule.startsWith('weekly:')) {
    return 'Every ${_capitalize(rule.substring('weekly:'.length))}';
  }
  if (rule.startsWith('monthly:')) {
    return 'Monthly on the ${rule.substring('monthly:'.length)}';
  }
  if (rule.startsWith('every:')) {
    return 'Every ${rule.substring('every:'.length)} days';
  }
  return rule;
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
