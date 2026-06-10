import '../models/assignment.dart';
import '../models/class_occurrence.dart';
import '../models/course.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';

/// Thrown when a write would break catalog or enrollment links.
class DataConstraintException implements Exception {
  final String message;
  const DataConstraintException(this.message);

  @override
  String toString() => message;
}

/// Client-side guards for linked Firestore data (courses ↔ users ↔ classes ↔ assignments).
class DataConstraints {
  DataConstraints._();

  static const _days = {'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'};
  static final _timeRe = RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$');

  static void validateCourse(Course course) {
    if (course.id.trim().isEmpty) {
      throw const DataConstraintException('Course id is required.');
    }
    if (course.code.trim().isEmpty || course.title.trim().isEmpty) {
      throw const DataConstraintException('Course code and title are required.');
    }
    if (course.studentCount < 0) {
      throw const DataConstraintException('Student count cannot be negative.');
    }
    if (course.initials.trim().length > 4) {
      throw const DataConstraintException('Initials must be four characters or fewer.');
    }
    for (var i = 0; i < course.sessions.length; i++) {
      _validateSession(course.sessions[i], index: i + 1);
    }
  }

  static void _validateSession(CourseSession session, {required int index}) {
    if (!_days.contains(session.day)) {
      throw DataConstraintException(
          'Session $index: pick a valid weekday (MON–SUN).');
    }
    if (!_timeRe.hasMatch(session.start) || !_timeRe.hasMatch(session.end)) {
      throw DataConstraintException(
          'Session $index: use 24-hour times like 09:00 and 13:30.');
    }
    if (_minutes(session.start) >= _minutes(session.end)) {
      throw DataConstraintException(
          'Session $index: end time must be after start time.');
    }
    if (session.room.trim().isEmpty) {
      throw DataConstraintException('Session $index: room is required.');
    }
  }

  static void validateAssignment(Assignment assignment) {
    if (assignment.courseId.trim().isEmpty) {
      throw const DataConstraintException('Assignment must belong to a course.');
    }
    if (assignment.title.trim().isEmpty) {
      throw const DataConstraintException('Deadline title is required.');
    }
    if (assignment.code.trim().isEmpty) {
      throw const DataConstraintException('Assignment course code is required.');
    }
  }

  static void validateOccurrenceEdit({
    required ClassOccurrence occ,
    required String room,
    required ClassStatus status,
  }) {
    if (status != ClassStatus.cancelled && room.trim().isEmpty) {
      throw const DataConstraintException(
          'Room is required unless the class is cancelled.');
    }
    if (occ.courseId.trim().isEmpty) {
      throw const DataConstraintException('Class is missing a linked course.');
    }
  }

  static void validateActivationTarget(UserProfile record) {
    if (record.status != AccountStatus.unclaimed) {
      throw const DataConstraintException(
          'Activation QR can only be issued for pending (unclaimed) accounts.');
    }
    if (record.idNumber.trim().isEmpty) {
      throw const DataConstraintException('User record is missing an ID number.');
    }
  }

  static void validateCourseDeletion(CourseLinkSummary links) {
    if (links.hasLinks) {
      throw DataConstraintException(
          'Cannot delete this course while linked data exists.\n${links.describe()}');
    }
  }

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

/// References that block course deletion or require sync after edits.
class CourseLinkSummary {
  final int enrolledUsers;
  final int teachingUsers;
  final int assignments;
  final int classes;

  const CourseLinkSummary({
    this.enrolledUsers = 0,
    this.teachingUsers = 0,
    this.assignments = 0,
    this.classes = 0,
  });

  bool get hasLinks =>
      enrolledUsers + teachingUsers + assignments + classes > 0;

  String describe() {
    final parts = <String>[];
    if (enrolledUsers > 0) {
      parts.add('$enrolledUsers enrolled student${enrolledUsers == 1 ? '' : 's'}');
    }
    if (teachingUsers > 0) {
      parts.add('$teachingUsers faculty assignment${teachingUsers == 1 ? '' : 's'}');
    }
    if (assignments > 0) {
      parts.add('$assignments deadline${assignments == 1 ? '' : 's'}');
    }
    if (classes > 0) {
      parts.add('$classes scheduled class${classes == 1 ? '' : 'es'}');
    }
    return parts.join(' · ');
  }
}
