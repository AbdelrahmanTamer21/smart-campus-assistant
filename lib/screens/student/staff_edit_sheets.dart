import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_config.dart';
import '../../models/assignment.dart';
import '../../models/class_occurrence.dart';
import '../../models/course.dart';
import '../../models/enums.dart';
import '../../models/user_profile.dart';
import '../../constants/campus_catalog.dart';
import '../../repositories/admin_repo.dart';
import '../../repositories/course_repo.dart';
import '../../repositories/notification_repo.dart';
import '../../services/data_constraints.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      // Keep sheet below status bar / Dynamic Island when content is tall.
      final maxHeight = media.size.height - media.padding.top - 12;
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom + 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              12,
              AppSpacing.screen,
              0,
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

Widget _grabber() => Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(4)),
      ),
    );

Widget _selectChip({
  required String label,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) =>
    ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primaryNavy,
      checkmarkColor: Colors.white,
      labelStyle: AppText.labelSm.copyWith(
        color: selected ? Colors.white : AppColors.textMuted,
      ),
      backgroundColor: AppColors.fill,
      shape: const StadiumBorder(),
      side: BorderSide.none,
    );

const _duePresets = [
  ('3 days', 3),
  ('1 week', 7),
  ('2 weeks', 14),
  ('1 month', 30),
];

bool _dueMatchesPreset(DateTime due, int days) {
  final target = DateTime.now().add(Duration(days: days));
  return due.year == target.year && due.month == target.month && due.day == target.day;
}

String _constraintMessage(Object e, [String fallback = 'Couldn\'t save changes.']) =>
    e is DataConstraintException ? e.message : fallback;

/// Close the bottom sheet, then run [after] on the next frame (avoids navigator lock).
void _finishSheet(BuildContext context, VoidCallback after) {
  if (!context.mounted) return;
  Navigator.of(context).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) => after());
}

/// Staff edit of a class occurrence — change room and/or status (F10 producer).
Future<void> showEditOccurrenceSheet(
    BuildContext context, ClassOccurrence occ, CourseRepo repo) {
  var selectedRoom = occ.room;
  final roomOptions = CampusCatalog.withValue(CampusCatalog.rooms, occ.room);
  ClassStatus status = occ.status;
  return _sheet(context, StatefulBuilder(
    builder: (context, setSheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grabber(),
        Text('Edit ${occ.title}', style: AppText.headlineSm),
        const SizedBox(height: 4),
        Text('${occ.code} · ${occ.timeLabel}',
            style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 18),
        Text('Room', style: AppText.labelLg),
        const SizedBox(height: 7),
        AppDropdownField<String>(
          icon: Icons.place_outlined,
          hint: 'Select room',
          value: selectedRoom,
          items: roomOptions,
          itemLabel: (r) => r,
          onChanged: (r) => setSheet(() => selectedRoom = r ?? selectedRoom),
        ),
        const SizedBox(height: 18),
        Text('Status', style: AppText.labelLg),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final s in ClassStatus.values)
              _selectChip(
                label: _statusLabel(s),
                selected: status == s,
                onSelected: (_) => setSheet(() => status = s),
              ),
          ],
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Save & Notify Students',
          icon: Icons.send_outlined,
          onPressed: () async {
            final notif = context.read<NotificationRepo>();
            final messenger = ScaffoldMessenger.of(context);
            try {
              await repo.editOccurrence(
                occ.id,
                room: selectedRoom,
                status: status,
                originalRoom: occ.originalRoom ?? occ.room,
              );
            } catch (e) {
              messenger.showSnackBar(
                  SnackBar(content: Text(_constraintMessage(e))));
              return;
            }
            final body = status == ClassStatus.cancelled
                ? '${occ.title} has been cancelled.'
                : '${occ.title} moved to $selectedRoom.';
            // Functions (emulator/deployed) fan out + push; otherwise do it here.
            if (!AppConfig.serverNotifications) {
              await notif.fanOutToCourse(occ.courseId,
                  title: 'Schedule update', body: body, type: 'class', route: '/schedule');
            }
            if (!context.mounted) return;
            _finishSheet(context, () {
              messenger.showSnackBar(const SnackBar(
                  content: Text('Class updated — students notified.')));
            });
          },
        ),
      ],
    ),
  ));
}

