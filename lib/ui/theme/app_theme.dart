import 'package:flutter/material.dart';

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B4EE8),
      brightness: brightness,
    ),
  );
}
