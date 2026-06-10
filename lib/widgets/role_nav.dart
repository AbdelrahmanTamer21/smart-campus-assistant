import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../routing/routes.dart';
import '../routing/tab_branches.dart';
import 'bottom_nav.dart';

/// Role-aware bottom navigation. When [navigationShell] is set (tab shell),
/// switches tabs in-place without rebuilding the nav bar.
class RoleNav extends StatelessWidget {
  final StatefulNavigationShell? navigationShell;
  /// Legacy: highlight tab when this screen is shown outside the shell.
  final String? current;

  const RoleNav({super.key, this.navigationShell, this.current});

  static const _student = [
    NavItem('Home', Icons.home_rounded, Routes.studentHome),
    NavItem('Schedule', Icons.calendar_today_rounded, Routes.schedule),
    NavItem('Map', Icons.place_outlined, Routes.map),
    NavItem('Events', Icons.confirmation_number_outlined, Routes.events),
    NavItem('AI', Icons.auto_awesome, Routes.ai),
  ];
  static const _staff = [
    NavItem('Home', Icons.home_rounded, Routes.staffHome),
    NavItem('Schedule', Icons.calendar_today_rounded, Routes.schedule),
    NavItem('Events', Icons.confirmation_number_outlined, Routes.events),
    NavItem('Map', Icons.place_outlined, Routes.map),
  ];
  static const _admin = [
    NavItem('Home', Icons.home_rounded, Routes.adminHome),
    NavItem('Users', Icons.group_outlined, Routes.userManagement),
    NavItem('Posts', Icons.campaign_outlined, Routes.announcements),
    NavItem('Courses', Icons.menu_book_outlined, Routes.courses),
    NavItem('Profile', Icons.person_outline_rounded, Routes.profile),
  ];

  static const _tabOf = {Routes.course: Routes.schedule};

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().activeRole;
    final items = switch (role) {
      UserRole.staff => _staff,
      UserRole.admin => _admin,
      _ => _student,
    };

    final int index;
    if (navigationShell != null) {
      index = TabBranches.visualTabIndex(role, navigationShell!.currentIndex);
    } else {
      final active = _tabOf[current ?? ''] ?? current ?? '';
      var i = items.indexWhere((item) => item.route == active);
      if (i < 0) i = 0;
      index = i;
    }

    return BottomNav(
      items: items,
      active: index,
      onChanged: (i) {
        if (navigationShell != null) {
          final branch = TabBranches.branchForVisualTab(role, i);
          navigationShell!.goBranch(
            branch,
            initialLocation: branch == navigationShell!.currentIndex,
          );
        } else {
          context.go(items[i].route);
        }
      },
      fab: role == UserRole.staff,
      onFab: role == UserRole.staff ? () => context.push(Routes.compose) : null,
    );
  }
}
