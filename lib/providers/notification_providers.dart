import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications/flutter_local_notifications_gateway.dart';
import '../data/notifications/notification_scheduler.dart';
import '../data/notifications/notifications_gateway.dart';

final notificationsGatewayProvider = Provider<NotificationsGateway>((ref) {
  return FlutterLocalNotificationsGateway();
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(ref.watch(notificationsGatewayProvider));
});
