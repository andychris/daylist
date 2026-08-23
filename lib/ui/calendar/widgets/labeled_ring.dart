import 'package:flutter/material.dart';

/// A full-size ring showing [fraction] (0.0-1.0), with a [label] beneath and
/// [centerText] in the middle. Used for the goal/progress/consistency rings
/// in the day-detail view. A null [fraction] renders as an empty/dim ring
/// (used for "no data yet", distinct from a real 0%).
class LabeledRing extends StatelessWidget {
  const LabeledRing({
    super.key,
    required this.label,
    required this.fraction,
    required this.centerText,
    required this.color,
  });

  final String label;
  final double? fraction;
  final String centerText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction ?? 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: fraction == null ? 0 : value,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      fraction == null ? colorScheme.outlineVariant : color,
                    ),
                  );
                },
              ),
              Text(
                centerText,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
