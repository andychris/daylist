import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/task_priority.dart';
import '../../../providers/checklist_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../widgets/priority_picker.dart';
import '../../widgets/project_picker.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTaskSheet(),
    );
  }

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleController = TextEditingController();
  TaskPriority _priority = TaskPriority.p4;
  int? _projectId;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _onReminderToggled(bool value) async {
    setState(() => _reminderEnabled = value);
    // Ask for notification permission lazily, only when the user actually
    // wants a reminder — not up front at app launch.
    if (value) {
      await ref.read(notificationsGatewayProvider).requestPermission();
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    ref
        .read(checklistRepositoryProvider)
        .addTask(
          title: title,
          priority: _priority,
          projectId: _projectId,
          reminderMinuteOfDay: _reminderEnabled
              ? _reminderTime.hour * 60 + _reminderTime.minute
              : null,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'What do you need to do?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text('Priority', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            PriorityPicker(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 16),
            ProjectPicker(
              value: _projectId,
              onChanged: (id) => setState(() => _projectId = id),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily reminder'),
              subtitle: _reminderEnabled
                  ? Text(_reminderTime.format(context))
                  : null,
              value: _reminderEnabled,
              onChanged: _onReminderToggled,
            ),
            if (_reminderEnabled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickReminderTime,
                  icon: const Icon(Icons.schedule),
                  label: Text('Change time (${_reminderTime.format(context)})'),
                ),
              ),
            const SizedBox(height: 12),
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
    );
  }
}
