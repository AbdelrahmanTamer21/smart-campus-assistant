import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/campus_event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../repositories/event_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

const _cats = ['All', 'Academic', 'Career', 'Sports', 'Social'];

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EventRepo>();
    final auth = context.watch<AuthProvider>();
    return ScreenScaffold(
      header: SCAppBar(
        leading: Avatar(
            initials: auth.profile?.initials ?? 'U',
            size: 40,
            onTap: () => context.push(Routes.profile)),
        trailing: CircleIconButton(
            icon: Icons.notifications_outlined,
            onTap: () => context.push(Routes.notifications)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campus Events', style: AppText.headlineLg),
            const SizedBox(height: 4),
            Text("Discover what's happening this week",
                style: AppText.bodyLg.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 18),
            FilterChipBar(
              items: _cats,
              active: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 18),
            StreamBuilder<List<CampusEvent>>(
              stream: repo.watchEvents(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                final cat = _cats[_filter];
                final list = (snap.data ?? const [])
                    .where((e) => cat == 'All' || e.cat == cat)
                    .toList();
                if (list.isEmpty) {
                  return EmptyState(
                      icon: Icons.confirmation_number_outlined,
                      title: 'No events here yet',
                      sub: 'Nothing under $cat right now. Check back soon.');
                }
                return Column(
                  children: [
                    for (final e in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _EventCard(event: e, repo: repo),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CampusEvent event;
  final EventRepo repo;
  const _EventCard({required this.event, required this.repo});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final offline = context.watch<ConnectivityProvider>().offline;
    final joined = auth.profile?.rsvps.contains(event.id) ?? false;
    final docId = auth.profile?.docId;

    return AppCard(
      pad: 12,
      accent: event.featured ? AppColors.accentNeutral : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventCover(tint: Color(event.tint), cat: event.cat, featured: event.featured),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tag(text: event.cat),
                    const SizedBox(width: 8),
                    if (joined)
                      StatusChip(
                        variant: offline ? ChipVariant.pending : ChipVariant.confirmed,
                        label: offline ? 'Pending sync' : 'Going',
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(event.title,
                    style: AppText.headlineSm.copyWith(fontSize: 18)),
                const SizedBox(height: 10),
                MetaRow(icon: Icons.schedule, text: event.date),
                const SizedBox(height: 6),
                MetaRow(icon: Icons.place_outlined, text: event.loc),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: joined
                          ? OutlineButton(
                              label: 'Going',
                              icon: Icons.check,
                              height: 46,
                              onPressed: docId == null
                                  ? null
                                  : () => _toggle(context, docId, false, offline),
                            )
                          : PrimaryButton(
                              label: event.featured ? 'Join Event' : 'Save Spot',
                              height: 46,
                              onPressed: docId == null
                                  ? null
                                  : () => _toggle(context, docId, true, offline),
                            ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event link copied to clipboard.'))),
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.ios_share, size: 19, color: AppColors.primaryNavy),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(BuildContext context, String docId, bool join, bool offline) async {
    await repo.toggleRsvp(docId, event.id, join);
    if (context.mounted && join) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(offline
            ? 'Spot saved — will sync when online.'
            : "You're going! Reminder set."),
      ));
    }
  }
}

class _EventCover extends StatelessWidget {
  final Color tint;
  final String cat;
  final bool featured;
  const _EventCover({required this.tint, required this.cat, required this.featured});
  @override
  Widget build(BuildContext context) {
    final icon = switch (cat) {
      'Career' => Icons.work_outline,
      'Academic' => Icons.school_outlined,
      'Sports' => Icons.sports_basketball_outlined,
      'Social' => Icons.groups_outlined,
      _ => Icons.confirmation_number_outlined,
    };
    return Container(
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint, tint.withValues(alpha: 0.7)],
        ),
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, size: 44, color: Colors.white.withValues(alpha: 0.9))),
          if (featured)
            const Positioned(
              top: 10,
              left: 10,
              child: StatusChip(variant: ChipVariant.featured, icon: Icons.star),
            ),
        ],
      ),
    );
  }
}
