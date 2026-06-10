import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design tokens — typography. Hanken Grotesk for headings, Inter for UI/body.
/// Mirrors the prototype `theme.jsx` TYPE scale.
class AppText {
  AppText._();

  static const String head = 'Hanken Grotesk';
  static const String body = 'Inter';

  // Headings → Hanken Grotesk
  static const headlineLg = TextStyle(
    fontFamily: head,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.64, // -0.02em
    height: 1.1,
    color: AppColors.textPrimary,
  );
  static const headlineMd = TextStyle(
    fontFamily: head,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24, // -0.01em
    height: 1.15,
    color: AppColors.textPrimary,
  );
  static const headlineSm = TextStyle(
    fontFamily: head,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // Body & UI → Inter
  static const bodyLg = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textPrimary,
  );
  static const bodyMd = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textPrimary,
  );
  static const labelLg = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14, // 0.01em
    color: AppColors.textPrimary,
  );
  static const labelSm = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
