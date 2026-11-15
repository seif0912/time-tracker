import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF6366F1);

  // Light theme
  static const lightBackground = Color(0xFFFAF9F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightElevated = Color(0xFFF3EFE6);
  static const lightBorder = Color(0xFFE3DED2);

  static const lightText = Color(0xFF171717);
  static const lightSecondaryText = Color(0xFF55534D);
  static const lightMutedText = Color(0xFF858179);

  // Dark theme
  static const darkBackground = Color(0xFF111110);
  static const darkSurface = Color(0xFF1B1B19);
  static const darkElevated = Color(0xFF242421);
  static const darkBorder = Color(0xFF353530);

  static const darkText = Color(0xFFF5F1E8);
  static const darkSecondaryText = Color(0xFFC8C4BA);
  static const darkMutedText = Color(0xFF85827A);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Common
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}
