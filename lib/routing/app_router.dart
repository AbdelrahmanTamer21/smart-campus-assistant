import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../screens/ai/ai_assistant_screen.dart';
import '../screens/ai/announcements_screen.dart';
import '../screens/ai/notifications_inbox.dart';
import '../screens/auth/complete_signup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/scan_qr_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/discovery/campus_map_screen.dart';
import '../screens/discovery/events_screen.dart';
import '../screens/staffadmin/courses_management_screen.dart';
import '../screens/staffadmin/admin_home.dart';
import '../screens/staffadmin/compose_screen.dart';
import '../screens/staffadmin/profile_screen.dart';
import '../screens/staffadmin/staff_home.dart';
import '../screens/staffadmin/user_management_screen.dart';
import '../screens/student/course_details_screen.dart';
import '../screens/student/schedule_screen.dart';
import '../screens/student/student_home.dart';
import '../widgets/app_tab_shell.dart';
import 'routes.dart';
import 'tab_branches.dart';

/// go_router with auth + role gating. Role is authoritative from the JWT claim
/// (see AuthProvider) — there is no user-facing role picker.
GoRouter buildRouter(AuthProvider auth) {
  String homeFor(UserRole r) => TabBranches.homeRoute(r);

  GoRoute tab(String path, Widget child) => GoRoute(
        path: path,
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: child,
        ),
      );

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;
      final loc = state.matchedLocation;
      final inAuthFlow = loc == Routes.login ||
          loc == Routes.scanQr ||
          loc == Routes.completeSignup ||
          loc == Routes.splash;

      if (status == AuthStatus.splash) {
        return loc == Routes.splash ? null : Routes.splash;
      }
      if (status == AuthStatus.unauthenticated) {
        if (loc == Routes.scanQr || loc == Routes.completeSignup) return null;
        return loc == Routes.login ? null : Routes.login;
      }
      // authenticated
      if (inAuthFlow) return homeFor(auth.activeRole);
      if (auth.activeRole == UserRole.admin && loc == Routes.ai) {
        return Routes.adminHome;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.scanQr, builder: (_, _) => const ScanQrScreen()),
      GoRoute(
        path: Routes.completeSignup,
        builder: (_, state) {
          final e = (state.extra as Map?) ?? const {};
          return CompleteSignupScreen(
            token: e['token'] ?? '',
            name: e['name'] ?? '',
            idNumber: e['idNumber'] ?? '',
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            AppTabShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [tab(Routes.studentHome, const StudentHome())]),
          StatefulShellBranch(routes: [tab(Routes.staffHome, const StaffHome())]),
          StatefulShellBranch(routes: [tab(Routes.adminHome, const AdminHome())]),
          StatefulShellBranch(routes: [tab(Routes.schedule, const ScheduleScreen())]),
          StatefulShellBranch(routes: [tab(Routes.map, const CampusMapScreen())]),
          StatefulShellBranch(routes: [tab(Routes.events, const EventsScreen())]),
          StatefulShellBranch(routes: [tab(Routes.ai, const AiAssistantScreen())]),
          StatefulShellBranch(
              routes: [tab(Routes.userManagement, const UserManagementScreen())]),
          StatefulShellBranch(
              routes: [tab(Routes.announcements, const AnnouncementsScreen())]),
          StatefulShellBranch(routes: [tab(Routes.profile, const ProfileScreen())]),
          StatefulShellBranch(
              routes: [tab(Routes.courses, const CoursesManagementScreen())]),
        ],
      ),
      GoRoute(
        path: '${Routes.course}/:id',
        builder: (_, state) =>
            CourseDetailsScreen(courseId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: Routes.notifications,
          builder: (_, _) => const NotificationsInbox()),
      GoRoute(path: Routes.compose, builder: (_, _) => const ComposeScreen()),
    ],
  );
}
