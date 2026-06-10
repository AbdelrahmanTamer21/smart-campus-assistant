import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';
import 'user_profile.dart';

/// Valid announcement audience values stored in Firestore.
abstract final class AnnouncementAudience {
  static const allStudents = 'All Students';
  static const campusWide = 'Campus-Wide';
  static const courses = 'Courses';
  static const faculty = 'Faculty';

  static List<String> optionsFor(UserRole role) => switch (role) {
        UserRole.admin => [allStudents, campusWide, courses, faculty],
        UserRole.staff => [allStudents, courses],
        _ => const [],
      };
}

class Announcement {
  final String id;
  final String dept;
  final int accent; // ARGB accent for the left bar / tag
  final String title;
  final String body;
  final String summary;
  final bool urgent;
  final bool pinned;
  final String audience;
  final List<String> targetCourseIds;
  final List<String> targetFacultyIds;
  final DateTime? createdAt;

  const Announcement({
    required this.id,
    required this.dept,
    required this.title,
    this.accent = 0xFF002147,
    this.body = '',
    this.summary = '',
    this.urgent = false,
    this.pinned = false,
    this.audience = AnnouncementAudience.allStudents,
    this.targetCourseIds = const [],
    this.targetFacultyIds = const [],
    this.createdAt,
  });

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Announcement(
      id: doc.id,
      dept: d['dept'] ?? 'General',
      accent: d['accent'] is int
          ? d['accent']
          : int.tryParse('${d['accent']}') ?? 0xFF002147,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      summary: d['summary'] ?? '',
      urgent: d['urgent'] ?? false,
      pinned: d['pinned'] ?? false,
      audience: d['audience'] ?? AnnouncementAudience.allStudents,
      targetCourseIds: List<String>.from(d['targetCourseIds'] ?? const []),
      targetFacultyIds: List<String>.from(d['targetFacultyIds'] ?? const []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Whether this announcement should appear in [profile]'s feed.
  bool isVisibleTo(UserProfile profile, UserRole activeRole) {
    if (activeRole == UserRole.admin) return true;

    switch (audience) {
      case AnnouncementAudience.campusWide:
        return true;
      case AnnouncementAudience.allStudents:
        return activeRole == UserRole.student || activeRole == UserRole.staff;
      case AnnouncementAudience.courses:
        return targetCourseIds.any((id) =>
            profile.enrolledCourseIds.contains(id) ||
            profile.teachingCourseIds.contains(id));
      case AnnouncementAudience.faculty:
        return activeRole == UserRole.staff &&
            targetFacultyIds.contains(profile.docId);
      default:
        return audience != 'My Courses' && activeRole == UserRole.student;
    }
  }

  Map<String, dynamic> toMap() => {
        'dept': dept,
        'accent': accent,
        'title': title,
        'body': body,
        'summary': summary,
        'urgent': urgent,
        'pinned': pinned,
        'audience': audience,
        if (targetCourseIds.isNotEmpty) 'targetCourseIds': targetCourseIds,
        if (targetFacultyIds.isNotEmpty) 'targetFacultyIds': targetFacultyIds,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Relative "x ago" label.
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
