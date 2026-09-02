import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/checklist_item.dart';
import '../../../providers/date_provider.dart';
import '../../../providers/project_providers.dart';
import '../../theme/hex_color.dart';
import '../../theme/task_priority_style.dart';
import 'animated_checkbox.dart';

class ChecklistItemTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = item.isDoneToday
        ? colorScheme.outline
        : colorScheme.onSurface;
    final project = item.projectId == null
        ? null
        : ref.watch(projectByIdProvider)[item.projectId];
    final today = ref.watch(currentLocalDateProvider);
    final isOverdue =
        !item.isDoneToday &&
        item.dueDate != null &&
        DateTime(
          item.dueDate!.year,
          item.dueDate!.month,
          item.dueDate!.day,
        ).isBefore(today);

    return ListTile(
      onTap: onToggle,
      onLongPress: onTap,
      leading: AnimatedCheckbox(
        checked: item.isDoneToday,
        activeColor: item.priority.color,
      ),
      title: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        // AnimatedDefaultTextStyle tweens between styles via Color.lerp,
        // which treats a null color as transparent rather than "inherit
        // the ambient default" — so both branches need a concrete color,
        // or a newly-appearing item fades toward invisible.
        style: TextStyle(
          fontSize: 16,
          decoration: item.isDoneToday
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          color: textColor,
        ),
        child: Text(item.title),
      ),
      subtitle: (project != null || item.dueDate != null)
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (project != null)
                    _Badge(
                      icon: Icons.circle,
                      iconColor: colorFromHex(project.colorHex),
                      iconSize: 8,
                      label: project.name,
                      textColor: textColor,
                    ),
                  if (item.dueDate != null)
                    _Badge(
                      icon: Icons.calendar_today_outlined,
                      iconColor: isOverdue ? colorScheme.error : textColor,
                      label: DateFormat.MMMd().format(item.dueDate!),
                      textColor: isOverdue ? colorScheme.error : textColor,
                    ),
                ],
              ),
            )
          : null,
      trailing: item.reminderMinuteOfDay != null
          ? Icon(Icons.notifications_outlined, size: 16, color: textColor)
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    this.iconSize = 14,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ],
    );
  }
}
