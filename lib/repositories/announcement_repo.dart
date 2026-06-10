import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementRepo {
  final FirebaseFirestore _db;
  AnnouncementRepo({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Announcement>> watchAnnouncements() => _db
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Announcement.fromDoc).toList());

  /// Staff/admin publish. Producer for F10 (the trigger fans out to topics).
  Future<void> publish(Announcement a) =>
      _db.collection('announcements').add(a.toMap());
}
