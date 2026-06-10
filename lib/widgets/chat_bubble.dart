import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// AI = cyan, left-aligned; user = navy, right-aligned. Asymmetric corners.
/// Optional [rich] child renders above the text (e.g. a RoomCard).
class ChatBubble extends StatelessWidget {
  final bool isAI;
  final String? text;
  final String? time;
  final Widget? rich;
  const ChatBubble({
    super.key,
    required this.isAI,
    this.text,
    this.time,
    this.rich,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: EdgeInsets.all(rich != null ? 8 : 0).copyWith(
            left: rich != null ? 8 : 14,
            right: rich != null ? 8 : 14,
            top: rich != null ? 8 : 11,
            bottom: rich != null ? 8 : 11,
          ),
          decoration: BoxDecoration(
            color: isAI ? AppColors.secondaryCyan : AppColors.primaryNavy,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isAI ? 4 : 16),
              bottomRight: Radius.circular(isAI ? 16 : 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ?rich,
              if (text != null && text!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: rich != null ? 8 : 0, left: rich != null ? 4 : 0),
                  child: Text(
                    text!,
                    style: AppText.bodyMd.copyWith(
                      fontSize: 14.5,
                      color: isAI ? AppColors.primaryNavy : Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (time != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(time!, style: AppText.labelSm.copyWith(color: AppColors.hint)),
          ),
      ],
    );
  }
}
