import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  const NavItem(this.label, this.icon, this.route);
}

/// Glassmorphism bottom nav: active = navy icon + dot. Optional center FAB.
class BottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int active;
  final ValueChanged<int> onChanged;
  final bool fab;
  final VoidCallback? onFab;
  const BottomNav({
    super.key,
    required this.items,
    required this.active,
    required this.onChanged,
    this.fab = false,
    this.onFab,
  });

  static const _fabGap = 72.0;

  @override
  Widget build(BuildContext context) {
    final bar = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            border: Border(
              top: BorderSide(
                  color: AppColors.primaryNavy.withValues(alpha: 0.06)),
            ),
            boxShadow: AppShadow.l2,
          ),
          child: fab && items.length == 4
              ? Row(
                  children: [
                    for (int i = 0; i < 2; i++)
                      Expanded(
                        child: _NavBtn(
                          item: items[i],
                          on: i == active,
                          onTap: () => onChanged(i),
                        ),
                      ),
                    const SizedBox(width: _fabGap),
                    for (int i = 2; i < 4; i++)
                      Expanded(
                        child: _NavBtn(
                          item: items[i],
                          on: i == active,
                          onTap: () => onChanged(i),
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavBtn(
                          item: items[i],
                          on: i == active,
                          onTap: () => onChanged(i),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );

    if (!fab) return bar;

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          bar,
          Positioned(
            top: 0,
            child: Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: AppColors.primaryNavy.withValues(alpha: 0.25),
            shape: const CircleBorder(),
            child: GestureDetector(
              onTap: onFab,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 4),
                  boxShadow: AppShadow.l2soft,
                ),
                child: const Icon(Icons.add, size: 26, color: Colors.white),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final NavItem item;
  final bool on;
  final VoidCallback onTap;
  const _NavBtn({required this.item, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = on ? AppColors.primaryNavy : AppColors.hint;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 24, color: c),
          const SizedBox(height: 4),
          Text(item.label,
              style: AppText.labelSm.copyWith(
                  fontSize: 10.5,
                  color: c,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
          const SizedBox(height: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
                color: on ? AppColors.primaryNavy : Colors.transparent,
                shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
