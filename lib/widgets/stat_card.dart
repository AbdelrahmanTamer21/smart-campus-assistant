import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

/// Dashboard stat: big number + label + optional trend (▲4%).
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? trend;
  final bool trendUp;
  final Color accent;
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.trend,
    this.trendUp = true,
    this.accent = AppColors.primaryNavy,
  });
  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.headlineLg.copyWith(fontSize: 30)),
          const SizedBox(height: 2),
          Text(label, style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
          if (trend != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: trendUp ? 0 : 3.14159,
                    child: Icon(Icons.arrow_upward,
                        size: 13,
                        color: trendUp ? AppColors.success : AppColors.error),
                  ),
                  const SizedBox(width: 3),
                  Text(trend!,
                      style: AppText.labelSm.copyWith(
                          color: trendUp ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
