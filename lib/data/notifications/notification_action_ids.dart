/// Action ids for a task reminder's Complete/Snooze buttons — shared
/// between where the notification is built
/// ([FlutterLocalNotificationsGateway]) and where the tap is handled
/// ([notificationBackgroundResponseHandler]), so the two can't drift apart.
const completeActionId = 'complete';
const snoozeActionId = 'snooze';
