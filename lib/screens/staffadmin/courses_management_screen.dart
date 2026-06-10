import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/class_occurrence.dart';
import '../../models/course.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/course_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';
import '../student/staff_edit_sheets.dart';

const _classFilters = ['All', 'Confirmed', 'Room Changed', 'Cancelled'];

String _shortDept(String dept) {
  if (dept.isEmpty) return 'Other';
  final i = dept.lastIndexOf(' of ');
  return i >= 0 ? dept.substring(i + 4) : dept;
}

/// Admin: browse all courses and manage campus-wide class occurrences.
class CoursesManagementScreen extends StatefulWidget {
  const CoursesManagementScreen({super.key});

  @override
  State<CoursesManagementScreen> createState() => _CoursesManagementScreenState();
}

class _CoursesManagementScreenState extends State<CoursesManagementScreen> {
  int _tab = 0;
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _day = _dateOnly(DateTime.now());
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CourseRepo>();
    final profile = context.watch<AuthProvider>().profile;

    return ScreenScaffold(
      scrollable: false,
      header: SCAppBar(
        leading: Avatar(
          initials: profile?.initials ?? 'AD',
          size: 40,
          bg: AppColors.accentSocial,
          onTap: () => context.push(Routes.profile),
        ),
        title: 'Admin',
        subtitle: 'Courses & Classes',
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Academic Catalog', style: AppText.headlineMd),
            const SizedBox(height: 4),
            Text('Manage course offerings and edit class schedules campus-wide.',
                style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            _SegmentedTab(
              left: 'Courses',
              right: 'Classes',
              leftSelected: _tab == 0,
              onLeft: () => setState(() => _tab = 0),
              onRight: () => setState(() => _tab = 1),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tab == 0
                  ? _CoursesList(
                      repo: repo,
                      onAddCourse: () => showEditCourseSheet(context, repo),
                    )
                  : _ClassesList(
                      repo: repo,
                      day: _day,
                      onDayChanged: (d) => setState(() => _day = _dateOnly(d)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTab extends StatelessWidget {
  final String left;
  final String right;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  const _SegmentedTab({
    required this.left,
    required this.right,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          Expanded(child: _seg(left, leftSelected, onLeft)),
          Expanded(child: _seg(right, !leftSelected, onRight)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: on ? AppShadow.l1 : null,
          ),
          child: Text(
            label,
            style: AppText.labelLg.copyWith(
              fontSize: 13,
              color: on ? AppColors.primaryNavy : AppColors.hint,
            ),
          ),
        ),
      );
}

class _CoursesList extends StatefulWidget {
  final CourseRepo repo;
  final VoidCallback onAddCourse;
  const _CoursesList({required this.repo, required this.onAddCourse});

  @override
  State<_CoursesList> createState() => _CoursesListState();
}

class _CoursesListState extends State<_CoursesList> {
  int _filter = 0;
  final _search = TextEditingController();
  List<String> _deptFilters = const ['All'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Course> _applyFilters(List<Course> list) {
    final q = _search.text.trim().toLowerCase();
    final dept = _deptFilters[_filter];
    return list.where((c) {
      if (_filter > 0 && _shortDept(c.dept) != dept) return false;
      if (q.isEmpty) return true;
      final hay = '${c.code} ${c.title} ${c.profName} ${c.dept}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Course>>(
      stream: widget.repo.watchAllCourses(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        final all = snap.data ?? const [];
        final depts = all.map((c) => _shortDept(c.dept)).toSet().toList()..sort();
        final filters = ['All', ...depts];
        if (filters.length != _deptFilters.length ||
            !filters.every((f) => _deptFilters.contains(f))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _deptFilters = filters;
              if (_filter >= filters.length) _filter = 0;
            });
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              icon: Icons.search,
              hint: 'Search courses',
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            FilterChipBar(
              items: _deptFilters,
              active: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onAddCourse,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add course'),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _buildList(all),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(List<Course> all) {
    if (all.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No courses',
        sub: 'Course records will appear here once added.',
      );
    }
    final list = _applyFilters(all);
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.filter_list_off,
        title: 'No matches',
        sub: 'Try a different department or search term.',
      );
    }
    return ListView(
      children: [
        for (final c in list)
          ListRow(
            icon: Icons.school_outlined,
            iconTint: AppColors.secondaryCyan,
            title: c.code,
            meta: '${c.title} · ${c.profName.isEmpty ? 'Unassigned' : c.profName} · '
                '${c.studentCount} students · ${c.sessions.length} sessions/wk',
            onTap: () => context.push('${Routes.course}/${c.id}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.primaryNavy,
              onPressed: () => showEditCourseSheet(context, widget.repo, existing: c),
            ),
            chevron: false,
          ),
      ],
    );
  }
}

class _ClassesList extends StatefulWidget {
  final CourseRepo repo;
  final DateTime day;
  final ValueChanged<DateTime> onDayChanged;
  const _ClassesList({
    required this.repo,
    required this.day,
    required this.onDayChanged,
  });

  @override
  State<_ClassesList> createState() => _ClassesListState();
}

class _ClassesListState extends State<_ClassesList> {
  int _filter = 0;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ClassOccurrence> _applyFilters(List<ClassOccurrence> list) {
    final q = _search.text.trim().toLowerCase();
    return list.where((occ) {
      final statusOk = switch (_filter) {
        1 => occ.status == ClassStatus.confirmed,
        2 => occ.status == ClassStatus.roomchanged,
        3 => occ.status == ClassStatus.cancelled,
        _ => true,
      };
      if (!statusOk) return false;
      if (q.isEmpty) return true;
      final hay = '${occ.title} ${occ.code} ${occ.room} ${occ.profName}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateBar(
          day: widget.day,
          onPrev: () => widget.onDayChanged(widget.day.subtract(const Duration(days: 1))),
          onNext: () => widget.onDayChanged(widget.day.add(const Duration(days: 1))),
          onToday: () => widget.onDayChanged(DateTime.now()),
        ),
        const SizedBox(height: 12),
        AppTextField(
          icon: Icons.search,
          hint: 'Search classes',
          controller: _search,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        FilterChipBar(
          items: _classFilters,
          active: _filter,
          onChanged: (i) => setState(() => _filter = i),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: StreamBuilder<List<ClassOccurrence>>(
            stream: widget.repo.watchAllClassesForDay(widget.day),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }
              final all = snap.data ?? const [];
              if (all.isEmpty) {
                return EmptyState(
                  icon: Icons.event_busy,
                  title: 'No classes',
                  sub: 'Nothing scheduled for ${_formatDayLabel(widget.day)}.',
                );
              }
              final list = _applyFilters(all);
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.filter_list_off,
                  title: 'No matches',
                  sub: 'Try a different status filter or search term.',
                );
              }
              return ListView(
                children: [
                  for (final occ in list)
                    _ClassRow(occ: occ, repo: widget.repo),
                ],
              );
            },
          ),
        ),
      ],
    );
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

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    final isToday = _isToday(day);
    final label = '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isToday)
                Text('Today',
                    style: AppText.labelLg.copyWith(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.w700,
                    )),
              Text(
                label,
                style: AppText.bodyLg.copyWith(
                  color: isToday ? AppColors.textMuted : AppColors.textPrimary,
                  fontWeight: isToday ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onPrev,
          child: const Icon(Icons.chevron_left, color: AppColors.primaryNavy),
        ),
        if (!isToday) ...[
          GestureDetector(
            onTap: onToday,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('Today',
                  style: AppText.labelSm.copyWith(color: AppColors.primaryNavy)),
            ),
          ),
        ] else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text('Today', style: AppText.labelSm.copyWith(color: Colors.white)),
          ),
        GestureDetector(
          onTap: onNext,
          child: const Icon(Icons.chevron_right, color: AppColors.primaryNavy),
        ),
      ],
    );
  }
}

String _formatDayLabel(DateTime day) {
  final n = DateTime.now();
  if (day.year == n.year && day.month == n.month && day.day == n.day) {
    return 'today';
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[day.month - 1]} ${day.day}';
}

class _ClassRow extends StatelessWidget {
  final ClassOccurrence occ;
  final CourseRepo repo;
  const _ClassRow({required this.occ, required this.repo});

  @override
  Widget build(BuildContext context) {
    final cancelled = occ.status == ClassStatus.cancelled;
    final chip = switch (occ.status) {
      ClassStatus.cancelled => ChipVariant.cancelled,
      ClassStatus.roomchanged => ChipVariant.roomchanged,
      _ => ChipVariant.confirmed,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        pad: 14,
        onTap: () => context.push('${Routes.course}/${occ.courseId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    occ.title,
                    style: AppText.labelLg.copyWith(
                      fontSize: 15,
                      decoration: cancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                StatusChip(variant: chip),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${occ.timeLabel} · ${occ.code} · ${occ.room}',
              style: AppText.bodyMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(occ.profName, style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 10),
            OutlineButton(
              label: 'Edit Class',
              icon: Icons.edit_outlined,
              height: 40,
              onPressed: () => showEditOccurrenceSheet(context, occ, repo),
            ),
          ],
        ),
      ),
    );
  }
}
