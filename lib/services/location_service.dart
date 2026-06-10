import 'package:geolocator/geolocator.dart';

/// Thin wrapper over geolocator with graceful permission/​unsupported fallback.
class LocationService {
  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      return p == LocationPermission.always ||
          p == LocationPermission.whileInUse;
    } catch (_) {
      return false; // unsupported platform / no plugin
    }
  }

  Future<Position?> current() async {
    try {
      if (!await ensurePermission()) return null;
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }
}
