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

/// The default test surface (800x600 logical px) is too short for screens
/// with tall scrollable content (e.g. a full calendar month grid) — day
/// cells late in the month land outside it and `tap()` silently misses.
/// Call at the top of a test that needs to interact with such content.
void useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
