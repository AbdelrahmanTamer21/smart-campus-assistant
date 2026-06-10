import 'package:cloud_firestore/cloud_firestore.dart';

class MapPin {
  final String id;
  final String label;
  final double x; // % position on the stylized canvas
  final double y;
  final String kind; // study / cafe / printer
  const MapPin({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.kind,
  });
  factory MapPin.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MapPin(
      id: doc.id,
      label: d['label'] ?? '',
      x: (d['x'] ?? 50).toDouble(),
      y: (d['y'] ?? 50).toDouble(),
      kind: d['kind'] ?? 'study',
    );
  }
  Map<String, dynamic> toMap() =>
      {'label': label, 'x': x, 'y': y, 'kind': kind};
}

class Building {
  final String name;
  final String facilities;
  final bool open;
  const Building({
    required this.name,
    required this.facilities,
    this.open = true,
  });
  factory Building.fromMap(Map<String, dynamic> d) => Building(
        name: d['name'] ?? '',
        facilities: d['facilities'] ?? '',
        open: d['open'] ?? true,
      );
  Map<String, dynamic> toMap() =>
      {'name': name, 'facilities': facilities, 'open': open};
}
