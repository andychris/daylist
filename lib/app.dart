import 'package:flutter/material.dart';

import 'ui/home/home_page.dart';
import 'ui/theme/app_theme.dart';

class DaylistApp extends StatelessWidget {
  const DaylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Checklist',
      theme: buildAppTheme(),
      home: const HomePage(),
    );
  }
}