/// Staff create/edit of an assignment/deadline (F10 producer).
Future<void> showAssignmentSheet(
  BuildContext context,
  CourseRepo repo, {
  required String courseId,
  required String courseCode,
  Assignment? existing,
}) {
  final title = TextEditingController(text: existing?.title ?? '');
  AssignmentType type = existing?.type ?? AssignmentType.assignment;
  DateTime due = existing?.dueAt ?? DateTime.now().add(const Duration(days: 7));
  String? err;
  return _sheet(context, StatefulBuilder(
    builder: (context, setSheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grabber(),
        Text(existing == null ? 'New Deadline' : 'Edit Deadline',
            style: AppText.headlineSm),
        const SizedBox(height: 18),
        Text('Title', style: AppText.labelLg),
        const SizedBox(height: 7),
        AppTextField(
            icon: Icons.edit_outlined,
            controller: title,
            hint: 'e.g. Problem Set 5',
            error: err),
        const SizedBox(height: 18),
        Text('Type', style: AppText.labelLg),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in AssignmentType.values)
              _selectChip(
                label: t.label,
                selected: type == t,
                onSelected: (_) => setSheet(() => type = t),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Due date', style: AppText.labelLg),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, days) in _duePresets)
              GestureDetector(
                onTap: () => setSheet(
                    () => due = DateTime.now().add(Duration(days: days))),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _dueMatchesPreset(due, days)
                        ? AppColors.primaryNavy
                        : AppColors.fill,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    label,
                    style: AppText.labelLg.copyWith(
                      fontSize: 13,
                      color: _dueMatchesPreset(due, days)
                          ? Colors.white
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          pad: 14,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: due,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setSheet(() => due = picked);
          },
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppColors.primaryNavy),
              const SizedBox(width: 12),
              Text('${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}',
                  style: AppText.bodyLg),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.border),
            ],
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Save & Notify Students',
          icon: Icons.send_outlined,
          onPressed: () async {
            if (title.text.trim().isEmpty) {
              setSheet(() => err = 'A title is required.');
              return;
            }
            final notif = context.read<NotificationRepo>();
            final messenger = ScaffoldMessenger.of(context);
            try {
              await repo.upsertAssignment(Assignment(
                id: existing?.id ?? '',
                courseId: courseId,
                code: courseCode,
                title: title.text.trim(),
                type: type,
                dueAt: due,
              ));
            } catch (e) {
              setSheet(() => err = _constraintMessage(e));
              return;
            }
            if (!AppConfig.serverNotifications) {
              await notif.fanOutToCourse(courseId,
                  title: existing == null ? 'New deadline' : 'Deadline updated',
                  body: '${title.text.trim()} ($courseCode)',
                  type: 'deadline',
                  route: '/course/$courseId');
            }
            if (!context.mounted) return;
            _finishSheet(context, () {
              messenger.showSnackBar(const SnackBar(
                  content: Text('Deadline saved — students notified.')));
            });
          },
        ),
      ],
    ),
  ));
}

String _statusLabel(ClassStatus s) => switch (s) {
      ClassStatus.confirmed => 'Confirmed',
      ClassStatus.cancelled => 'Cancelled',
      ClassStatus.roomchanged => 'Room Changed',
    };

String _courseDocId(String code, String? existingId) {
  if (existingId != null && existingId.isNotEmpty) return existingId;
  final id = code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  return id.isEmpty ? 'COURSE${DateTime.now().millisecondsSinceEpoch}' : id;
}

/// Admin create/edit of a course catalog entry.
Future<void> showEditCourseSheet(
  BuildContext context,
  CourseRepo repo, {
  Course? existing,
  VoidCallback? onDeleted,
}) async {
  final faculty = await context.read<AdminRepo>().fetchFaculty();
  if (!context.mounted) return;
  return _sheet(
    context,
    _EditCourseSheetBody(
      repo: repo,
      existing: existing,
      faculty: faculty,
      onDeleted: onDeleted,
    ),
  );
}

class _EditCourseSheetBody extends StatefulWidget {
  final CourseRepo repo;
  final Course? existing;
  final List<UserProfile> faculty;
  final VoidCallback? onDeleted;
  const _EditCourseSheetBody({
    required this.repo,
    required this.existing,
    required this.faculty,
    this.onDeleted,
  });

  @override
  State<_EditCourseSheetBody> createState() => _EditCourseSheetBodyState();
}

