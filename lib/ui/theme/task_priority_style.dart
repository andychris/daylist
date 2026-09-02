import 'package:flutter/material.dart';

import '../../domain/models/task_priority.dart';

extension TaskPriorityStyle on TaskPriority {
  String get label => switch (this) {
    TaskPriority.p1 => 'Priority 1',
    TaskPriority.p2 => 'Priority 2',
    TaskPriority.p3 => 'Priority 3',
    TaskPriority.p4 => 'Priority 4',
  };

  String get shortLabel => switch (this) {
    TaskPriority.p1 => 'P1',
    TaskPriority.p2 => 'P2',
    TaskPriority.p3 => 'P3',
    TaskPriority.p4 => 'P4',
  };

  Color get color => switch (this) {
    TaskPriority.p1 => const Color(0xFFD1453B),
    TaskPriority.p2 => const Color(0xFFEB8909),
    TaskPriority.p3 => const Color(0xFF246FE0),
    TaskPriority.p4 => const Color(0xFF808080),
  };
}
