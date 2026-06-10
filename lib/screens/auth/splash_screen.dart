import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primitives.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Logo(size: 96),
                const SizedBox(height: 28),
                Text('Campus Assistant',
                    style: AppText.headlineLg.copyWith(color: AppColors.primaryNavy)),
                const SizedBox(height: 12),
                Text('Your University Life, Simplified.',
                    style: AppText.bodyLg.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Positioned(
            bottom: 64,
            child: Column(
              children: [
                SizedBox(
                  width: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, _) => LinearProgressIndicator(
                        value: _c.value,
                        minHeight: 4,
                        backgroundColor: AppColors.fill,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primaryNavy),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.hint),
                    const SizedBox(width: 7),
                    Text('SECURE UNIVERSITY PORTAL',
                        style: AppText.labelSm
                            .copyWith(color: AppColors.hint, letterSpacing: 1.4)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
