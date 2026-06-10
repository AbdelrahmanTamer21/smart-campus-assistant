import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationRepo {
  final FirebaseFirestore _db;
  NotificationRepo({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // Notifications live under the institutional record doc (id = [recordId]).
  CollectionReference<Map<String, dynamic>> _col(String recordId) =>
      _db.collection('users').doc(recordId).collection('notifications');

  Stream<List<AppNotification>> watch(String recordId) => _col(recordId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  Future<void> markRead(String recordId, String id) =>
      _col(recordId).doc(id).update({'read': true});

  Future<void> markAllRead(String recordId) async {
    final unread = await _col(recordId).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  // ── Client-side fan-out (free; replaces the Cloud Functions trigger) ──

  Map<String, dynamic> _payload(
          String title, String body, String type, String? route) =>
      {
        'title': title,
        'body': body,
        'type': type,
        'route': route,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Notify every student enrolled in [courseId].
  Future<void> fanOutToCourse(
    String courseId, {
    required String title,
    required String body,
    required String type,
    String? route,
  }) async {
    final students = await _db
        .collection('users')
        .where('enrolledCourseIds', arrayContains: courseId)
        .get();
    final batch = _db.batch();
    for (final s in students.docs) {
      batch.set(s.reference.collection('notifications').doc(),
          _payload(title, body, type, route));
    }
    await batch.commit();
  }

  Future<void> _fanOutToRecordIds(
    Iterable<String> recordIds, {
    required String title,
    required String body,
    String type = 'announcement',
    String? route = '/announcements',
  }) async {
    final ids = recordIds.toSet();
    if (ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      batch.set(
        _col(id).doc(),
        _payload(title, body, type, route),
      );
    }
    await batch.commit();
  }

  /// Notify every active user (students, staff, admins).
  Future<void> fanOutToCampusWide({
    required String title,
    required String body,
    String type = 'announcement',
    String? route = '/announcements',
  }) async {
    final users =
        await _db.collection('users').where('status', isEqualTo: 'active').get();
    await _fanOutToRecordIds(
      users.docs.map((d) => d.id),
      title: title,
      body: body,
      type: type,
      route: route,
    );
  }

  /// Notify selected faculty/staff records by institutional doc id.
  Future<void> fanOutToFaculty(
    List<String> facultyDocIds, {
    required String title,
    required String body,
    String type = 'announcement',
    String? route = '/announcements',
  }) async {
    await _fanOutToRecordIds(
      facultyDocIds,
      title: title,
      body: body,
      type: type,
      route: route,
    );
  }

  /// Notify all active students (broad announcement audiences).
  Future<void> fanOutToAllStudents({
    required String title,
    required String body,
    String type = 'announcement',
    String? route = '/announcements',
  }) async {
    final students = await _db
        .collection('users')
        .where('roles', arrayContains: 'student')
        .where('status', isEqualTo: 'active')
        .get();
    final batch = _db.batch();
    for (final s in students.docs) {
      batch.set(s.reference.collection('notifications').doc(),
          _payload(title, body, type, route));
    }
    await batch.commit();
  }
}
