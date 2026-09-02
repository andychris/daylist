import 'package:daylist/data/database/app_database.dart';
import 'package:daylist/providers/database_provider.dart';
import 'package:daylist/providers/notification_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_notifications_gateway.dart';

/// The standard provider overrides for a widget test that pumps the real
/// [DaylistApp] widget tree: an in-memory [db] (rather than the real
/// on-device database) and a [FakeNotificationsGateway] (rather than real
/// platform-channel calls, which aren't mocked in `flutter_test` and would
/// throw `MissingPluginException`). Also mocks the `home_widget` plugin
/// channel (see [_mockHomeWidgetChannel]) — every widget test pumps
/// [HomePage], which talks to it directly (not through an injectable
/// gateway, unlike notifications) to sync the Android home-screen widget.
List<Override> testProviderOverrides(AppDatabase db) {
  _mockHomeWidgetChannel();
  return [
    databaseProvider.overrideWithValue(db),
    notificationsGatewayProvider.overrideWithValue(FakeNotificationsGateway()),
  ];
}

const _homeWidgetChannel = MethodChannel('home_widget');
const _homeWidgetEventChannel = EventChannel('home_widget/updates');

void _mockHomeWidgetChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_homeWidgetChannel, (call) async {
        switch (call.method) {
          case 'initiallyLaunchedFromHomeWidget':
            return null;
          case 'registerBackgroundCallback':
            return true;
          case 'saveWidgetData':
          case 'updateWidget':
            return true;
          default:
            return null;
        }
      });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(
        _homeWidgetEventChannel,
        MockStreamHandler.inline(onListen: (arguments, events) {}),
      );
}

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
