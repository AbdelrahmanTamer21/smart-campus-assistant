import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/admin_stats.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/admin_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool _week = true;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepo>();
    final profile = context.watch<AuthProvider>().profile;

    return ScreenScaffold(
      header: SCAppBar(
        leading: Avatar(
          initials: profile?.initials ?? 'AD',
          bg: AppColors.accentSocial,
          size: 40,
          onTap: () => context.push(Routes.profile),
        ),
        title: 'Admin',
        subtitle: 'Dashboard',
        trailing: CircleIconButton(
          icon: Icons.notifications_outlined,
          onTap: () => context.push(Routes.notifications),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 24),
        child: StreamBuilder<AdminStats?>(
          stream: repo.watchStats(),
          builder: (context, snap) {
            final stats = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Overview', style: AppText.headlineLg),
                const SizedBox(height: 4),
                Text('Campus-wide health at a glance',
                    style: AppText.bodyLg.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 22),
                if (stats == null)
                  const LoadingState()
                else ...[
                  StatCard(
                      value: stats.stats[0].value,
                      label: stats.stats[0].label,
                      accent: AppColors.accentNeutral),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                            value: stats.stats[1].value,
                            label: stats.stats[1].label,
                            trend: stats.stats[1].trend,
                            accent: AppColors.accentUpcoming),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                            value: stats.stats[2].value,
                            label: stats.stats[2].label,
                            accent: AppColors.accentSocial),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _EngagementCard(
                    week: _week,
                    onToggle: (w) => setState(() => _week = w),
                    bars: _week ? stats.engagementWeek : stats.engagementMonth,
                  ),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Post Campus-Wide Announcement',
                  icon: Icons.campaign_outlined,
                  onPressed: () => context.push(Routes.compose),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EngagementCard extends StatefulWidget {
  final bool week;
  final ValueChanged<bool> onToggle;
  final List<int> bars;
  const _EngagementCard({required this.week, required this.onToggle, required this.bars});

  @override
  State<_EngagementCard> createState() => _EngagementCardState();
}

class _EngagementCardState extends State<_EngagementCard> {
  int? _selected;

  @override
  void didUpdateWidget(covariant _EngagementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week != widget.week || oldWidget.bars != widget.bars) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.week
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : ['W1', 'W2', 'W3', 'W4'];
    final periodLabels = widget.week
        ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        : ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
    return AppCard(
      pad: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notification\nEngagement',
                        style: AppText.headlineSm.copyWith(fontSize: 17, height: 1.25)),
                    const SizedBox(height: 4),
                    Text('Open rate by ${widget.week ? 'day' : 'week'}',
                        style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: AppColors.fill,
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  children: [
                    _seg('Week', widget.week, () => widget.onToggle(true)),
                    _seg('Month', !widget.week, () => widget.onToggle(false)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < widget.bars.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = _selected == i ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 18,
                              child: _selected == i
                                  ? Text(
                                      '${widget.bars[i]}%',
                                      style: AppText.labelLg.copyWith(
                                        fontSize: 11,
                                        color: AppColors.primaryNavy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  : null,
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  widthFactor: _selected == i ? 1 : 0.88,
                                  heightFactor: (widget.bars[i].clamp(0, 100)) / 100,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      color: _selected == i
                                          ? AppColors.primaryNavy
                                          : (i == widget.bars.length - 1
                                              ? AppColors.primaryNavy.withValues(alpha: 0.85)
                                              : AppColors.secondaryCyan),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: _selected == i ? AppShadow.l1 : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              labels[i % labels.length],
                              style: AppText.labelSm.copyWith(
                                color: _selected == i
                                    ? AppColors.primaryNavy
                                    : AppColors.hint,
                                fontWeight:
                                    _selected == i ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 12),
            Text(
              '${periodLabels[_selected! % periodLabels.length]} · ${widget.bars[_selected!]}% open rate',
              style: AppText.bodyMd.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seg(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: on ? AppShadow.l1 : null,
          ),
          child: Text(label,
              style: AppText.labelLg.copyWith(
                  fontSize: 12.5,
                  color: on ? AppColors.primaryNavy : AppColors.hint)),
        ),
      );
}