class _EditCourseSheetBodyState extends State<_EditCourseSheetBody> {
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _students;
  late final TextEditingController _initialsCtrl;
  late UserProfile? _instructor;
  late String _dept;
  late List<CourseSession> _sessions;
  String? _err;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _code = TextEditingController(text: e?.code ?? '');
    _title = TextEditingController(text: e?.title ?? '');
    _students = TextEditingController(text: e?.studentCount.toString() ?? '0');
    _dept = e?.dept != null &&
            (CampusCatalog.departments.contains(e!.dept) ||
                CampusCatalog.withValue(CampusCatalog.departments, e.dept)
                    .contains(e.dept))
        ? e.dept
        : CampusCatalog.departments.first;
    UserProfile? matched;
    if (e != null && e.profName.isNotEmpty) {
      for (final f in widget.faculty) {
        if (f.name == e.profName) {
          matched = f;
          break;
        }
      }
    }
    _instructor = matched;
    final initials = _instructor?.initials ?? e?.initials ?? '';
    _initialsCtrl = TextEditingController(text: initials);
    _sessions = List<CourseSession>.from(e?.sessions ?? const []);
    if (_sessions.isEmpty) {
      _sessions = const [
        CourseSession(day: 'MON', start: '09:00', end: '10:30', room: 'Room 101'),
      ];
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _students.dispose();
    _initialsCtrl.dispose();
    super.dispose();
  }

