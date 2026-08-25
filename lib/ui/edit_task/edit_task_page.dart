import 'package:animations/animations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/checklist_item.dart';
import '../../domain/models/task_category.dart';
import '../../providers/checklist_providers.dart';
import '../../providers/notification_providers.dart';
import '../theme/task_category_style.dart';

class EditTaskPage extends ConsumerStatefulWidget {
  const EditTaskPage({super.key, required this.item});

  final ChecklistItem item;

  static Route<void> route(ChecklistItem item) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => EditTaskPage(
        item: item,
      ),
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
  ConsumerState<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends ConsumerState<EditTaskPage> {
  late final _titleController = TextEditingController(text: widget.item.title);
  late TaskCategory _category = widget.item.category;
  late bool _reminderEnabled = widget.item.reminderMinuteOfDay != null;
  late TimeOfDay _reminderTime = widget.item.reminderMinuteOfDay != null
      ? TimeOfDay(
          hour: widget.item.reminderMinuteOfDay! ~/ 60,
          minute: widget.item.reminderMinuteOfDay! % 60,
        )
      : const TimeOfDay(hour: 9, minute: 0);

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
    if (value) {
      await ref.read(notificationsGatewayProvider).requestPermission();
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await ref
        .read(checklistRepositoryProvider)
        .updateTask(
          taskId: widget.item.id,
          title: title,
          category: _category,
          reminderMinuteOfDay: _reminderEnabled
              ? Value(_reminderTime.hour * 60 + _reminderTime.minute)
              : const Value(null),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
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
            subtitle: _reminderEnabled ? Text(_reminderTime.format(context)) : null,
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
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete task'),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this task?'),
                  content: Text(
                    '"${widget.item.title}" will be removed from your '
                    'checklist. Its history is kept.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                HapticFeedback.mediumImpact();
                await ref
                    .read(checklistRepositoryProvider)
                    .archiveTask(widget.item.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
