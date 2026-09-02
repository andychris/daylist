import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/label_providers.dart';
import '../theme/hex_color.dart';

class LabelMultiSelect extends ConsumerWidget {
  const LabelMultiSelect({
    super.key,
    required this.selectedLabelIds,
    required this.onChanged,
  });

  final Set<int> selectedLabelIds;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelsAsync = ref.watch(allLabelsProvider);

    return labelsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (labels) {
        if (labels.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.map((label) {
            final selected = selectedLabelIds.contains(label.id);
            return FilterChip(
              label: Text(label.name),
              avatar: Icon(
                Icons.label_outline,
                size: 16,
                color: colorFromHex(label.colorHex),
              ),
              selected: selected,
              onSelected: (isSelected) {
                final next = Set<int>.from(selectedLabelIds);
                if (isSelected) {
                  next.add(label.id);
                } else {
                  next.remove(label.id);
                }
                onChanged(next);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
