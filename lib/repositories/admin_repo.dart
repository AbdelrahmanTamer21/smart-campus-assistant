import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_stats.dart';
import '../models/user_profile.dart';
import '../models/enums.dart';

class AdminRepo {
  final FirebaseFirestore _db;
  AdminRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<AdminStats?> watchStats() => _db
      .collection('adminStats')
      .doc('overview')
      .snapshots()
      .map((d) => d.exists ? AdminStats.fromDoc(d) : null);

  /// Unclaimed institutional records — candidates for QR activation.
  Stream<List<UserProfile>> watchUnclaimed() => _db
      .collection('users')
      .where('status', isEqualTo: AccountStatus.unclaimed.id)
      .snapshots()
      .map((s) => s.docs.map(UserProfile.fromDoc).toList());

  /// Every institutional record — unclaimed first, then alphabetical.
  Stream<List<UserProfile>> watchAllUsers() => _db.collection('users').snapshots().map((s) {
        final list = s.docs.map(UserProfile.fromDoc).toList();
        list.sort((a, b) {
          if (a.status != b.status) {
            return a.status == AccountStatus.unclaimed ? -1 : 1;
          }
          return a.name.compareTo(b.name);
        });
        return list;
      });

  /// Active faculty records for course assignment dropdowns.
  Future<List<UserProfile>> fetchFaculty() async {
    final snap = await _db
        .collection('users')
        .where('roles', arrayContains: UserRole.staff.id)
        .get();
    final list = snap.docs.map(UserProfile.fromDoc).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}
