import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/date_utils.dart';

/// Holds today's local-midnight date, refreshed at the next local midnight
/// and re-checked on app resume (a bare Timer misses rollovers that happen
/// while the device is asleep).
final currentLocalDateProvider = NotifierProvider<CurrentLocalDateNotifier, DateTime>(
  CurrentLocalDateNotifier.new,
);

class CurrentLocalDateNotifier extends Notifier<DateTime> {
  Timer? _midnightTimer;
  AppLifecycleListener? _lifecycleListener;

  @override
  DateTime build() {
    _scheduleNextMidnight();
    _lifecycleListener = AppLifecycleListener(
      onResume: _refreshIfDateChanged,
    );
    ref.onDispose(() {
      _midnightTimer?.cancel();
      _lifecycleListener?.dispose();
    });
    return todayLocalMidnight();
  }

  void _scheduleNextMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      state = todayLocalMidnight();
      _scheduleNextMidnight();
    });
  }

  void _refreshIfDateChanged() {
    final today = todayLocalMidnight();
    if (today != state) {
      state = today;
    }
    _scheduleNextMidnight();
  }
}
