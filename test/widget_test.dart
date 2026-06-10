// Basic unit tests for model logic (no Firebase needed).
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project/models/assignment.dart';
import 'package:mobile_project/models/enums.dart';

void main() {
  test('Assignment.dueLabel reflects urgency', () {
    final tomorrow = Assignment(
      id: 'a',
      courseId: 'c',
      code: 'X-1',
      title: 'Lab',
      type: AssignmentType.assignment,
      dueAt: DateTime.now().add(const Duration(days: 1)),
    );
    expect(tomorrow.dueLabel, 'Due Tomorrow');
    expect(tomorrow.isUrgent, isTrue);
  });

  test('UserRole maps from id', () {
    expect(UserRoleX.fromId('admin'), UserRole.admin);
    expect(UserRoleX.fromId('nonsense'), UserRole.student);
  });
}
