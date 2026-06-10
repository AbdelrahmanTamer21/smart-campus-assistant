import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../repositories/announcement_repo.dart';
import '../../repositories/course_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

class StaffHome extends StatelessWidget {
  const StaffHome({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final unread = context.watch<NotificationsProvider>().unread;
    final courseRepo = context.read<CourseRepo>();
    final annRepo = context.read<AnnouncementRepo>();
    final p = auth.profile;

    return ScreenScaffold(
      header: SCAppBar(
        leading: Avatar(
          initials: p?.initials ?? 'PW',
          bg: AppColors.accentAcademic,
          size: 40,
          ring: true,
          onTap: () => context.push(Routes.profile),
        ),
        title: 'Faculty · ${p?.dept ?? 'Mathematics'}',
        subtitle: p?.name ?? 'Prof. Wilson',
        trailing: CircleIconButton(
          icon: Icons.notifications_outlined,
          dot: unread > 0,
          onTap: () => context.push(Routes.notifications),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 2, AppSpacing.screen, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Urgent Actions', small: true),
            AppCard(
              accent: AppColors.accentUrgent,
              onTap: () => context.go(Routes.schedule),
              child: Row(
                children: [
                  const IconCircle(
                      icon: Icons.warning_amber_rounded,
                      tint: AppColors.errorContainer,
                      color: AppColors.error,
                      size: 46,
                      iconSize: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Review today\'s classes',
                            style: AppText.labelLg.copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('Update rooms or cancellations — students get notified.',
                            style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.border),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Courses', style: AppText.headlineSm),
                GestureDetector(
                  onTap: () => context.go(Routes.schedule),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text('View All',
                        style: AppText.labelLg.copyWith(
                            fontSize: 12.5, color: AppColors.primaryNavy)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Course>>(
              stream: courseRepo.watchCourses(p?.teachingCourseIds ?? const []),
              builder: (context, snap) {
                final list = snap.data ?? const [];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No courses yet',
                      sub: 'Courses you teach will appear here.');
                }
                return Column(
                  children: [
                    for (int i = 0; i < list.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CourseCard(
                          course: list[i],
                          accent: i.isEven ? AppColors.accentAcademic : AppColors.accentSocial,
                          tint: i.isEven ? AppColors.secondaryCyan : AppColors.tertiaryPurple,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            SectionHeader(
                title: 'Recent Announcements',
                action: 'View All',
                onAction: () => context.push(Routes.announcements)),
            StreamBuilder<List<Announcement>>(
              stream: annRepo.watchAnnouncements(),
              builder: (context, snap) {
                final list = (snap.data ?? const []).take(2).toList();
                return Column(
                  children: [
                    for (final a in list)
                      ListRow(
                        icon: Icons.campaign_outlined,
                        iconTint: AppColors.tertiaryPurple,
                        title: a.title,
                        meta: a.timeAgo,
                        onTap: () => context.push(Routes.announcements),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Color accent;
  final Color tint;
  const _CourseCard({required this.course, required this.accent, required this.tint});
  @override
  Widget build(BuildContext context) {
    final sched = course.sessions.isEmpty
        ? ''
        : '${course.sessions.map((s) => s.day).take(2).join(', ')} · ${course.sessions.first.start}';
    return AppCard(
      accent: accent,
      onTap: () => context.push('${Routes.course}/${course.id}'),
      child: Row(
        children: [
          IconCircle(
              icon: Icons.science_outlined, tint: tint, color: accent, size: 48, iconSize: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(text: course.code),
                const SizedBox(height: 6),
                Text(course.title, style: AppText.labelLg.copyWith(fontSize: 15)),
                const SizedBox(height: 6),
                if (sched.isNotEmpty) MetaRow(icon: Icons.schedule, text: sched),
                const SizedBox(height: 4),
                MetaRow(icon: Icons.group_outlined, text: '${course.studentCount} Students'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
