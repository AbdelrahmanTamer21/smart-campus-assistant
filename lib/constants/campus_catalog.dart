/// Canonical campus values for dropdowns — keeps linked data consistent.
class CampusCatalog {
  CampusCatalog._();

  static const departments = [
    'Department of Mathematics',
    'Department of Computer Science',
    'Department of Fine Arts',
    'Department of Physics',
    'Administration',
  ];

  static const rooms = [
    'Room 101',
    'Room 112',
    'Room 202',
    'Room 204',
    'Lab 2',
    'Lab 3',
    'Auditorium A',
    'Grand Hall',
  ];

  static List<String> get timeSlots {
    final slots = <String>[];
    for (var h = 8; h <= 20; h++) {
      for (final m in [0, 30]) {
        if (h == 20 && m > 0) break;
        slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  /// Ensures [value] appears in [options] (for legacy/custom entries).
  static List<String> withValue(List<String> options, String? value) {
    if (value == null || value.trim().isEmpty) return options;
    if (options.contains(value)) return options;
    return [...options, value];
  }
}
