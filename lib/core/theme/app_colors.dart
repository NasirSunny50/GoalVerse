import 'package:flutter/material.dart';

/// Central palette for the premium FIFA 2026 look.
class AppColors {
  AppColors._();

  // Brand accents (used in both themes). Blue, matching the GoalVerse logo.
  static const Color primary = Color(0xFF2E9BE6); // GoalVerse blue
  static const Color secondary = Color(0xFF5468FF); // indigo-blue
  static const Color tertiary = Color(0xFFFF5E7E); // pink
  static const Color gold = Color(0xFFFFC65C);

  static const Color live = Color(0xFFFF4D6D);
  static const Color upcoming = Color(0xFF5C9CFF);
  static const Color finished = Color(0xFF8E97A8);

  /// Accent used for group / stage labels (deliberately not the green primary).
  static const Color group = Color(0xFFFFA53C); // warm amber
  static const Color groupAlt = Color(0xFF7C83FF); // periwinkle

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF0A0E1A);
  static const Color darkBg2 = Color(0xFF111728);
  static const Color darkSurface = Color(0xFF161C2E);
  static const Color darkCard = Color(0xFF1B2236);
  static const Color darkBorder = Color(0x1AFFFFFF);
  static const Color darkText = Color(0xFFF4F6FC);
  static const Color darkTextDim = Color(0xFF9AA4BE);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF4F6FB);
  static const Color lightBg2 = Color(0xFFEBEFF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0x14101630);
  static const Color lightText = Color(0xFF111528);
  static const Color lightTextDim = Color(0xFF626B85);

  // Hero / brand gradient (deep blue → bright cyan-blue, like the logo ring).
  static const List<Color> brandGradient = [
    Color(0xFF1666E0),
    Color(0xFF38C6F4),
  ];

  static const List<Color> heroGradient = [
    Color(0xFF1A1F47),
    Color(0xFF101428),
    Color(0xFF0A0E1A),
  ];

  static const List<Color> pitchGradient = [
    Color(0xFF1565E0),
    Color(0xFF0D3A8C),
  ];
}
