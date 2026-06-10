import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/data_constraints.dart';

/// Thrown when a write would break catalog or enrollment links.
export '../services/data_constraints.dart' show DataConstraintException;

/// Admin-side issuance of one-time QR activation tokens that reference an
/// existing `unclaimed` institutional record (no academic data is copied).
class ActivationService {
  final FirebaseFirestore _db;
  ActivationService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Mints a single-use token for [record]; returns the token id to encode as
  /// a QR. The QR payload is the token document id.
  Future<String> issueToken(UserProfile record, String adminUid) async {
    DataConstraints.validateActivationTarget(record);
    final ref = _db.collection('signupTokens').doc();
    await ref.set({
      'targetUserDocId': record.docId,
      'idNumber': record.idNumber,
      'name': record.name,
      'used': false,
      'createdByUid': adminUid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7))),
    });
    return ref.id;
  }
}
