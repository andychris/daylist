import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_mode_provider.dart';
import 'ui/home/home_page.dart';
import 'ui/theme/app_theme.dart';

class DaylistApp extends ConsumerWidget {
  const DaylistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'daylist',
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}
