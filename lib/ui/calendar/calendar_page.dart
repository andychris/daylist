import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/date_provider.dart';
import '../../providers/history_providers.dart';
import '../home/widgets/streak_badge.dart';
import 'widgets/day_detail_sheet.dart';
import 'widgets/month_grid.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const CalendarPage(),
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
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  // Always normalized to the 1st of the month — monthRingsProvider's family
  // key is compared by exact equality.
  late DateTime _visibleMonth = _normalize(DateTime.now());

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, 1);

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _visibleMonth = _normalize(DateTime.now());
    });
  }

  // A horizontal fling faster than this (logical px/s) counts as a
  // deliberate swipe rather than an incidental drag.
  static const _swipeVelocityThreshold = 200.0;

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_swipeVelocityThreshold) {
      _goToNextMonth();
    } else if (velocity >= _swipeVelocityThreshold) {
      _goToPreviousMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ringsAsync = ref.watch(monthRingsProvider(_visibleMonth));
    final today = ref.watch(currentLocalDateProvider);
    final isCurrentMonth = _visibleMonth == _normalize(today);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(_visibleMonth)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
          onPressed: _goToPreviousMonth,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_outlined),
            tooltip: 'Jump to today',
            onPressed: isCurrentMonth ? null : _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: _goToNextMonth,
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: StreakBadge(),
              ),
              ringsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('Something went wrong: $error')),
                ),
                data: (rings) => MonthGrid(
                  monthAnchor: _visibleMonth,
                  rings: rings,
                  today: today,
                  onDayTap: (date) {
                    final dayRings = rings.firstWhere((r) => r.date == date);
                    DayDetailSheet.show(context, dayRings);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
