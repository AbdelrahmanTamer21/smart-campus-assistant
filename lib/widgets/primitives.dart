import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Circular avatar — shows a base64 photo if provided, else initials.
class Avatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color bg;
  final Color color;
  final bool ring;
  final VoidCallback? onTap;
  final String? photoBase64;
  const Avatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.bg = AppColors.primaryNavy,
    this.color = Colors.white,
    this.ring = false,
    this.onTap,
    this.photoBase64,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        bytes = base64Decode(photoBase64!);
      } catch (_) {}
    }
    final w = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        image: bytes != null
            ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
            : null,
        boxShadow: ring
            ? [
                BoxShadow(
                  color: AppColors.primaryNavy.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
        border: ring ? Border.all(color: AppColors.card, width: 2) : null,
      ),
      child: bytes != null
          ? null
          : Text(
              initials,
              style: TextStyle(
                fontFamily: AppText.head,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
                color: color,
              ),
            ),
    );
    if (onTap == null) return w;
    return GestureDetector(onTap: onTap, child: w);
  }
}

/// Navy rounded-square logo with a sparkle glyph.
class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.32),
            offset: const Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome,
          size: size * 0.5, color: AppColors.inversePrimary),
    );
  }
}

/// Icon inside a tinted circle.
class IconCircle extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color color;
  final double size;
  final double iconSize;
  const IconCircle({
    super.key,
    required this.icon,
    this.tint = AppColors.secondaryCyan,
    this.color = AppColors.primaryNavy,
    this.size = 44,
    this.iconSize = 22,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// Small icon + text row used across cards (time / room / professor).
class MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const MetaRow({
    super.key,
    required this.icon,
    required this.text,
    this.color = AppColors.textMuted,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text,
              style: AppText.bodyMd.copyWith(color: color),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// iOS-style labeled toggle row.
class AppToggle extends StatelessWidget {
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  const AppToggle({
    super.key,
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
    this.color = AppColors.primaryNavy,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (label.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppText.labelLg.copyWith(fontSize: 15)),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(sub!,
                        style: AppText.bodyMd
                            .copyWith(fontSize: 13, color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 50,
            height: 30,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? color : AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
