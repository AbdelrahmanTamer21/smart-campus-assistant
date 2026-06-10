import 'package:cloud_firestore/cloud_firestore.dart';

class CourseSession {
  final String day; // MON / WED / FRI
  final String start;
  final String end;
  final String room;
  const CourseSession({
    required this.day,
    required this.start,
    required this.end,
    required this.room,
  });
  factory CourseSession.fromMap(Map<String, dynamic> m) => CourseSession(
        day: m['day'] ?? '',
        start: m['start'] ?? '',
        end: m['end'] ?? '',
        room: m['room'] ?? '',
      );
  Map<String, dynamic> toMap() =>
      {'day': day, 'start': start, 'end': end, 'room': room};
  String get timeLabel => '$start – $end';
}

class ResourceFile {
  final String name;
  final String size;
  final String? storagePath;
  const ResourceFile({required this.name, required this.size, this.storagePath});
  factory ResourceFile.fromMap(Map<String, dynamic> m) => ResourceFile(
        name: m['name'] ?? '',
        size: m['size'] ?? '',
        storagePath: m['storagePath'],
      );
  Map<String, dynamic> toMap() =>
      {'name': name, 'size': size, 'storagePath': storagePath};
}

class Course {
  final String id;
  final String code;
  final String title;
  final String profUid;
  final String profName;
  final String dept;
  final String initials;
  final List<CourseSession> sessions;
  final List<ResourceFile> resources;
  final int studentCount;

  const Course({
    required this.id,
    required this.code,
    required this.title,
    this.profUid = '',
    this.profName = '',
    this.dept = '',
    this.initials = '',
    this.sessions = const [],
    this.resources = const [],
    this.studentCount = 0,
  });

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Course(
      id: doc.id,
      code: d['code'] ?? '',
      title: d['title'] ?? '',
      profUid: d['profUid'] ?? '',
      profName: d['profName'] ?? '',
      dept: d['dept'] ?? '',
      initials: d['initials'] ?? '',
      sessions: (d['sessions'] as List?)
              ?.map((e) => CourseSession.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      resources: (d['resources'] as List?)
              ?.map((e) => ResourceFile.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      studentCount: d['studentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'title': title,
        'profUid': profUid,
        'profName': profName,
        'dept': dept,
        'initials': initials,
        'sessions': sessions.map((s) => s.toMap()).toList(),
        'resources': resources.map((r) => r.toMap()).toList(),
        'studentCount': studentCount,
      };
}
