import '../models/assignment.dart';
import '../models/class_occurrence.dart';
import '../models/course.dart';
import '../models/announcement.dart';
import '../models/user_profile.dart';
import '../models/enums.dart' show ClassStatus;

/// A cache-first snapshot of the user's own campus data, assembled for the AI
/// engine. Built only from the signed-in user's providers — never another
/// user's data (hard data-scoping guardrail).
class AiContext {
  final UserProfile? profile;
  final List<ClassOccurrence> today;
  final List<Assignment> deadlines;
  final List<Announcement> announcements;
  final List<Course> courses;
  final bool fromCache;

  const AiContext({
    this.profile,
    this.today = const [],
    this.deadlines = const [],
    this.announcements = const [],
    this.courses = const [],
    this.fromCache = false,
  });

  ClassOccurrence? get nextClass {
    final upcoming =
        today.where((c) => c.status != ClassStatus.cancelled).toList();
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Assignment? get nextDeadline => deadlines.isEmpty ? null : deadlines.first;

  Assignment? get nextExam {
    final exams = deadlines.where((d) => d.isExam).toList();
    return exams.isEmpty ? null : exams.first;
  }
}