  void _onInstructorChanged(UserProfile? faculty) {
    setState(() {
      _instructor = faculty;
      if (faculty != null) {
        _initialsCtrl.text = faculty.initials;
        if (faculty.dept.isNotEmpty &&
            CampusCatalog.departments.contains(faculty.dept)) {
          _dept = faculty.dept;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deptOptions = CampusCatalog.withValue(CampusCatalog.departments, _dept);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _grabber(),
          Text(widget.existing == null ? 'New Course' : 'Edit Course',
              style: AppText.headlineSm),
          const SizedBox(height: 18),
          Text('Course code', style: AppText.labelLg),
          const SizedBox(height: 7),
          AppTextField(
            icon: Icons.tag,
            controller: _code,
            hint: 'e.g. MATH-401',
            error: _err,
          ),
          const SizedBox(height: 14),
          Text('Title', style: AppText.labelLg),
          const SizedBox(height: 7),
          AppTextField(
            icon: Icons.menu_book_outlined,
            controller: _title,
            hint: 'Course title',
          ),
          const SizedBox(height: 14),
          Text('Instructor', style: AppText.labelLg),
          const SizedBox(height: 7),
          AppDropdownField<UserProfile?>(
            icon: Icons.person_outline,
            hint: 'Select faculty',
            value: _instructor,
            items: [null, ...widget.faculty],
            itemLabel: (f) => f?.name ?? 'Unassigned',
            onChanged: _onInstructorChanged,
          ),
          const SizedBox(height: 14),
          Text('Department', style: AppText.labelLg),
          const SizedBox(height: 7),
          AppDropdownField<String>(
            icon: Icons.apartment_outlined,
            hint: 'Select department',
            value: _dept,
            items: deptOptions,
            itemLabel: (d) => d,
            onChanged: (d) => setState(() => _dept = d ?? _dept),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Initials', style: AppText.labelLg),
                    const SizedBox(height: 7),
                    AppTextField(
                      icon: Icons.badge_outlined,
                      controller: _initialsCtrl,
                      hint: 'ER',
                      readOnly: _instructor != null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Students', style: AppText.labelLg),
                    const SizedBox(height: 7),
                    AppTextField(
                      icon: Icons.groups_outlined,
                      controller: _students,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text('Weekly sessions', style: AppText.labelLg)),
              TextButton.icon(
                onPressed: () => setState(() => _sessions = [
                      ..._sessions,
                      const CourseSession(
                          day: 'MON', start: '09:00', end: '10:30', room: 'Room 101'),
                    ]),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          for (int i = 0; i < _sessions.length; i++) ...[
            const SizedBox(height: 8),
            _SessionEditor(
              session: _sessions[i],
              onChanged: (s) => setState(() => _sessions[i] = s),
              onRemove: _sessions.length > 1
                  ? () => setState(() => _sessions = [
                        for (int j = 0; j < _sessions.length; j++)
                          if (j != i) _sessions[j],
                      ])
                  : null,
            ),
          ],
          const SizedBox(height: 22),
          PrimaryButton(
            label: widget.existing == null ? 'Create Course' : 'Save Course',
            icon: Icons.save_outlined,
            onPressed: _save,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 10),
            OutlineButton(
              label: 'Delete Course',
              icon: Icons.delete_outline,
              height: 44,
              onPressed: _delete,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_code.text.trim().isEmpty || _title.text.trim().isEmpty) {
      setState(() => _err = 'Code and title are required.');
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final count = int.tryParse(_students.text.trim()) ?? 0;
    final course = Course(
      id: _courseDocId(_code.text.trim(), widget.existing?.id),
      code: _code.text.trim(),
      title: _title.text.trim(),
      profName: _instructor?.name ?? '',
      dept: _dept,
      initials: _initialsCtrl.text.trim().toUpperCase(),
      studentCount: count,
      sessions: _sessions,
      resources: widget.existing?.resources ?? const [],
    );
    try {
      if (widget.existing == null && await widget.repo.courseExists(course.id)) {
        setState(() => _err = 'A course with this code already exists.');
        return;
      }
      await widget.repo.upsertCourse(course);
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = _constraintMessage(e));
      return;
    }
    if (!mounted) return;
    final msg = widget.existing == null ? 'Course created.' : 'Course updated.';
    _finishSheet(context, () {
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  Future<void> _delete() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final onDeleted = widget.onDeleted;
    try {
      await widget.repo.deleteCourse(widget.existing!.id);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_constraintMessage(e))));
      return;
    }
    if (!mounted) return;
    _finishSheet(context, () {
      onDeleted?.call();
      messenger.showSnackBar(
          const SnackBar(content: Text('Course removed.')));
    });
  }
}

class _SessionEditor extends StatefulWidget {
  final CourseSession session;
  final ValueChanged<CourseSession> onChanged;
  final VoidCallback? onRemove;
  const _SessionEditor({
    required this.session,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends State<_SessionEditor> {
  static const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  late String _day;
  late String _start;
  late String _end;
  late String _room;
  late List<String> _timeOptions;
  late List<String> _roomOptions;

  @override
  void initState() {
    super.initState();
    _day = _days.contains(widget.session.day) ? widget.session.day : 'MON';
    _timeOptions =
        CampusCatalog.withValue(CampusCatalog.timeSlots, widget.session.start);
    _timeOptions = CampusCatalog.withValue(_timeOptions, widget.session.end);
    _start = _timeOptions.contains(widget.session.start)
        ? widget.session.start
        : CampusCatalog.timeSlots.first;
    _end = _timeOptions.contains(widget.session.end)
        ? widget.session.end
        : CampusCatalog.timeSlots[2];
    _roomOptions = CampusCatalog.withValue(CampusCatalog.rooms, widget.session.room);
    _room = _roomOptions.contains(widget.session.room)
        ? widget.session.room
        : _roomOptions.first;
  }

  void _emit() => widget.onChanged(CourseSession(
        day: _day,
        start: _start,
        end: _end,
        room: _room,
      ));

  @override
  Widget build(BuildContext context) {
    return AppCard(
      pad: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day', style: AppText.labelSm.copyWith(color: AppColors.hint)),
          const SizedBox(height: 6),
          AppDropdownField<String>(
            icon: Icons.calendar_view_week,
            hint: 'Weekday',
            value: _day,
            items: _days,
            itemLabel: (d) => d,
            onChanged: (d) => setState(() {
              _day = d ?? _day;
              _emit();
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start', style: AppText.labelSm.copyWith(color: AppColors.hint)),
                    const SizedBox(height: 6),
                    AppDropdownField<String>(
                      icon: Icons.schedule,
                      hint: 'Start',
                      value: _start,
                      items: _timeOptions,
                      itemLabel: (t) => t,
                      onChanged: (t) => setState(() {
                        _start = t ?? _start;
                        _emit();
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End', style: AppText.labelSm.copyWith(color: AppColors.hint)),
                    const SizedBox(height: 6),
                    AppDropdownField<String>(
                      icon: Icons.schedule_outlined,
                      hint: 'End',
                      value: _end,
                      items: _timeOptions,
                      itemLabel: (t) => t,
                      onChanged: (t) => setState(() {
                        _end = t ?? _end;
                        _emit();
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Room', style: AppText.labelSm.copyWith(color: AppColors.hint)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppDropdownField<String>(
                  icon: Icons.place_outlined,
                  hint: 'Room',
                  value: _room,
                  items: _roomOptions,
                  itemLabel: (r) => r,
                  onChanged: (r) => setState(() {
                    _room = r ?? _room;
                    _emit();
                  }),
                ),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close, color: AppColors.error),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
