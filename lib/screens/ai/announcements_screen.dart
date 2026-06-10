import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/announcement_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AnnouncementRepo>();
    final canPost = context.watch<AuthProvider>().activeRole != UserRole.student;
    final isAdmin =
        context.watch<AuthProvider>().activeRole == UserRole.admin;

    return ScreenScaffold(
      header: SCAppBar(
        onBack: context.canPop() ? () => context.pop() : null,
        leading: context.canPop()
            ? null
            : Avatar(initials: context.read<AuthProvider>().profile?.initials ?? 'U', size: 40),
        title: isAdmin ? 'Admin' : 'Campus',
        subtitle: 'Announcements',
        trailing: canPost
            ? CircleIconButton(
                icon: Icons.add,
                bg: AppColors.primaryNavy,
                iconColor: Colors.white,
                onTap: () => context.push(Routes.compose))
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, 24),
        child: StreamBuilder<List<Announcement>>(
          stream: repo.watchAnnouncements(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }
            final all = snap.data ?? const [];
            final profile = context.watch<AuthProvider>().profile;
            final role = context.watch<AuthProvider>().activeRole;
            final visible = profile == null
                ? all
                : all.where((a) => a.isVisibleTo(profile, role)).toList();
            final urgent = visible.where((a) => a.urgent || a.pinned).toList();
            final recent = visible.where((a) => !a.urgent && !a.pinned).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppTextField(icon: Icons.search, hint: 'Search announcements'),
                const SizedBox(height: 22),
                if (urgent.isNotEmpty) ...[
                  const SectionHeader(title: 'Urgent & Pinned', small: true),
                  for (final a in urgent) _UrgentCard(a: a),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Updates', style: AppText.headlineSm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list, size: 14, color: AppColors.primaryNavy),
                          const SizedBox(width: 5),
                          Text('Filter',
                              style: AppText.labelLg.copyWith(
                                  fontSize: 12.5, color: AppColors.primaryNavy)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (recent.isEmpty)
                  const EmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'No announcements',
                      sub: 'Updates from campus will appear here.'),
                for (final a in recent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentCard(a: a),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  final Announcement a;
  const _UrgentCard({required this.a});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: const Border(left: BorderSide(color: AppColors.error, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusChip(variant: ChipVariant.urgent, icon: Icons.warning_amber_rounded),
              const SizedBox(width: 8),
              Flexible(
                child: Text('${a.dept} · ${a.timeAgo}',
                    style: AppText.labelSm.copyWith(
                        color: AppColors.onErrorContainer.withValues(alpha: 0.8))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.title,
              style: AppText.headlineSm.copyWith(
                  fontSize: 18, color: AppColors.onErrorContainer)),
          if (a.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(a.body,
                style: AppText.bodyMd.copyWith(color: const Color(0xFF5E0A0A))),
          ],
          if (a.summary.isNotEmpty)
            AISummary(
              text: a.summary,
              accent: AppColors.error,
              bg: Colors.white.withValues(alpha: 0.55),
              bodyColor: const Color(0xFF5E0A0A),
            ),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  final Announcement a;
  const _RecentCard({required this.a});
  @override
  Widget build(BuildContext context) {
    final accent = Color(a.accent);
    return AppCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(text: a.dept, bg: accent.withValues(alpha: 0.12), fg: accent),
              const Spacer(),
              Text(a.timeAgo, style: AppText.labelSm.copyWith(color: AppColors.hint)),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.title, style: AppText.headlineSm.copyWith(fontSize: 17)),
          if (a.summary.isNotEmpty) AISummary(text: a.summary),
        ],
      ),
    );
  }
}
