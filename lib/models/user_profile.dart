import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// A pre-existing institutional record (registrar/SIS import). The doc exists
/// before any account; QR activation binds an [authUid] to it.
class UserProfile {
  final String docId;
  final String name;
  final String first;
  final String idNumber;
  final String initials;
  final List<UserRole> roles;
  final String dept;
  final String program;
  final String? year;
  final List<String> enrolledCourseIds;
  final List<String> teachingCourseIds;
  final List<String> rsvps;
  final AccountStatus status;
  final String? authUid;
  final String? photoBase64;

  const UserProfile({
    required this.docId,
    required this.name,
    required this.first,
    required this.idNumber,
    required this.initials,
    required this.roles,
    this.dept = '',
    this.program = '',
    this.year,
    this.enrolledCourseIds = const [],
    this.teachingCourseIds = const [],
    this.rsvps = const [],
    this.status = AccountStatus.unclaimed,
    this.authUid,
    this.photoBase64,
  });

  bool get hasMultipleRoles => roles.length > 1;
  UserRole get primaryRole => roles.isEmpty ? UserRole.student : roles.first;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfile(
      docId: doc.id,
      name: d['name'] ?? '',
      first: d['first'] ?? (d['name'] ?? '').toString().split(' ').first,
      idNumber: d['idNumber'] ?? '',
      initials: d['initials'] ?? '',
      roles: (d['roles'] as List?)?.map((e) => UserRoleX.fromId(e)).toList() ??
          [UserRole.student],
      dept: d['dept'] ?? '',
      program: d['program'] ?? '',
      year: d['year'],
      enrolledCourseIds: List<String>.from(d['enrolledCourseIds'] ?? const []),
      teachingCourseIds: List<String>.from(d['teachingCourseIds'] ?? const []),
      rsvps: List<String>.from(d['rsvps'] ?? const []),
      status: AccountStatusX.fromId(d['status']),
      authUid: d['authUid'],
      photoBase64: d['photoBase64'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'first': first,
        'idNumber': idNumber,
        'initials': initials,
        'roles': roles.map((r) => r.id).toList(),
        'dept': dept,
        'program': program,
        'year': year,
        'enrolledCourseIds': enrolledCourseIds,
        'teachingCourseIds': teachingCourseIds,
        'rsvps': rsvps,
        'status': status.id,
        'authUid': authUid,
        'photoBase64': photoBase64,
      };
}
