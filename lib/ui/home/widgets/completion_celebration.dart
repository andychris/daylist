import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wraps [child] and plays a confetti burst + haptic + "All done" banner
/// exactly once, on the edge transition into "all of today's tasks done"
/// (not on every rebuild while already all-done).
class CompletionCelebration extends StatefulWidget {
  const CompletionCelebration({
    super.key,
    required this.allDone,
    required this.child,
  });

  final bool allDone;
  final Widget child;

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration> {
  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 1),
  );
  bool _showBanner = false;
  Timer? _hideBannerTimer;

  @override
  void didUpdateWidget(covariant CompletionCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allDone && !oldWidget.allDone) {
      _celebrate();
    }
  }

  void _celebrate() {
    HapticFeedback.heavyImpact();
    _confettiController.play();
    setState(() => _showBanner = true);
    _hideBannerTimer?.cancel();
    _hideBannerTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showBanner = false);
    });
  }

  @override
  void dispose() {
    _hideBannerTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 12,
            minBlastForce: 6,
            emissionFrequency: 0.06,
            numberOfParticles: 16,
            gravity: 0.3,
          ),
        ),
        if (_showBanner)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Material(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  'All done for today 🎉',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 250.ms).scale(
              begin: const Offset(0.8, 0.8),
              curve: Curves.elasticOut,
              duration: 500.ms,
            ),
          ),
      ],
    );
  }
}
