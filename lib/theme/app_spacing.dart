// Design tokens — spacing (8px grid), radius, elevation shadows.
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double screen = 20; // side margins
  static const double cardPad = 16;

  /// Shared top-bar insets so headers align across tabs.
  static const double headerTop = 8;
  static const double headerBottom = 14;
  static const double headerContentHeight = 48;
}

class AppRadius {
  AppRadius._();
  static const double card = 16;
  static const double tag = 8;
  static const double tagSm = 4;
  static const double sheet = 24;
  static const double pill = 9999;
}

class AppShadow {
  AppShadow._();

  /// Level 1 — standard cards.
  static List<BoxShadow> get l1 => [
        BoxShadow(
          color: AppColors.primaryNavy.withValues(alpha: 0.05),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  /// Level 2 — floating / bottom nav / active.
  static List<BoxShadow> get l2 => [
        BoxShadow(
          color: AppColors.primaryNavy.withValues(alpha: 0.08),
          offset: const Offset(0, 8),
          blurRadius: 20,
        ),
      ];

  /// Level 2 soft — FAB / bottom sheet lift.
  static List<BoxShadow> get l2soft => [
        BoxShadow(
          color: AppColors.primaryNavy.withValues(alpha: 0.10),
          offset: const Offset(0, 8),
          blurRadius: 24,
        ),
      ];
}
