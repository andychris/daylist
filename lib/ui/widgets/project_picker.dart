import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/project_node.dart';
import '../../providers/project_providers.dart';
import '../theme/hex_color.dart';

/// A dropdown of every project (indented by nesting depth), plus "Inbox"
/// for no project (`null`).
class ProjectPicker extends ConsumerWidget {
  const ProjectPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flatTree = flattenProjectTree(ref.watch(projectTreeProvider));

    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Project',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Inbox')),
        for (final node in flatTree)
          DropdownMenuItem(
            value: node.project.id,
            child: Padding(
              padding: EdgeInsets.only(left: node.depth * 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: colorFromHex(node.project.colorHex),
                  ),
                  const SizedBox(width: 8),
                  Text(node.project.name),
                ],
              ),
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
