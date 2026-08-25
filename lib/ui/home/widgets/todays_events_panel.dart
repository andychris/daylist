import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/device_calendar_providers.dart';

/// Read-only "Today's events" section pulled from the device calendar.
/// Never becomes a checklist task — see device_calendar_source.dart.
class TodaysEventsPanel extends ConsumerWidget {
  const TodaysEventsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(calendarPermissionProvider);

    return permissionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (status) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text("Today's events"),
            leading: const Icon(Icons.event_outlined),
            initiallyExpanded: status == CalendarPermissionStatus.granted,
            children: [
              if (status != CalendarPermissionStatus.granted)
                _EnableAccessRow(status: status)
              else
                const _EventsList(),
            ],
          ),
        );
      },
    );
  }
}

class _EnableAccessRow extends ConsumerWidget {
  const _EnableAccessRow({required this.status});

  final CalendarPermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPermanentlyDenied = status == CalendarPermissionStatus.denied;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        isPermanentlyDenied
            ? 'Calendar access denied'
            : 'See today\'s calendar events here',
      ),
      subtitle: isPermanentlyDenied
          ? const Text('Enable it in system settings')
          : null,
      trailing: FilledButton.tonal(
        onPressed: () async {
          if (isPermanentlyDenied) {
            await DeviceCalendar.instance.openAppSettings();
          } else {
            await ref.read(deviceCalendarSourceProvider).requestPermission();
          }
          ref.invalidate(calendarPermissionProvider);
        },
        child: Text(isPermanentlyDenied ? 'Open settings' : 'Enable'),
      ),
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList();

  static const _maxShown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(todaysEventsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return eventsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Couldn\'t load events: $error'),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No events today'),
          );
        }

        final shown = events.take(_maxShown).toList();
        final remaining = events.length - shown.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final event in shown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(
                          event.isAllDay
                              ? 'All day'
                              : DateFormat.jm().format(event.startTime),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.outline),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          event.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (remaining > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 56, top: 2),
                  child: Text(
                    '+$remaining more',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
