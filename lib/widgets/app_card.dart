import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// White card with 16-radius, soft navy shadow, and an optional 4px colored
/// left accent bar denoting category.
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final VoidCallback? onTap;
  final double pad;
  final Color? background;
  final List<BoxShadow>? shadow;
  final double? opacity;
  const AppCard({
    super.key,
    required this.child,
    this.accent,
    this.onTap,
    this.pad = AppSpacing.cardPad,
    this.background,
    this.shadow,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final showBar = accent != null;
    Widget content = Container(
      decoration: BoxDecoration(
        color: background ?? AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: shadow ?? AppShadow.l1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  showBar ? pad + 4 : pad, pad, pad, pad),
              child: child,
            ),
            if (showBar)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(color: accent!),
              ),
          ],
        ),
      ),
    );
    if (opacity != null) content = Opacity(opacity: opacity!, child: content);
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
  }
}
