import '../models/enums.dart';
import 'routes.dart';

/// Indexed-stack branch order for [StatefulShellRoute] (one branch per tab route).
class TabBranches {
  TabBranches._();

  static const studentHome = 0;
  static const staffHome = 1;
  static const adminHome = 2;
  static const schedule = 3;
  static const map = 4;
  static const events = 5;
  static const ai = 6;
  static const userManagement = 7;
  static const announcements = 8;
  static const profile = 9;
  static const courses = 10;

  static int homeBranch(UserRole role) => switch (role) {
        UserRole.admin => adminHome,
        UserRole.staff => staffHome,
        _ => studentHome,
      };

  static String homeRoute(UserRole role) => switch (role) {
        UserRole.admin => Routes.adminHome,
        UserRole.staff => Routes.staffHome,
        _ => Routes.studentHome,
      };

  static int branchForRoute(UserRole role, String route) {
    final tabRoute = route.startsWith(Routes.course) ? Routes.schedule : route;
    return switch (role) {
      UserRole.admin => switch (tabRoute) {
          Routes.adminHome => adminHome,
          Routes.userManagement => userManagement,
          Routes.announcements => announcements,
          Routes.courses => courses,
          Routes.profile => profile,
          _ => adminHome,
        },
      UserRole.staff => switch (tabRoute) {
          Routes.staffHome => staffHome,
          Routes.schedule => schedule,
          Routes.events => events,
          Routes.map => map,
          Routes.profile => profile,
          _ => staffHome,
        },
      _ => switch (tabRoute) {
          Routes.studentHome => studentHome,
          Routes.schedule => schedule,
          Routes.map => map,
          Routes.events => events,
          Routes.ai => ai,
          _ => studentHome,
        },
    };
  }

  /// Maps a shell branch index to the highlighted bottom-nav tab (0–4).
  static int visualTabIndex(UserRole role, int branch) => switch (role) {
        UserRole.admin => switch (branch) {
            adminHome => 0,
            userManagement => 1,
            announcements => 2,
            courses => 3,
            profile => 4,
            _ => 0,
          },
        UserRole.staff => switch (branch) {
            staffHome => 0,
            schedule => 1,
            events => 2,
            map => 3,
            _ => 0,
          },
        _ => switch (branch) {
            studentHome => 0,
            schedule => 1,
            map => 2,
            events => 3,
            ai => 4,
            _ => 0,
          },
      };

  static int branchForVisualTab(UserRole role, int tab) => switch (role) {
        UserRole.admin =>
          [adminHome, userManagement, announcements, courses, profile][tab],
        UserRole.staff => [staffHome, schedule, events, map][tab],
        _ => [studentHome, schedule, map, events, ai][tab],
      };
}
