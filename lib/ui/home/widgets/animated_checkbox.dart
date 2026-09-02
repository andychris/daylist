import 'package:flutter/material.dart';

class AnimatedCheckbox extends StatelessWidget {
  const AnimatedCheckbox({super.key, required this.checked, this.activeColor});

  final bool checked;

  /// Color the checkbox fills with once checked (and its border tweens
  /// toward). Defaults to the theme's primary color — pass a task's
  /// priority color to get Todoist-style priority-coded checkboxes.
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = activeColor ?? colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: checked ? 1 : 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.elasticOut,
      builder: (context, t, _) {
        // t overshoots past 1 (elasticOut), so clamp the color/opacity
        // interpolation while letting the scale keep its pop.
        final clamped = t.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.85 + 0.15 * t,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(Colors.transparent, active, clamped),
              border: Border.all(
                color: Color.lerp(colorScheme.outline, active, clamped)!,
                width: 2,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: checked
                  ? Icon(
                      Icons.check,
                      key: const ValueKey('checked'),
                      size: 16,
                      color: colorScheme.onPrimary,
                    )
                  : const SizedBox.shrink(key: ValueKey('unchecked')),
            ),
          ),
        );
      },
    );
  }
}
