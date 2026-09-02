import 'package:flutter/material.dart';

import '../../domain/models/task_priority.dart';
import '../theme/task_priority_style.dart';

class PriorityPicker extends StatelessWidget {
  const PriorityPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TaskPriority.values.map((priority) {
        final selected = priority == value;
        return ChoiceChip(
          label: Text(priority.shortLabel),
          avatar: Icon(
            Icons.flag,
            size: 18,
            color: selected ? colorScheme.onPrimary : priority.color,
          ),
          selected: selected,
          onSelected: (_) => onChanged(priority),
        );
      }).toList(),
    );
  }
}
