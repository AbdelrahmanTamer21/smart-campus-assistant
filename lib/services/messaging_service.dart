import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import '../models/user_profile.dart';

/// Top-level background handler (required by FCM to be a static/top-level fn).
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final title = message.notification?.title ?? message.data['title'];
  final body = message.notification?.body ?? message.data['body'];
  if (title == null && body == null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  const channel = AndroidNotificationChannel(
    'campus_default',
    'Campus alerts',
    description: 'Schedule changes, deadlines and announcements',
    importance: Importance.high,
  );
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await plugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: message.data['route'],
  );
}

/// FCM: permission, token, per-topic subscribe, and foreground display via a
/// local notification banner. Tap → deep-link route exposed via [onTapRoute].
class MessagingService {
  final FirebaseMessaging _fm;
  final FirebaseFirestore _db;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  MessagingService({FirebaseMessaging? fm, FirebaseFirestore? db})
      : _fm = fm ?? FirebaseMessaging.instance,
        _db = db ?? FirebaseFirestore.instance;

  static const _channel = AndroidNotificationChannel(
    'campus_default',
    'Campus alerts',
    description: 'Schedule changes, deadlines and announcements',
    importance: Importance.high,
  );

  List<String> _topics = const [];
  String? _recordId;
  bool _inited = false;
  bool _tokenRetryScheduled = false;
  final _recentKeys = <String>{};

  /// Called once at startup. [onTapRoute] receives a deep-link route when a
  /// notification is tapped (foreground tap or app-open from a push).
  Future<void> init(void Function(String route)? onTapRoute) async {
    if (_inited) return;
    _inited = true;
    try {
      await _fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _fm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (resp) {
          final route = resp.payload;
          if (route != null && route.isNotEmpty) onTapRoute?.call(route);
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      FirebaseMessaging.onMessage.listen((m) => _handleRemote(m));

      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        final route = m.data['route'] as String?;
        if (route != null && route.isNotEmpty) onTapRoute?.call(route);
      });

      final initial = await _fm.getInitialMessage();
      final route = initial?.data['route'] as String?;
      if (route != null && route.isNotEmpty) onTapRoute?.call(route);

      _fm.onTokenRefresh.listen(_persistToken);
    } catch (e) {
      debugPrint('Messaging init unavailable: $e');
    }
  }

  void _handleRemote(RemoteMessage m) {
    final title = m.notification?.title ?? m.data['title'] as String?;
    final body = m.notification?.body ?? m.data['body'] as String?;
    if (title == null && body == null) return;
    showBanner(title ?? 'Campus Assistant', body ?? '', route: m.data['route'] as String?);
  }

  /// Show an OS notification banner (foreground / in-app fan-out fallback).
  Future<void> showBanner(String title, String body, {String? route}) async {
    if (!_inited) return;
    final key = '$title|$body';
    if (_recentKeys.contains(key)) return;
    _recentKeys.add(key);
    Future.delayed(const Duration(seconds: 8), () => _recentKeys.remove(key));

    try {
      await _local.show(
        key.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: route,
      );
    } catch (e) {
      debugPrint('Local notification failed: $e');
    }
  }

  /// Topics the [profile] should receive: their courses + role audiences.
  List<String> topicsFor(UserProfile p) {
    final t = <String>{'campus_wide'};
    for (final c in {...p.enrolledCourseIds, ...p.teachingCourseIds}) {
      t.add('course_$c');
    }
    if (p.roles.any((r) => r.name == 'student')) t.add('all_students');
    if (p.roles.any((r) => r.name == 'staff')) t.add('faculty');
    return t.toList();
  }

  Future<void> start(UserProfile profile) async {
    _recordId = profile.docId;
    await _refreshToken();
    await _syncTopics(profile);
  }

  /// FCM token fetch — optional on iOS without APNS (free Apple ID / no push cert).
  /// In-app inbox + local banners still work via Firestore.
  Future<String?> _tryGetToken() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 5; i++) {
          final apns = await _fm.getAPNSToken();
          if (apns != null) break;
          await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
        }
      }
      return await _fm.getToken();
    } on FirebaseException catch (e) {
      if (e.code == 'apns-token-not-set') return null;
      debugPrint('FCM getToken failed: ${e.code}');
      return null;
    } catch (e) {
      if (e.toString().contains('apns-token-not-set')) return null;
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }

  Future<void> _refreshToken() async {
    final token = await _tryGetToken();
    if (token != null) {
      await _persistToken(token);
      debugPrint('FCM token registered');
      return;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
          'Remote push unavailable (no APNS token). In-app notifications still work.');
      _scheduleTokenRetry();
    }
  }

  void _scheduleTokenRetry() {
    if (_tokenRetryScheduled || _recordId == null) return;
    _tokenRetryScheduled = true;
    Future<void>.delayed(const Duration(seconds: 8), () async {
      _tokenRetryScheduled = false;
      if (_recordId == null) return;
      final token = await _tryGetToken();
      if (token != null) await _persistToken(token);
    });
  }

  Future<void> _syncTopics(UserProfile profile) async {
    try {
      final next = topicsFor(profile);
      for (final t in next) {
        if (!_topics.contains(t)) await _fm.subscribeToTopic(t);
      }
      for (final t in _topics) {
        if (!next.contains(t)) await _fm.unsubscribeFromTopic(t);
      }
      _topics = next;
      debugPrint('FCM topics: $_topics');
    } catch (e) {
      debugPrint('FCM topic subscribe skipped: $e');
    }
  }

  Future<void> _persistToken(String token) async {
    final id = _recordId;
    if (id == null) return;
    try {
      await _db.collection('users').doc(id).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      for (final t in _topics) {
        await _fm.unsubscribeFromTopic(t);
      }
      _topics = const [];
      _recordId = null;
    } catch (_) {}
  }
}
