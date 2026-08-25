import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/task_category.dart';
import '../../../providers/checklist_providers.dart';
import '../../../providers/notification_providers.dart';
import '../../theme/task_category_style.dart';

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
  TaskCategory _category = TaskCategory.other;
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
          category: _category,
          reminderMinuteOfDay: _reminderEnabled
              ? _reminderTime.hour * 60 + _reminderTime.minute
              : null,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            Text('Category', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskCategory.values.map((category) {
                final selected = category == _category;
                return ChoiceChip(
                  label: Text(category.label),
                  avatar: Icon(
                    category.icon,
                    size: 18,
                    color: selected ? colorScheme.onPrimary : category.color,
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = category),
                );
              }).toList(),
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
