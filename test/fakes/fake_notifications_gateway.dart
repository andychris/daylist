import 'package:daylist/data/notifications/notifications_gateway.dart';

/// In-memory fake so scheduling/reconcile logic can be tested without
/// touching real platform channels. Each `id` lives in at most one of the
/// three maps at a time — scheduling it one way clears the others, mirroring
/// how a real plugin replaces id N's prior schedule outright.
class FakeNotificationsGateway implements NotificationsGateway {
  final Map<int, int> scheduled = {}; // id -> minuteOfDay (daily)
  final Map<int, ({int weekday, int minuteOfDay})> scheduledWeekly = {};
  final Map<int, DateTime> scheduledOnce = {};
  int cancelCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  void _clear(int id) {
    scheduled.remove(id);
    scheduledWeekly.remove(id);
    scheduledOnce.remove(id);
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int minuteOfDay,
  }) async {
    _clear(id);
    scheduled[id] = minuteOfDay;
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int minuteOfDay,
  }) async {
    _clear(id);
    scheduledWeekly[id] = (weekday: weekday, minuteOfDay: minuteOfDay);
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    _clear(id);
    scheduledOnce[id] = at;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCallCount++;
    _clear(id);
  }

  @override
  Future<Set<int>> pendingIds() async => {
    ...scheduled.keys,
    ...scheduledWeekly.keys,
    ...scheduledOnce.keys,
  };
}
