import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const lightColorScheme = ColorScheme.light(
    primary: Color(0xFF2E7D32), // Green
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFA5D6A7),
    secondary: Color(0xFF81C784),
    onSecondary: Colors.black,
    background: Colors.white,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    error: Colors.red,
    onError: Colors.white,
  );

  // Dark Theme Colors
  static const darkColorScheme = ColorScheme.dark(
    primary: Color(0xFFa2d39b), // Light Green
    onPrimary: Colors.black,
    primaryContainer: Color(0xFF0F140E),
    secondary: Color(0xFF81C784),
    onSecondary: Colors.white,
    background: Color(0xFF0F140E), // Dark background
    onBackground: Colors.white,
    surface: Color(0xFF1E1E1E), // Card background
    onSurface: Colors.white,
    error: Colors.red,
    onError: Colors.white,
  );

  // Common Colors
  static const white = Colors.white;
  static const black = Colors.black;
  static const grey = Colors.grey;
  static const transparent = Colors.transparent;

  // Light Theme Specific
  static const lightBackground = Colors.white;
  static const lightCardBackground = Color(0xFFF5F5F5);
  static const lightTextPrimary = Colors.black87;
  static const lightTextSecondary = Colors.black54;
  static const lightDivider = Color(0xFFE0E0E0);

  // Dark Theme Specific
  static const darkBackground = Color(0xFF0F140E);
  static const darkCardBackground = Color(0xFF1E1E1E);
  static const darkTextPrimary = Colors.white;
  static const darkTextSecondary = Colors.white70;
  static const darkDivider = Color(0xFF424242);

  // Brand Colors
  static const brandGreen = Color(0xFFa2d39b);
  static const brandDark = Color(0xFF0F140E);
}
