import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'role_nav.dart';

/// Persistent shell: bottom nav stays mounted; only [navigationShell] swaps.
class AppTabShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppTabShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: RoleNav(navigationShell: navigationShell),
    );
  }
}
