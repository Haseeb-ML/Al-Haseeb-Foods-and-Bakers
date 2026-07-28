import 'package:flutter/material.dart';

//-------------------- APP COLOR TOKENS --------------------
// Sirf 3 core colors: Primary (Indigo), Success (Green), Danger (Red)
class AppColors {
  // Brand
  static const primary = Color(0xFF4F46E5);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);

  // Dark theme surfaces
  static const darkBg = Color(0xFF0F172A);
  static const darkCard = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF334155);
  static const darkTextPrimary = Colors.white;
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF64748B);

  // Light theme surfaces
  static const lightBg = Color(0xFFF5F6FA);
  static const lightCard = Colors.white;
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightTextMuted = Color(0xFF94A3B8);
}

//-------------------- SPACING SYSTEM (use only these values) --------------------
class AppSpacing {
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
}

//-------------------- RADIUS SYSTEM --------------------
class AppRadius {
  static const card = 20.0;
  static const button = 16.0;
}

//-------------------- BUTTON SIZE --------------------
class AppButton {
  static const height = 52.0;
}

//-------------------- LIGHT THEME --------------------
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBg,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),
  cardColor: AppColors.lightCard,
  fontFamily: 'Roboto',
  useMaterial3: true,
);

//-------------------- DARK THEME (Midnight Blue) --------------------
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBg,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ),
  cardColor: AppColors.darkCard,
  fontFamily: 'Roboto',
  useMaterial3: true,
);
