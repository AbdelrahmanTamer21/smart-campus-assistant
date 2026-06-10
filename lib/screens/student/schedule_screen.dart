import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/class_occurrence.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/course_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';
import 'staff_edit_sheets.dart';

/// Today's Schedule — vertical timeline of class occurrences for the user's
/// enrolled/taught courses, with date navigation. Staff can edit occurrences.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _day = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final repo = context.read<CourseRepo>();
    final isStaff = auth.activeRole == UserRole.staff;
    final courseIds = isStaff
        ? (auth.profile?.teachingCourseIds ?? const [])
        : (auth.profile?.enrolledCourseIds ?? const []);

    return ScreenScaffold(
      header: SCAppBar(
        leading: Avatar(
            initials: auth.profile?.initials ?? 'U',
            size: 40,
            onTap: () => context.push(Routes.profile)),
        trailing: CircleIconButton(
            icon: Icons.notifications_outlined,
            onTap: () => context.push(Routes.notifications)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isToday(_day) ? "Today's Schedule" : 'Schedule',
                style: AppText.headlineLg),
            const SizedBox(height: 8),
            _DateBar(
              day: _day,
              onPrev: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
              onNext: () => setState(() => _day = _day.add(const Duration(days: 1))),
              onToday: () => setState(() => _day = DateTime.now()),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<ClassOccurrence>>(
              stream: repo.watchDay(courseIds, _day),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snap.hasError) {
                  return ErrorStateView(message: 'Couldn\'t load your schedule.');
                }
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.event_busy,
                      title: 'No classes',
                      sub: 'Nothing scheduled for this day.');
                }
                return Column(
                  children: [
                    for (final c in list)
                      _TimelineRow(occ: c, isStaff: isStaff, repo: repo),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}

class _DateBar extends StatelessWidget {
  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  const _DateBar({
    required this.day,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });
  @override
  Widget build(BuildContext context) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final label = '${_ordinalWeekday(day)}, ${months[day.month - 1]} ${day.day}';
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: AppText.bodyLg.copyWith(color: AppColors.textMuted))),
        GestureDetector(onTap: onPrev, child: const Icon(Icons.chevron_left, color: AppColors.primaryNavy)),
        GestureDetector(
          onTap: onToday,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text('Today', style: AppText.labelSm.copyWith(color: AppColors.primaryNavy)),
          ),
        ),
        GestureDetector(onTap: onNext, child: const Icon(Icons.chevron_right, color: AppColors.primaryNavy)),
      ],
    );
  }

  static String _ordinalWeekday(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[d.weekday - 1];
  }
}

class _TimelineRow extends StatelessWidget {
  final ClassOccurrence occ;
  final bool isStaff;
  final CourseRepo repo;
  const _TimelineRow({required this.occ, required this.isStaff, required this.repo});

  @override
  Widget build(BuildContext context) {
    final cancelled = occ.status == ClassStatus.cancelled;
    final accent = switch (occ.status) {
      ClassStatus.cancelled => AppColors.accentUrgent,
      ClassStatus.roomchanged => AppColors.roomChanged,
      _ => AppColors.accentUpcoming,
    };
    final chip = switch (occ.status) {
      ClassStatus.cancelled => ChipVariant.cancelled,
      ClassStatus.roomchanged => ChipVariant.roomchanged,
      _ => ChipVariant.confirmed,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(occ.start,
                  textAlign: TextAlign.right,
                  style: AppText.labelSm.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              const SizedBox(height: 5),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2.5),
                ),
              ),
              Expanded(
                child: Container(width: 2, color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppCard(
                accent: accent,
                pad: 14,
                opacity: cancelled ? 0.7 : 1,
                onTap: () => context.push('${Routes.course}/${occ.courseId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(occ.title,
                              style: AppText.headlineSm.copyWith(
                                  fontSize: 17,
                                  decoration: cancelled
                                      ? TextDecoration.lineThrough
                                      : null)),
                        ),
                        StatusChip(variant: chip),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MetaRow(icon: Icons.schedule, text: '${occ.timeLabel} · ${occ.code}'),
                    const SizedBox(height: 5),
                    MetaRow(
                        icon: Icons.place_outlined,
                        text: occ.room,
                        color: occ.status == ClassStatus.roomchanged
                            ? AppColors.roomChangedFg
                            : AppColors.textMuted),
                    const SizedBox(height: 5),
                    MetaRow(icon: Icons.person_outline, text: occ.profName),
                    if (isStaff) ...[
                      const SizedBox(height: 12),
                      OutlineButton(
                        label: 'Edit Class',
                        icon: Icons.edit_outlined,
                        height: 42,
                        onPressed: () => showEditOccurrenceSheet(context, occ, repo),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
