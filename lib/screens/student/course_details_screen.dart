import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/course_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';
import 'staff_edit_sheets.dart';

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;
  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CourseRepo>();
    final role = context.watch<AuthProvider>().activeRole;
    final isAdmin = role == UserRole.admin;
    final canManage = role == UserRole.staff || isAdmin;

    return ScreenScaffold(
      header: StreamBuilder<Course?>(
        stream: repo.watchCourse(courseId),
        builder: (context, snap) => SCAppBar(
          onBack: () => context.pop(),
          title: 'Course',
          subtitle: snap.data?.code ?? 'Course',
        ),
      ),
      bottomNav: const RoleNav(current: Routes.course),
      body: StreamBuilder<Course?>(
        stream: repo.watchCourse(courseId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          final c = snap.data;
          if (c == null) {
            return const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Course not found',
                sub: 'This course may have been removed.');
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, 0, AppSpacing.screen, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Hero(
                  course: c,
                  onEdit: isAdmin
                      ? () => showEditCourseSheet(
                            context,
                            repo,
                            existing: c,
                            onDeleted: () => context.pop(),
                          )
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Weekly sessions
                const SectionHeader(title: 'Weekly Sessions'),
                for (final s in c.sessions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      accent: AppColors.accentAcademic,
                      pad: 12,
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: AppColors.secondaryCyan,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(s.day,
                                style: AppText.labelLg
                                    .copyWith(color: AppColors.primaryNavy)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.timeLabel,
                                    style: AppText.labelLg.copyWith(fontSize: 15)),
                                const SizedBox(height: 2),
                                MetaRow(icon: Icons.place_outlined, text: s.room),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // Deadlines for this course
                SectionHeader(
                  title: 'Upcoming Deadlines',
                  action: canManage ? 'Add' : null,
                  onAction: canManage
                      ? () => showAssignmentSheet(context, repo,
                          courseId: c.id, courseCode: c.code)
                      : null,
                ),
                StreamBuilder<List<Assignment>>(
                  stream: repo.watchAssignments([c.id]),
                  builder: (context, asnap) {
                    final list = asnap.data ?? const [];
                    if (list.isEmpty) {
                      return Text('No deadlines yet.',
                          style: AppText.bodyMd.copyWith(color: AppColors.textMuted));
                    }
                    return Column(
                      children: [
                        for (final a in list)
                          ListRow(
                            icon: a.isExam ? Icons.quiz_outlined : Icons.assignment_outlined,
                            iconTint: a.isUrgent ? AppColors.errorContainer : AppColors.fill,
                            accent: a.isUrgent ? AppColors.accentUrgent : AppColors.accentNeutral,
                            title: a.title,
                            meta: a.type.label,
                            chevron: false,
                            onTap: canManage
                                ? () => showAssignmentSheet(context, repo,
                                    courseId: c.id, courseCode: c.code, existing: a)
                                : null,
                            trailing: Text(a.dueLabel,
                                style: AppText.labelLg.copyWith(
                                    fontSize: 13,
                                    color: a.isUrgent ? AppColors.error : AppColors.textMuted)),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Resources
                const SectionHeader(title: 'Course Resources'),
                AppCard(
                  pad: 6,
                  child: Column(
                    children: [
                      for (int i = 0; i < c.resources.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: i < c.resources.length - 1
                                  ? BorderSide(color: AppColors.border.withValues(alpha: 0.4))
                                  : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            children: [
                              const IconCircle(
                                  icon: Icons.picture_as_pdf_outlined,
                                  tint: AppColors.fillLow,
                                  color: AppColors.error,
                                  size: 40,
                                  iconSize: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.resources[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.labelLg.copyWith(fontSize: 14)),
                                    Text('PDF · ${c.resources[i].size}',
                                        style: AppText.labelSm
                                            .copyWith(color: AppColors.hint)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(
                                        'Downloading ${c.resources[i].name} — available offline.'))),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                      color: AppColors.fill, shape: BoxShape.circle),
                                  child: const Icon(Icons.download_outlined,
                                      size: 18, color: AppColors.primaryNavy),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (role == UserRole.student) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    background: AppColors.secondaryCyan,
                    shadow: const [],
                    pad: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const IconCircle(
                                icon: Icons.auto_awesome,
                                tint: Colors.white,
                                color: AppColors.primaryNavy,
                                size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Course Assistant',
                                      style: AppText.headlineSm.copyWith(
                                          fontSize: 17,
                                          color: AppColors.primaryNavy)),
                                  Text('Ask anything about ${c.code}',
                                      style: AppText.bodyMd.copyWith(
                                          color: AppColors.primaryNavy
                                              .withValues(alpha: 0.8))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: 'Start Learning',
                          icon: Icons.auto_awesome,
                          height: 48,
                          onPressed: () => context.go(Routes.ai),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Course course;
  final VoidCallback? onEdit;
  const _Hero({required this.course, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.l2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(text: course.code, bg: Colors.white.withValues(alpha: 0.16), fg: Colors.white),
              const Spacer(),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('Edit',
                            style: AppText.labelSm.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(course.title,
              style: AppText.headlineMd.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Avatar(
                  initials: course.initials,
                  bg: AppColors.inversePrimary,
                  color: AppColors.primaryNavy,
                  size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.profName,
                        style: AppText.labelLg.copyWith(color: Colors.white)),
                    Text(course.dept,
                        style: AppText.bodyMd.copyWith(color: AppColors.inversePrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
