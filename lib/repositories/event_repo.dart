import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/campus_event.dart';

class EventRepo {
  final FirebaseFirestore _db;
  EventRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<CampusEvent>> watchEvents() => _db
      .collection('events')
      .snapshots()
      .map((s) => s.docs.map(CampusEvent.fromDoc).toList());

  /// Toggle RSVP on the user's own record (array union/remove).
  Future<void> toggleRsvp(String userDocId, String eventId, bool join) {
    return _db.collection('users').doc(userDocId).update({
      'rsvps': join
          ? FieldValue.arrayUnion([eventId])
          : FieldValue.arrayRemove([eventId]),
    });
  }
}
