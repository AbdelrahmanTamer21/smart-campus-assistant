import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

class NotificationsInbox extends StatelessWidget {
  const NotificationsInbox({super.key});

  IconData _icon(String type) => switch (type) {
        'class' => Icons.event_busy_outlined,
        'deadline' => Icons.assignment_late_outlined,
        _ => Icons.campaign_outlined,
      };

  Color _accent(String type) => switch (type) {
        'class' => AppColors.roomChanged,
        'deadline' => AppColors.accentUrgent,
        _ => AppColors.accentAcademic,
      };

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationsProvider>();
    return ScreenScaffold(
      header: SCAppBar(
        onBack: () => context.pop(),
        title: 'Inbox',
        subtitle: 'Notifications',
        trailing: prov.unread > 0
            ? GestureDetector(
                onTap: prov.markAllRead,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text('Mark all read',
                      style: AppText.labelSm.copyWith(color: AppColors.primaryNavy)),
                ),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 4, AppSpacing.screen, 24),
        child: Builder(builder: (context) {
          if (prov.loading) return const LoadingState();
          if (prov.items.isEmpty) {
            return const EmptyState(
                icon: Icons.notifications_none,
                title: "You're all caught up",
                sub: 'New alerts about your classes and deadlines appear here.');
          }
          return Column(
            children: [
              for (final n in prov.items)
                ListRow(
                  icon: _icon(n.type),
                  iconTint: n.read ? AppColors.fill : _accent(n.type).withValues(alpha: 0.15),
                  accent: n.read ? null : _accent(n.type),
                  title: n.title,
                  meta: '${n.body}  ·  ${n.timeAgo}',
                  onTap: () async {
                    await prov.markRead(n.id);
                    if (context.mounted && n.route != null) context.push(n.route!);
                  },
                ),
            ],
          );
        }),
      ),
    );
  }
}
