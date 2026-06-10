import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Material 3 ThemeData seeded from University Navy, wired to the token classes.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryNavy,
      primary: AppColors.primaryNavy,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondaryCyan,
      tertiary: AppColors.tertiaryPurple,
      error: AppColors.error,
      surface: AppColors.card,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppText.body,
      splashFactory: InkRipple.splashFactory,
      textTheme: const TextTheme(
        displayLarge: AppText.headlineLg,
        headlineMedium: AppText.headlineMd,
        headlineSmall: AppText.headlineSm,
        bodyLarge: AppText.bodyLg,
        bodyMedium: AppText.bodyMd,
        labelLarge: AppText.labelLg,
        labelSmall: AppText.labelSm,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDarkest,
        contentTextStyle: TextStyle(
          fontFamily: AppText.body,
          color: Colors.white,
          fontSize: 13.5,
        ),
      ),
    );
  }
}
