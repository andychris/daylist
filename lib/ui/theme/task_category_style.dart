import 'package:flutter/material.dart';

import '../../domain/models/task_category.dart';

extension TaskCategoryStyle on TaskCategory {
  String get label => switch (this) {
    TaskCategory.personal => 'Personal',
    TaskCategory.work => 'Work',
    TaskCategory.health => 'Health',
    TaskCategory.errands => 'Errands',
    TaskCategory.shopping => 'Shopping',
    TaskCategory.other => 'Other',
  };

  IconData get icon => switch (this) {
    TaskCategory.personal => Icons.person_outline,
    TaskCategory.work => Icons.work_outline,
    TaskCategory.health => Icons.favorite_outline,
    TaskCategory.errands => Icons.checklist_outlined,
    TaskCategory.shopping => Icons.shopping_bag_outlined,
    TaskCategory.other => Icons.label_outline,
  };

  Color get color => switch (this) {
    TaskCategory.personal => const Color(0xFF5B4EE8),
    TaskCategory.work => const Color(0xFF2D7DD2),
    TaskCategory.health => const Color(0xFFE0507A),
    TaskCategory.errands => const Color(0xFF3FA772),
    TaskCategory.shopping => const Color(0xFFE0932E),
    TaskCategory.other => const Color(0xFF78716C),
  };
}
