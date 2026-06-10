import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app_config.dart';
import '../../models/announcement.dart';
import '../../models/course.dart';
import '../../models/enums.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../repositories/admin_repo.dart';
import '../../repositories/announcement_repo.dart';
import '../../repositories/course_repo.dart';
import '../../repositories/notification_repo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});
  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  late String _audience;
  final _selectedCourseIds = <String>{};
  final _selectedFacultyIds = <String>{};
  bool _urgent = false;
  bool _pinned = false;
  String? _err;

  List<UserProfile> _faculty = const [];
  bool _loadingFaculty = false;

  @override
  void initState() {
    super.initState();
    final role = context.read<AuthProvider>().activeRole;
    _audience = AnnouncementAudience.optionsFor(role).first;
    _loadFacultyIfNeeded();
  }

  Future<void> _loadFacultyIfNeeded() async {
    final role = context.read<AuthProvider>().activeRole;
    if (role != UserRole.admin) return;
    setState(() => _loadingFaculty = true);
    try {
      final list = await context.read<AdminRepo>().fetchFaculty();
      if (mounted) setState(() => _faculty = list);
    } finally {
      if (mounted) setState(() => _loadingFaculty = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _setAudience(String value) {
    setState(() {
      _audience = value;
      _err = null;
      if (value != AnnouncementAudience.courses) _selectedCourseIds.clear();
      if (value != AnnouncementAudience.faculty) _selectedFacultyIds.clear();
    });
  }

  void _toggleCourse(String id) {
    setState(() {
      if (_selectedCourseIds.contains(id)) {
        _selectedCourseIds.remove(id);
      } else {
        _selectedCourseIds.add(id);
      }
      _err = null;
    });
  }

  void _toggleFaculty(String id) {
    setState(() {
      if (_selectedFacultyIds.contains(id)) {
        _selectedFacultyIds.remove(id);
      } else {
        _selectedFacultyIds.add(id);
      }
      _err = null;
    });
  }

  String _audienceSummary() {
    return switch (_audience) {
      AnnouncementAudience.courses =>
        '${_selectedCourseIds.length} course${_selectedCourseIds.length == 1 ? '' : 's'}',
      AnnouncementAudience.faculty =>
        '${_selectedFacultyIds.length} faculty member${_selectedFacultyIds.length == 1 ? '' : 's'}',
      _ => _audience,
    };
  }

  Future<void> _publish() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _err = 'A title is required.');
      return;
    }
    if (_audience == AnnouncementAudience.courses && _selectedCourseIds.isEmpty) {
      setState(() => _err = 'Select at least one course.');
      return;
    }
    if (_audience == AnnouncementAudience.faculty && _selectedFacultyIds.isEmpty) {
      setState(() => _err = 'Select at least one faculty member.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final offline = context.read<ConnectivityProvider>().offline;
    final notif = context.read<NotificationRepo>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final accent =
        _urgent ? AppColors.accentUrgent.toARGB32() : AppColors.accentNeutral.toARGB32();
    final title = _title.text.trim();
    final body = _body.text.trim();
    final pushTitle = _urgent ? '⚠️ $title' : title;

    await context.read<AnnouncementRepo>().publish(Announcement(
          id: '',
          dept: auth.profile?.dept.isNotEmpty == true ? auth.profile!.dept : 'General',
          accent: accent,
          title: title,
          body: body,
          summary: body,
          urgent: _urgent,
          pinned: _pinned,
          audience: _audience,
          targetCourseIds: _selectedCourseIds.toList(),
          targetFacultyIds: _selectedFacultyIds.toList(),
        ));

    if (!offline && !AppConfig.serverNotifications) {
      switch (_audience) {
        case AnnouncementAudience.allStudents:
          await notif.fanOutToAllStudents(title: pushTitle, body: body);
        case AnnouncementAudience.campusWide:
          await notif.fanOutToCampusWide(title: pushTitle, body: body);
        case AnnouncementAudience.courses:
          for (final id in _selectedCourseIds) {
            await notif.fanOutToCourse(
              id,
              title: pushTitle,
              body: body,
              type: 'announcement',
              route: '/announcements',
            );
          }
        case AnnouncementAudience.faculty:
          await notif.fanOutToFaculty(
            _selectedFacultyIds.toList(),
            title: pushTitle,
            body: body,
          );
      }
    }

    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(offline
          ? 'Saved — will publish when you reconnect.'
          : 'Announcement published to ${_audienceSummary()}.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<ConnectivityProvider>().offline;
    final auth = context.watch<AuthProvider>();
    final role = auth.activeRole;
    final audiences = AnnouncementAudience.optionsFor(role);
    final courseRepo = context.read<CourseRepo>();

    return ScreenScaffold(
      header: SCAppBar(onBack: () => context.pop(), title: 'New', subtitle: 'Announcement'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: AppText.labelLg),
            const SizedBox(height: 7),
            AppTextField(
              icon: Icons.edit_outlined,
              hint: 'e.g. Lab hours extended',
              controller: _title,
              error: _err,
              onChanged: (_) => setState(() => _err = null),
            ),
            const SizedBox(height: 18),
            Text('Message', style: AppText.labelLg),
            const SizedBox(height: 7),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.fill, borderRadius: BorderRadius.circular(AppRadius.card)),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _body,
                maxLines: 5,
                style: AppText.bodyLg,
                decoration: const InputDecoration.collapsed(hintText: 'Write your announcement…'),
              ),
            ),
            const SizedBox(height: 18),
            Text('Audience', style: AppText.labelLg),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in audiences)
                  GestureDetector(
                    onTap: () => _setAudience(a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _audience == a ? AppColors.primaryNavy : AppColors.fill,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        a == AnnouncementAudience.courses ? 'Selected Courses' : a,
                        style: AppText.labelLg.copyWith(
                          fontSize: 13,
                          color: _audience == a ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_audience == AnnouncementAudience.courses) ...[
              const SizedBox(height: 14),
              Text('Choose courses', style: AppText.labelSm.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              _CoursePicker(
                repo: courseRepo,
                role: role,
                teachingCourseIds: auth.profile?.teachingCourseIds ?? const [],
                selected: _selectedCourseIds,
                onToggle: _toggleCourse,
              ),
            ],
            if (_audience == AnnouncementAudience.faculty) ...[
              const SizedBox(height: 14),
              Text('Choose faculty members',
                  style: AppText.labelSm.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              if (_loadingFaculty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else if (_faculty.isEmpty)
                Text('No faculty records found.',
                    style: AppText.bodyMd.copyWith(color: AppColors.hint))
              else
                _FacultyPicker(
                  faculty: _faculty,
                  selected: _selectedFacultyIds,
                  onToggle: _toggleFaculty,
                ),
            ],
            const SizedBox(height: 22),
            AppToggle(
                label: 'Mark as Urgent',
                sub: 'Sends a push alert to all recipients',
                value: _urgent,
                onChanged: (v) => setState(() => _urgent = v),
                color: AppColors.error),
            const SizedBox(height: 18),
            AppToggle(
                label: 'Pin to top',
                sub: 'Keeps this at the top of the feed',
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v)),
            const SizedBox(height: 24),
            PrimaryButton(
              label: offline ? 'Queue for Publishing' : 'Publish Announcement',
              icon: Icons.send,
              onPressed: _publish,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoursePicker extends StatelessWidget {
  final CourseRepo repo;
  final UserRole role;
  final List<String> teachingCourseIds;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _CoursePicker({
    required this.repo,
    required this.role,
    required this.teachingCourseIds,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final stream = role == UserRole.admin
        ? repo.watchAllCourses()
        : repo.watchCourses(teachingCourseIds);

    return StreamBuilder<List<Course>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final courses = snap.data ?? const [];
        if (courses.isEmpty) {
          return Text(
            role == UserRole.staff
                ? 'You have no assigned courses to announce to.'
                : 'No courses available.',
            style: AppText.bodyMd.copyWith(color: AppColors.hint),
          );
        }
        return Column(
          children: [
            for (final c in courses)
              _SelectRow(
                label: c.code.isNotEmpty ? '${c.code} · ${c.title}' : c.title,
                sub: c.dept,
                checked: selected.contains(c.id),
                onTap: () => onToggle(c.id),
              ),
          ],
        );
      },
    );
  }
}

class _FacultyPicker extends StatelessWidget {
  final List<UserProfile> faculty;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _FacultyPicker({
    required this.faculty,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final f in faculty)
          _SelectRow(
            label: f.name,
            sub: f.dept.isNotEmpty ? f.dept : f.idNumber,
            checked: selected.contains(f.docId),
            onTap: () => onToggle(f.docId),
          ),
      ],
    );
  }
}

class _SelectRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool checked;
  final VoidCallback onTap;

  const _SelectRow({
    required this.label,
    required this.sub,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: checked ? AppColors.primaryNavy.withValues(alpha: 0.08) : AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: checked ? AppColors.primaryNavy.withValues(alpha: 0.35) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: checked ? AppColors.primaryNavy : AppColors.hint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.labelLg.copyWith(fontSize: 14)),
                    if (sub.isNotEmpty)
                      Text(sub, style: AppText.labelSm.copyWith(color: AppColors.hint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
