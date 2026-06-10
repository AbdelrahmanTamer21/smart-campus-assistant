import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks online/offline. Drives the global offline banner and disables
/// live-only actions (navigation, fresh AI, QR).
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity;
  StreamSubscription? _sub;
  bool _online = true;

  bool get online => _online;
  bool get offline => !_online;

  ConnectivityProvider({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  Future<void> _init() async {
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      _online = true;
    }
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final next = !(results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none));
    if (next != _online) {
      _online = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
