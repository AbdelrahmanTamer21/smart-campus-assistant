import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/connectivity_provider.dart';
import 'feedback.dart';

/// Standard screen shell: optional offline banner → header → scrollable body →
/// optional bottom nav. Body extends under the nav with safe padding.
class ScreenScaffold extends StatelessWidget {
  final Widget? header;
  final Widget body;
  final Widget? bottomNav;
  final Color background;
  final bool scrollable;
  final Future<void> Function()? onRefresh;
  const ScreenScaffold({
    super.key,
    this.header,
    required this.body,
    this.bottomNav,
    this.background = AppColors.background,
    this.scrollable = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<ConnectivityProvider>().offline;
    Widget content = scrollable
        ? (onRefresh != null
            ? RefreshIndicator(
                color: AppColors.primaryNavy,
                onRefresh: onRefresh!,
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), child: body))
            : SingleChildScrollView(child: body))
        : body;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (offline) const OfflineBanner(),
            ?header,
            Expanded(child: content),
          ],
        ),
      ),
      bottomNavigationBar: bottomNav,
    );
  }
}
