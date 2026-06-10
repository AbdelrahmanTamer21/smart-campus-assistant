import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repo.dart';

typedef NotificationAlertHandler = void Function(
  String title,
  String body,
  String? route,
);

/// Streams the signed-in user's notifications → drives the bell badge + inbox.
class NotificationsProvider extends ChangeNotifier {
  final NotificationRepo _repo;
  StreamSubscription? _sub;
  String? _uid;
  bool _ready = false;

  /// Fired when a new unread notification arrives (in-app fan-out / Firestore).
  NotificationAlertHandler? onAlert;

  List<AppNotification> _items = const [];
  bool _loading = true;

  NotificationsProvider(this._repo);

  List<AppNotification> get items => _items;
  bool get loading => _loading;
  int get unread => _items.where((n) => !n.read).length;

  /// Called by the proxy provider when the auth uid changes.
  void bind(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _ready = false;
    _sub?.cancel();
    if (uid == null) {
      _items = const [];
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _sub = _repo.watch(uid).listen((list) {
      if (_ready) {
        final known = _items.map((e) => e.id).toSet();
        for (final n in list) {
          if (!known.contains(n.id) && !n.read) {
            onAlert?.call(n.title, n.body, n.route);
            break;
          }
        }
      }
      _items = list;
      _loading = false;
      _ready = true;
      notifyListeners();
    }, onError: (_) {
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> markRead(String id) async {
    if (_uid != null) await _repo.markRead(_uid!, id);
  }

  Future<void> markAllRead() async {
    if (_uid != null) await _repo.markAllRead(_uid!);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
