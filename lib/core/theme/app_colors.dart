import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6366F1);

  // Light theme
  static const lightBackground = Color(0xFFF7F7F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF111113);
  static const lightSecondaryText = Color(0xFF6B6B73);
  static const lightBorder = Color(0xFFE5E5E7);

  // Dark theme
  static const darkBackground = Color(0xFF0D0D0F);
  static const darkSurface = Color(0xFF17171A);
  static const darkText = Color(0xFFF5F5F7);
  static const darkSecondaryText = Color(0xFF9A9AA3);
  static const darkBorder = Color(0xFF29292E);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}
