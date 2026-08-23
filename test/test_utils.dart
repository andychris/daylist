import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drift's stream cleanup schedules a zero-duration Timer when a listener is
/// cancelled. flutter_test's strict "no pending timers" invariant check trips
/// if that fires during its own automatic teardown, so we explicitly unmount
/// the widget tree (triggering that cleanup) and flush it ourselves first.
Future<void> disposeCleanly(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}
