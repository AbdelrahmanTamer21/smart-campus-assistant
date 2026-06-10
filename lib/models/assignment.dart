import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Deadlines & assignments, per course.
class Assignment {
  final String id;
  final String courseId;
  final String code;
  final String title;
  final AssignmentType type;
  final DateTime dueAt;
  final String description;
  final String createdByUid;

  const Assignment({
    required this.id,
    required this.courseId,
    required this.code,
    required this.title,
    required this.type,
    required this.dueAt,
    this.description = '',
    this.createdByUid = '',
  });

  bool get isExam => type == AssignmentType.exam;

  factory Assignment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Assignment(
      id: doc.id,
      courseId: d['courseId'] ?? '',
      code: d['code'] ?? '',
      title: d['title'] ?? '',
      type: AssignmentTypeX.fromId(d['type']),
      dueAt: (d['dueAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: d['description'] ?? '',
      createdByUid: d['createdByUid'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'courseId': courseId,
        'code': code,
        'title': title,
        'type': type.id,
        'dueAt': Timestamp.fromDate(dueAt),
        'description': description,
        'createdByUid': createdByUid,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Human urgency label derived from [dueAt].
  String get dueLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
    final days = due.difference(today).inDays;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Due Today';
    if (days == 1) return 'Due Tomorrow';
    if (days <= 7) return 'Due in $days days';
    return 'Due ${_month(dueAt.month)} ${dueAt.day}';
  }

  bool get isUrgent {
    final days = DateTime(dueAt.year, dueAt.month, dueAt.day)
        .difference(DateTime.now())
        .inDays;
    return days <= 1;
  }

  static String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}
