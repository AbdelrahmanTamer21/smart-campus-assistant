// Shared enums for roles, class status, assignment types, and audiences.

enum UserRole { student, staff, admin }

extension UserRoleX on UserRole {
  String get id => name;
  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.staff => 'Faculty / Staff',
        UserRole.admin => 'Administrator',
      };
  static UserRole fromId(String? s) =>
      UserRole.values.firstWhere((r) => r.name == s, orElse: () => UserRole.student);
}

enum ClassStatus { confirmed, cancelled, roomchanged }

extension ClassStatusX on ClassStatus {
  String get id => name;
  static ClassStatus fromId(String? s) => ClassStatus.values
      .firstWhere((v) => v.name == s, orElse: () => ClassStatus.confirmed);
}

enum AssignmentType { exam, assignment, problemset, project }

extension AssignmentTypeX on AssignmentType {
  String get id => name;
  String get label => switch (this) {
        AssignmentType.exam => 'Exam',
        AssignmentType.assignment => 'Assignment',
        AssignmentType.problemset => 'Problem Set',
        AssignmentType.project => 'Project',
      };
  static AssignmentType fromId(String? s) => AssignmentType.values
      .firstWhere((v) => v.name == s, orElse: () => AssignmentType.assignment);
}

enum AccountStatus { unclaimed, active }

extension AccountStatusX on AccountStatus {
  String get id => name;
  static AccountStatus fromId(String? s) => AccountStatus.values
      .firstWhere((v) => v.name == s, orElse: () => AccountStatus.unclaimed);
}
