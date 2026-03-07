import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Colors.blue;
  static const String _fontFamily = 'Roboto';

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    fontFamily: _fontFamily,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    fontFamily: _fontFamily,
  );
}
