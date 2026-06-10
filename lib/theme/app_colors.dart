import 'package:flutter/material.dart';

/// Design tokens — colors. Ported verbatim from the Stitch/Claude Design
/// prototype `theme.jsx`. Never hardcode hex in screens; use these.
class AppColors {
  AppColors._();

  static const primaryNavy = Color(0xFF002147);
  static const primaryDarkest = Color(0xFF000A1E);
  static const onPrimary = Color(0xFFFFFFFF);
  static const inversePrimary = Color(0xFFAEC7F6);

  static const background = Color(0xFFF9F9F9);
  static const card = Color(0xFFFFFFFF);
  static const fill = Color(0xFFEEEEEE);
  static const fillLow = Color(0xFFF3F3F3);

  static const secondaryCyan = Color(0xFFD0E7EA);
  static const tertiaryPurple = Color(0xFFF3E5F5);

  static const textPrimary = Color(0xFF1A1C1C);
  static const textMuted = Color(0xFF44474E);
  static const hint = Color(0xFF74777F);
  static const border = Color(0xFFC4C6CF);

  static const success = Color(0xFF1B7A43);
  static const successContainer = Color(0xFFD7F0DD);
  static const onSuccess = Color(0xFF0A5128);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Category accent-bar colors
  static const accentUpcoming = Color(0xFF1B7A43); // green = upcoming/confirmed
  static const accentUrgent = Color(0xFFBA1A1A); // red = urgent
  static const accentAcademic = Color(0xFF3E8E9B); // cyan-deep = academic
  static const accentSocial = Color(0xFF9C5BB0); // purple = social
  static const accentNeutral = Color(0xFF002147); // navy = neutral

  // Room-changed amber
  static const roomChanged = Color(0xFFC98A00);
  static const roomChangedBg = Color(0xFFFFF1D6);
  static const roomChangedFg = Color(0xFF7A4E00);
}
