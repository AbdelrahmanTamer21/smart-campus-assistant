import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Slim navy offline banner.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDarkest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: AppColors.inversePrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text("You're offline — showing saved data",
                style: AppText.labelSm.copyWith(color: Colors.white, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(color: AppColors.primaryNavy, strokeWidth: 2.6),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  const EmptyState({super.key, required this.icon, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
                child: Icon(icon, size: 28, color: AppColors.hint),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: AppText.headlineSm.copyWith(fontSize: 17), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(sub,
                  style: AppText.bodyMd.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorStateView({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.errorContainer, shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off, size: 28, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text('Something went wrong',
              style: AppText.headlineSm.copyWith(fontSize: 17), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message,
              style: AppText.bodyMd.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          if (onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(onPressed: onRetry, child: const Text('Try again')),
            ),
        ],
      ),
    );
  }
}

/// "AI Summary" tinted box used in announcements.
class AISummary extends StatelessWidget {
  final String text;
  final Color accent;
  final Color? bg;
  final Color? bodyColor;
  const AISummary({
    super.key,
    required this.text,
    this.accent = AppColors.accentAcademic,
    this.bg,
    this.bodyColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg ?? AppColors.fillLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI SUMMARY',
                    style: AppText.labelSm.copyWith(
                        color: accent, fontWeight: FontWeight.w700, letterSpacing: 0.72)),
                const SizedBox(height: 3),
                Text(text,
                    style: AppText.bodyMd.copyWith(
                        fontSize: 13.5,
                        color: bodyColor ?? AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
