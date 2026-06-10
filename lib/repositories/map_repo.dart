import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/map_models.dart';

class MapRepo {
  final FirebaseFirestore _db;
  MapRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<MapPin>> watchPins() => _db
      .collection('mapPins')
      .snapshots()
      .map((s) => s.docs.map(MapPin.fromDoc).toList());

  Future<Building?> getBuilding(String id) async {
    final d = await _db.collection('buildings').doc(id).get();
    return d.exists ? Building.fromMap(d.data()!) : null;
  }
}
