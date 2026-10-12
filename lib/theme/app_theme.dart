import 'package:flutter/material.dart';

/// تعريف ألوان الثيم الداكن المستقبلي.
class AppColors {
  static const Color primary = Color(0xFF00BFA5); // Teal accent
  static const Color secondary = Color(0xFF7C4DFF); // Deep purple accent
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color error = Color(0xFFCF6679);

  static const Color onPrimary = Colors.black;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Colors.white70;
  static const Color onSurface = Colors.white70;
  static const Color onError = Colors.black;
}

/// الثيم العام للتطبيق.
class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.surface,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.background,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.onSecondary,
      onBackground: AppColors.onBackground,
      onSurface: AppColors.onSurface,
      onError: AppColors.onError,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headline1: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headline2: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
      bodyText1: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyText2: TextStyle(
        fontSize: 14,
        color: Colors.white60,
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.primary,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.white38),
    ),
  );
}
