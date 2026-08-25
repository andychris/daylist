import 'package:daylist/data/notifications/notifications_gateway.dart';

/// In-memory fake so scheduling/reconcile logic can be tested without
/// touching real platform channels.
class FakeNotificationsGateway implements NotificationsGateway {
  final Map<int, int> scheduled = {}; // id -> minuteOfDay
  int cancelCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int minuteOfDay,
  }) async {
    scheduled[id] = minuteOfDay;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCallCount++;
    scheduled.remove(id);
  }

  @override
  Future<Set<int>> pendingIds() async => scheduled.keys.toSet();
}
