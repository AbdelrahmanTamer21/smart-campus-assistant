import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Simulates the registrar/SIS import: pre-loads people (with roles, enrolment,
/// courses), expands timetable occurrences, seeds assignments, events,
/// announcements, map data and admin stats. Run once with --dart-define=SEED=true.
///
/// Creates a few pre-activated accounts (password: `campus123`) for login, plus
/// one UNCLAIMED record + a pending activation token to demo the QR flow.
class SeedService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const password = 'campus123';

  Future<void> run() async {
    final marker = await _db.collection('_meta').doc('seed').get();
    if (marker.exists) {
      debugPrint('Seed already applied — skipping.');
      return;
    }
    debugPrint('Seeding Firestore…');

    await _seedCourses();
    await _seedClasses();
    await _seedAssignments();
    await _seedEvents();
    await _seedAnnouncements();
    await _seedMap();
    await _seedAdminStats();
    await _seedUsers();
    await _seedPendingActivation();

    await _db.collection('_meta').doc('seed').set({
      'appliedAt': FieldValue.serverTimestamp(),
    });
    // Creating accounts signs us in as the last one — start clean.
    await _auth.signOut();
    debugPrint('Seed complete. Log in with any seeded ID / password "campus123".');
  }

  Future<void> _seedCourses() async {
    final courses = {
      'MATH401': {
        'code': 'MATH-401',
        'title': 'Advanced Calculus',
        'profName': 'Dr. Emily Roberts',
        'dept': 'Department of Mathematics',
        'initials': 'ER',
        'studentCount': 42,
        'sessions': [
          {'day': 'MON', 'start': '11:30', 'end': '13:00', 'room': 'Room 204'},
          {'day': 'WED', 'start': '11:30', 'end': '13:00', 'room': 'Room 204'},
          {'day': 'FRI', 'start': '10:00', 'end': '11:30', 'room': 'Lab 2'},
        ],
        'resources': [
          {'name': 'Syllabus.pdf', 'size': '240 KB'},
          {'name': 'Lecture Notes — Week 6.pdf', 'size': '1.8 MB'},
          {'name': 'Practice Midterm.pdf', 'size': '512 KB'},
        ],
      },
      'MATH220': {
        'code': 'MATH-220',
        'title': 'Linear Algebra',
        'profName': 'Dr. Chen',
        'dept': 'Department of Mathematics',
        'initials': 'LC',
        'studentCount': 36,
        'sessions': [
          {'day': 'TUE', 'start': '13:00', 'end': '14:30', 'room': 'Room 112'},
          {'day': 'THU', 'start': '13:00', 'end': '14:30', 'room': 'Room 112'},
        ],
        'resources': [
          {'name': 'Course Outline.pdf', 'size': '180 KB'},
        ],
      },
      'ART150': {
        'code': 'ART-150',
        'title': 'Art History',
        'profName': 'Dr. Vance',
        'dept': 'Department of Fine Arts',
        'initials': 'DV',
        'studentCount': 58,
        'sessions': [
          {'day': 'MON', 'start': '14:00', 'end': '15:30', 'room': 'Room 202'},
        ],
        'resources': const [],
      },
      'PHYS210': {
        'code': 'PHYS-210',
        'title': 'Physics Seminar',
        'profName': 'Dr. Okafor',
        'dept': 'Department of Physics',
        'initials': 'DO',
        'studentCount': 24,
        'sessions': [
          {'day': 'MON', 'start': '16:00', 'end': '17:30', 'room': 'Lab 3'},
        ],
        'resources': const [],
      },
    };
    for (final e in courses.entries) {
      await _db.collection('courses').doc(e.key).set(e.value);
    }
  }

  /// Expand today's occurrences so the schedule/dashboard have live data.
  Future<void> _seedClasses() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = [
      {'courseId': 'MATH220', 'code': 'MATH-220', 'title': 'Linear Algebra', 'profName': 'Dr. Chen', 'start': '09:00', 'end': '10:30', 'room': 'Room 112', 'status': 'confirmed'},
      {'courseId': 'MATH401', 'code': 'MATH-401', 'title': 'Advanced Calculus', 'profName': 'Dr. Emily Roberts', 'start': '11:30', 'end': '13:00', 'room': 'Room 204', 'status': 'confirmed'},
      {'courseId': 'ART150', 'code': 'ART-150', 'title': 'Art History', 'profName': 'Dr. Vance', 'start': '14:00', 'end': '15:30', 'room': 'Room 202', 'status': 'roomchanged'},
      {'courseId': 'PHYS210', 'code': 'PHYS-210', 'title': 'Physics Seminar', 'profName': 'Dr. Okafor', 'start': '16:00', 'end': '17:30', 'room': 'Lab 3', 'status': 'cancelled'},
    ];
    for (final c in items) {
      await _db.collection('classes').add({
        ...c,
        'date': Timestamp.fromDate(today),
      });
    }
  }

  Future<void> _seedAssignments() async {
    final now = DateTime.now();
    final items = [
      {'courseId': 'PHYS210', 'code': 'PHYS-210', 'title': 'Physics Lab Report', 'type': 'assignment', 'days': 1},
      {'courseId': 'ART150', 'code': 'ART-150', 'title': 'Essay: Modern Art', 'type': 'assignment', 'days': 3},
      {'courseId': 'MATH401', 'code': 'MATH-401', 'title': 'Problem Set 4', 'type': 'problemset', 'days': 5},
      {'courseId': 'MATH401', 'code': 'MATH-401', 'title': 'Midterm Exam', 'type': 'exam', 'days': 9},
    ];
    for (final a in items) {
      await _db.collection('assignments').add({
        'courseId': a['courseId'],
        'code': a['code'],
        'title': a['title'],
        'type': a['type'],
        'dueAt': Timestamp.fromDate(now.add(Duration(days: a['days'] as int))),
        'description': '',
        'createdByUid': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _seedEvents() async {
    final events = [
      {'title': 'Annual Tech Mixer', 'cat': 'Career', 'date': 'Today · 5:00 PM', 'loc': 'Innovation Hub', 'featured': true, 'tint': 0xFF1F3A5F},
      {'title': 'Guest Lecture: Quantum Computing', 'cat': 'Academic', 'date': 'Oct 24 · 2:00 PM', 'loc': 'Auditorium A', 'featured': false, 'tint': 0xFF3E5C76},
      {'title': 'Inter-College Basketball Finals', 'cat': 'Sports', 'date': 'Oct 25 · 6:30 PM', 'loc': 'Main Arena', 'featured': false, 'tint': 0xFF5B4B7A},
      {'title': 'Wellness & Mindfulness Night', 'cat': 'Social', 'date': 'Oct 26 · 7:00 PM', 'loc': 'Student Union', 'featured': false, 'tint': 0xFF6A4E8C},
      {'title': 'Career Fair: Spring Internships', 'cat': 'Career', 'date': 'Oct 27 · 10:00 AM', 'loc': 'Grand Hall', 'featured': false, 'tint': 0xFF244A66},
    ];
    for (final e in events) {
      await _db.collection('events').add(e);
    }
  }

  Future<void> _seedAnnouncements() async {
    final base = DateTime.now();
    final items = [
      {'dept': 'Campus Safety', 'accent': 0xFFBA1A1A, 'title': 'Emergency Power Outage — Science Wing', 'urgent': true, 'pinned': true, 'minsAgo': 20,
        'body': 'A planned electrical maintenance will cut power to the Science Wing from 1–4 PM today. Labs are closed during this window.',
        'summary': 'Science Wing power is out 1–4 PM today for maintenance. All labs closed; classes relocated — check your schedule.'},
      {'dept': 'Engineering', 'accent': 0xFF3E8E9B, 'title': 'Robotics Lab Hours Extended', 'urgent': false, 'pinned': false, 'minsAgo': 120,
        'body': '', 'summary': 'Robotics Lab now open until 11 PM on weekdays through finals. Badge access required after 8 PM.'},
      {'dept': 'General', 'accent': 0xFF002147, 'title': 'Fall Registration Opens Monday', 'urgent': false, 'pinned': false, 'minsAgo': 300,
        'body': '', 'summary': 'Spring course registration opens Monday 8 AM by seniority. Meet your advisor before booking.'},
      {'dept': 'Athletics', 'accent': 0xFF9C5BB0, 'title': 'Gym Closed for Tournament', 'urgent': false, 'pinned': false, 'minsAgo': 1500,
        'body': '', 'summary': 'Main gym reserved for the regional tournament Fri–Sun. Annex facilities remain open to all students.'},
    ];
    for (final a in items) {
      await _db.collection('announcements').add({
        'dept': a['dept'],
        'accent': a['accent'],
        'title': a['title'],
        'body': a['body'],
        'summary': a['summary'],
        'urgent': a['urgent'],
        'pinned': a['pinned'],
        'audience': 'All Students',
        'createdByUid': '',
        'createdAt': Timestamp.fromDate(
            base.subtract(Duration(minutes: a['minsAgo'] as int))),
      });
    }
  }

  Future<void> _seedMap() async {
    final pins = [
      {'label': 'Science Center', 'x': 58, 'y': 38, 'kind': 'study'},
      {'label': 'Library', 'x': 30, 'y': 60, 'kind': 'study'},
      {'label': 'Union Café', 'x': 72, 'y': 66, 'kind': 'cafe'},
      {'label': 'Print Hub', 'x': 42, 'y': 28, 'kind': 'printer'},
    ];
    for (final p in pins) {
      await _db.collection('mapPins').add(p);
    }
  }

  Future<void> _seedAdminStats() async {
    await _db.collection('adminStats').doc('overview').set({
      'stats': [
        {'value': '12,402', 'label': 'Total Users'},
        {'value': '8,230', 'label': 'Active Students', 'trend': '4% increase', 'trendUp': true},
        {'value': '124', 'label': 'Published Announcements'},
      ],
      'engagementWeek': [42, 58, 51, 67, 73, 61, 80],
      'engagementMonth': [55, 62, 70, 78],
    });
  }

  /// Pre-activated accounts for direct login (password: campus123).
  Future<void> _seedUsers() async {
    await _activatedUser(
      docId: 'student_alex',
      idNumber: '202400123',
      name: 'Alex Morgan',
      initials: 'AM',
      roles: ['student'],
      dept: 'Computer Science',
      program: 'Undergraduate',
      enrolled: ['MATH401', 'MATH220', 'ART150', 'PHYS210'],
    );
    await _activatedUser(
      docId: 'staff_wilson',
      idNumber: '900100',
      name: 'Prof. Wilson',
      initials: 'PW',
      roles: ['staff'],
      dept: 'Mathematics',
      program: 'Faculty',
      teaching: ['MATH401', 'MATH220'],
    );
    await _activatedUser(
      docId: 'admin_console',
      idNumber: '500001',
      name: 'Admin Console',
      initials: 'AD',
      roles: ['admin'],
      dept: 'Administration',
      program: 'Administrator',
    );
  }

  Future<void> _activatedUser({
    required String docId,
    required String idNumber,
    required String name,
    required String initials,
    required List<String> roles,
    String dept = '',
    String program = '',
    List<String> enrolled = const [],
    List<String> teaching = const [],
  }) async {
    String? uid;
    final email = AuthService.emailFor(idNumber);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      uid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final cred = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        uid = cred.user!.uid;
      } else {
        rethrow;
      }
    }
    await _db.collection('users').doc(docId).set({
      'name': name,
      'first': name.split(' ').first,
      'idNumber': idNumber,
      'initials': initials,
      'roles': roles,
      'dept': dept,
      'program': program,
      'enrolledCourseIds': enrolled,
      'teachingCourseIds': teaching,
      'rsvps': <String>[],
      'status': 'active',
      'authUid': uid,
    });
    // Note: role custom claims are set server-side by a Cloud Function /
    // admin script in production. The client mirrors `roles` for UI.
  }

  /// One unclaimed record + a pending activation token (QR demo).
  Future<void> _seedPendingActivation() async {
    const docId = 'student_jordan';
    await _db.collection('users').doc(docId).set({
      'name': 'Jordan Lee',
      'first': 'Jordan',
      'idNumber': '202400999',
      'initials': 'JL',
      'roles': ['student'],
      'dept': 'Computer Science',
      'program': 'Undergraduate',
      'enrolledCourseIds': ['MATH401', 'ART150'],
      'teachingCourseIds': <String>[],
      'rsvps': <String>[],
      'status': 'unclaimed',
      'authUid': null,
    });
    await _db.collection('signupTokens').doc('DEMO-ACTIVATE-001').set({
      'targetUserDocId': docId,
      'idNumber': '202400999',
      'used': false,
      'createdByUid': 'seed',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
  }
}
