import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/assignment.dart';
import '../../models/class_occurrence.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../repositories/course_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final unread = context.watch<NotificationsProvider>().unread;
    final profile = auth.profile;
    final repo = context.read<CourseRepo>();
    final courseIds = profile?.enrolledCourseIds ?? const [];

    return ScreenScaffold(
      header: SCAppBar(
        leading: Avatar(
          initials: profile?.initials ?? 'U',
          bg: AppColors.primaryNavy,
          size: 40,
          ring: true,
          photoBase64: profile?.photoBase64,
          onTap: () => context.push(Routes.profile),
        ),
        title: _todayLabel(),
        subtitle: 'Welcome back, ${profile?.first ?? ''}',
        trailing: CircleIconButton(
          icon: Icons.notifications_outlined,
          dot: unread > 0,
          onTap: () => context.push(Routes.notifications),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 2, AppSpacing.screen, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Up Next ──
            const SectionHeader(title: 'Up Next', small: true),
            StreamBuilder<List<ClassOccurrence>>(
              stream: repo.watchDay(courseIds, DateTime.now()),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const _UpNextSkeleton();
                }
                final upcoming = snap.data!
                    .where((c) => c.status != ClassStatus.cancelled)
                    .toList();
                if (upcoming.isEmpty) {
                  return const EmptyState(
                      icon: Icons.event_available,
                      title: 'Nothing left today',
                      sub: 'Your classes are done. Enjoy the rest of your day!');
                }
                return _UpNextCard(occ: upcoming.first);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Daily Insight ──
            AppCard(
              background: AppColors.tertiaryPurple,
              shadow: const [],
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconCircle(
                      icon: Icons.lightbulb_outline,
                      tint: Colors.white,
                      color: AppColors.accentSocial,
                      size: 40,
                      iconSize: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Insight',
                            style: AppText.labelLg
                                .copyWith(color: AppColors.accentSocial)),
                        const SizedBox(height: 4),
                        Text(
                          'You have a gap before your next class — the Library 3rd '
                          'floor is quiet right now. A good time to start the report '
                          'due tomorrow.',
                          style: AppText.bodyMd
                              .copyWith(color: const Color(0xFF4A2A55)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Deadlines ──
            SectionHeader(
                title: 'Deadlines',
                action: 'See All',
                onAction: () => context.go(Routes.schedule)),
            StreamBuilder<List<Assignment>>(
              stream: repo.watchAssignments(courseIds),
              builder: (context, snap) {
                final list = (snap.data ?? const <Assignment>[]).take(3).toList();
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.task_alt,
                      title: 'No upcoming deadlines',
                      sub: 'You\'re all caught up.');
                }
                return Column(
                  children: [
                    for (final a in list)
                      ListRow(
                        icon: Icons.event_available,
                        iconTint: a.isUrgent
                            ? AppColors.errorContainer
                            : AppColors.fill,
                        accent: a.isUrgent
                            ? AppColors.accentUrgent
                            : AppColors.accentNeutral,
                        title: a.title,
                        meta: a.code,
                        chevron: false,
                        trailing: Tag(
                          text: a.dueLabel,
                          bg: a.isUrgent
                              ? AppColors.errorContainer
                              : AppColors.fill,
                          fg: a.isUrgent
                              ? AppColors.onErrorContainer
                              : AppColors.textMuted,
                        ),
                        onTap: () =>
                            context.push('${Routes.course}/${a.courseId}'),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),

            // ── Quick tiles ──
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    bg: AppColors.secondaryCyan,
                    fg: AppColors.primaryNavy,
                    icon: Icons.confirmation_number_outlined,
                    title: 'Campus Events',
                    sub: 'See what\'s on',
                    onTap: () => context.go(Routes.events),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Tile(
                    bg: AppColors.fill,
                    fg: AppColors.textPrimary,
                    icon: Icons.local_cafe_outlined,
                    title: 'Study Spaces',
                    sub: 'Find a spot',
                    onTap: () => context.go(Routes.map),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _todayLabel() {
    final n = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[n.weekday - 1]}, ${months[n.month - 1]} ${n.day}';
  }
}

class _UpNextCard extends StatelessWidget {
  final ClassOccurrence occ;
  const _UpNextCard({required this.occ});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: AppColors.accentUpcoming,
      pad: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StatusChip(variant: ChipVariant.soon, icon: Icons.schedule),
              _Countdown(start: occ.start),
            ],
          ),
          const SizedBox(height: 12),
          Text(occ.title, style: AppText.headlineMd),
          const SizedBox(height: 12),
          MetaRow(icon: Icons.schedule, text: occ.timeLabel),
          const SizedBox(height: 6),
          MetaRow(icon: Icons.place_outlined, text: occ.room),
          const SizedBox(height: 6),
          MetaRow(icon: Icons.person_outline, text: occ.profName),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Navigate to Room',
            icon: Icons.navigation_outlined,
            height: 48,
            onPressed: () => context.go(Routes.map),
          ),
        ],
      ),
    );
  }
}

/// Live countdown ("in 18:23") to a HH:mm start time today.
class _Countdown extends StatefulWidget {
  final String start;
  const _Countdown({required this.start});
  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  @override
  Widget build(BuildContext context) {
    final parts = widget.start.split(':');
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day,
        int.tryParse(parts[0]) ?? 0, int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
    final diff = target.difference(now);
    final label = diff.isNegative
        ? 'now'
        : 'in ${diff.inHours > 0 ? '${diff.inHours}h ' : ''}${diff.inMinutes % 60}m';
    return Text(label,
        style: AppText.labelLg.copyWith(color: AppColors.accentUpcoming));
  }
}

class _Tile extends StatelessWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _Tile({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final plain = bg == AppColors.fill;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: plain ? null : AppShadow.l1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconCircle(
              icon: icon,
              tint: plain ? Colors.white : Colors.white.withValues(alpha: 0.45),
              color: fg,
              size: 40,
              iconSize: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.labelLg.copyWith(fontSize: 15, color: fg)),
                Text(sub,
                    style: AppText.bodyMd.copyWith(
                        fontSize: 13, color: fg.withValues(alpha: 0.75))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpNextSkeleton extends StatelessWidget {
  const _UpNextSkeleton();
  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: AppColors.accentUpcoming,
      pad: 18,
      child: const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primaryNavy, strokeWidth: 2.4),
        ),
      ),
    );
  }
}
