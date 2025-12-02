import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    primaryColor: SMColors.blue,
    scaffoldBackgroundColor: SMColors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: SMColors.blue,
      foregroundColor: SMColors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: SMColors.blue),
  );
}
