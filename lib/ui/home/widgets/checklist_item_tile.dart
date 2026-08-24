import 'package:flutter/material.dart';

import '../../../domain/models/checklist_item.dart';
import '../../theme/task_category_style.dart';
import 'animated_checkbox.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onTap,
  });

  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = item.isDoneToday
        ? colorScheme.outline
        : colorScheme.onSurface;

    return ListTile(
      onTap: onToggle,
      onLongPress: onTap,
      leading: AnimatedCheckbox(checked: item.isDoneToday),
      title: Row(
        children: [
          Icon(
            item.category.icon,
            size: 16,
            color: item.isDoneToday ? colorScheme.outline : item.category.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              // AnimatedDefaultTextStyle tweens between styles via
              // Color.lerp, which treats a null color as transparent rather
              // than "inherit the ambient default" — so both branches need
              // a concrete color, or a newly-appearing item fades toward
              // invisible.
              style: TextStyle(
                fontSize: 16,
                decoration: item.isDoneToday
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: textColor,
              ),
              child: Text(item.title),
            ),
          ),
          if (item.reminderMinuteOfDay != null)
            Icon(Icons.notifications_outlined, size: 16, color: textColor),
        ],
      ),
    );
  }
}
