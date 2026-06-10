import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_config.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/notifications_provider.dart';
import 'repositories/admin_repo.dart';
import 'repositories/announcement_repo.dart';
import 'repositories/chat_repo.dart';
import 'repositories/course_repo.dart';
import 'repositories/event_repo.dart';
import 'repositories/map_repo.dart';
import 'repositories/notification_repo.dart';
import 'routing/app_router.dart';
import 'services/messaging_service.dart';
import 'services/seed_service.dart';
import 'theme/app_theme.dart';

const _seed = bool.fromEnvironment('SEED');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Local Firebase Emulator Suite (Auth + Firestore + Functions) for dev.
  if (AppConfig.useEmulator) {
    final host = AppConfig.emulatorHost;
    debugPrint('Firebase emulators → $host (auth:9099 firestore:8080 functions:5001)');
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  } else {
    // Offline-first: cache-first reads + queued offline writes.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // FCM background/terminated handler (must be registered before runApp).
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

  if (_seed) {
    try {
      await SeedService().run();
    } catch (e, st) {
      debugPrint('Seed failed (is the emulator running at ${AppConfig.emulatorHost}?): $e\n$st');
    }
  }

  runApp(const CampusApp());
}

class CampusApp extends StatefulWidget {
  const CampusApp({super.key});
  @override
  State<CampusApp> createState() => _CampusAppState();
}

class _CampusAppState extends State<CampusApp> {
  late final AuthProvider _auth = AuthProvider();
  late final _router = buildRouter(_auth);
  final _messaging = MessagingService();
  String? _messagingFor;

  @override
  void initState() {
    super.initState();
    _messaging.init((route) => _router.go(route));
    _auth.addListener(_syncMessaging);
  }

  /// Subscribe FCM topics when a user signs in; unsubscribe on sign-out.
  void _syncMessaging() {
    final p = _auth.profile;
    if (p != null && p.docId != _messagingFor) {
      _messagingFor = p.docId;
      _messaging.start(p);
    } else if (p == null && _messagingFor != null) {
      _messagingFor = null;
      _messaging.stop();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_syncMessaging);
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityProvider>(create: (_) => ConnectivityProvider()),
        // Repositories + services
        Provider<CourseRepo>(create: (_) => CourseRepo()),
        Provider<EventRepo>(create: (_) => EventRepo()),
        Provider<AnnouncementRepo>(create: (_) => AnnouncementRepo()),
        Provider<MapRepo>(create: (_) => MapRepo()),
        Provider<AdminRepo>(create: (_) => AdminRepo()),
        Provider<NotificationRepo>(create: (_) => NotificationRepo()),
        Provider<ChatRepo>(create: (_) => ChatRepo()),
        // Auth (role from JWT claim)
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        // Bind notifications + chat to the signed-in user.
        ChangeNotifierProxyProvider<AuthProvider, NotificationsProvider>(
          create: (ctx) => NotificationsProvider(ctx.read<NotificationRepo>()),
          update: (_, auth, prov) {
            prov!
              ..onAlert = (title, body, route) {
                _messaging.showBanner(title, body, route: route);
              }
              ..bind(auth.profile?.docId);
            return prov;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (ctx) => ChatProvider(
              ctx.read<ChatRepo>(), ctx.read<CourseRepo>(), ctx.read<AnnouncementRepo>()),
          update: (_, auth, prov) => prov!..bind(auth.profile),
        ),
      ],
      child: MaterialApp.router(
        title: 'Smart Campus Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
