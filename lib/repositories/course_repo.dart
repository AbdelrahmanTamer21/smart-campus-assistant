import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/class_occurrence.dart';
import '../models/assignment.dart';
import '../models/enums.dart';
import '../services/data_constraints.dart';

/// Thrown when a write would break catalog or enrollment links.
export '../services/data_constraints.dart' show DataConstraintException, CourseLinkSummary;

/// Reads + staff writes for courses, timetable occurrences, and assignments.
class CourseRepo {
  final FirebaseFirestore _db;
  CourseRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // ── Courses ──
  Stream<List<Course>> watchCourses(List<String> ids) {
    if (ids.isEmpty) return Stream.value(const []);
    // whereIn supports up to 30 ids; fine for a student/staff course list.
    return _db
        .collection('courses')
        .where(FieldPath.documentId, whereIn: ids.take(30).toList())
        .snapshots()
        .map((s) => s.docs.map(Course.fromDoc).toList());
  }

  Stream<Course?> watchCourse(String id) => _db
      .collection('courses')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Course.fromDoc(d) : null);

  /// All courses — admin catalog view.
  Stream<List<Course>> watchAllCourses() => _db.collection('courses').snapshots().map((s) {
        final list = s.docs.map(Course.fromDoc).toList();
        list.sort((a, b) => a.code.compareTo(b.code));
        return list;
      });

  /// Every class occurrence on a given day — admin campus-wide view.
  Stream<List<ClassOccurrence>> watchAllClassesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('classes')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) {
      final list = s.docs.map(ClassOccurrence.fromDoc).toList();
      list.sort((a, b) => a.start.compareTo(b.start));
      return list;
    });
  }

  // ── Timetable occurrences ──
  Stream<List<ClassOccurrence>> watchDay(List<String> courseIds, DateTime day) {
    if (courseIds.isEmpty) return Stream.value(const []);
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('classes')
        .where('courseId', whereIn: courseIds.take(30).toList())
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) {
      final list = s.docs.map(ClassOccurrence.fromDoc).toList();
      list.sort((a, b) => a.start.compareTo(b.start));
      return list;
    });
  }

  /// Staff edit of a single occurrence (room / status). Producer for F10.
  Future<void> editOccurrence(
    String id, {
    String? room,
    ClassStatus? status,
    String? originalRoom,
  }) async {
    final ref = _db.collection('classes').doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      throw const DataConstraintException('Class occurrence no longer exists.');
    }
    final occ = ClassOccurrence.fromDoc(snap);
    final nextRoom = room ?? occ.room;
    final nextStatus = status ?? occ.status;
    DataConstraints.validateOccurrenceEdit(
      occ: occ,
      room: nextRoom,
      status: nextStatus,
    );
    await _assertCourseExists(occ.courseId);
    await ref.update({
      if (room != null) 'room': room.trim(),
      if (status != null) 'status': status.id,
      if (originalRoom != null) 'originalRoom': originalRoom,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Assignments ──
  Stream<List<Assignment>> watchAssignments(List<String> courseIds) {
    if (courseIds.isEmpty) return Stream.value(const []);
    return _db
        .collection('assignments')
        .where('courseId', whereIn: courseIds.take(30).toList())
        .snapshots()
        .map((s) {
      final list = s.docs.map(Assignment.fromDoc).toList();
      list.sort((a, b) => a.dueAt.compareTo(b.dueAt));
      return list;
    });
  }

  Future<void> upsertAssignment(Assignment a) async {
    DataConstraints.validateAssignment(a);
    await _assertCourseExists(a.courseId);
    final col = _db.collection('assignments');
    if (a.id.isEmpty) {
      await col.add(a.toMap());
    } else {
      await col.doc(a.id).set(a.toMap());
    }
  }

  Future<void> deleteAssignment(String id) =>
      _db.collection('assignments').doc(id).delete();

  /// Create or update a course catalog entry (admin).
  Future<void> upsertCourse(Course course) async {
    DataConstraints.validateCourse(course);
    final ref = _db.collection('courses').doc(course.id);
    final existed = (await ref.get()).exists;
    await ref.set(course.toMap(), SetOptions(merge: true));
    if (existed) await _syncCourseReferences(course);
  }

  /// Remove a course from the catalog (admin) when nothing references it.
  Future<void> deleteCourse(String id) async {
    final links = await courseLinkSummary(id);
    DataConstraints.validateCourseDeletion(links);
    await _db.collection('courses').doc(id).delete();
  }

  /// Counts user enrollments, faculty links, deadlines, and class rows.
  Future<bool> courseExists(String id) =>
      _db.collection('courses').doc(id).get().then((d) => d.exists);

  Future<CourseLinkSummary> courseLinkSummary(String courseId) async {
    final users = await _db.collection('users').get();
    var enrolled = 0;
    var teaching = 0;
    for (final doc in users.docs) {
      final enrolledIds = List<String>.from(doc.data()['enrolledCourseIds'] ?? const []);
      final teachingIds = List<String>.from(doc.data()['teachingCourseIds'] ?? const []);
      if (enrolledIds.contains(courseId)) enrolled++;
      if (teachingIds.contains(courseId)) teaching++;
    }
    final assignments = await _db
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .count()
        .get();
    final classes = await _db
        .collection('classes')
        .where('courseId', isEqualTo: courseId)
        .count()
        .get();
    return CourseLinkSummary(
      enrolledUsers: enrolled,
      teachingUsers: teaching,
      assignments: assignments.count ?? 0,
      classes: classes.count ?? 0,
    );
  }

  Future<void> _assertCourseExists(String courseId) async {
    final snap = await _db.collection('courses').doc(courseId).get();
    if (!snap.exists) {
      throw DataConstraintException(
          'Course "$courseId" was not found. Create the course first.');
    }
  }

  Future<void> _syncCourseReferences(Course course) async {
    final batch = _db.batch();
    var pending = 0;
    final assignments = await _db
        .collection('assignments')
        .where('courseId', isEqualTo: course.id)
        .get();
    for (final doc in assignments.docs) {
      batch.update(doc.reference, {'code': course.code});
      pending++;
    }
    final classes = await _db
        .collection('classes')
        .where('courseId', isEqualTo: course.id)
        .get();
    for (final doc in classes.docs) {
      batch.update(doc.reference, {
        'code': course.code,
        'title': course.title,
        'profName': course.profName,
      });
      pending++;
    }
    if (pending > 0) await batch.commit();
  }

  // ── Per-student completion ──
  Stream<Set<String>> watchDoneAssignments(String authUid) => _db
      .collection('users')
      .doc(authUid)
      .collection('assignmentStatus')
      .where('done', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> setAssignmentDone(
      String userDocId, String assignmentId, bool done) {
    return _db
        .collection('users')
        .doc(userDocId)
        .collection('assignmentStatus')
        .doc(assignmentId)
        .set({'done': done, 'doneAt': FieldValue.serverTimestamp()});
  }
}
