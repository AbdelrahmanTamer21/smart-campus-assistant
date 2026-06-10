import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/map_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../repositories/map_repo.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

const _filters = ['Cafe', 'Printers', 'Study Rooms'];
const _kindOf = {'Cafe': 'cafe', 'Printers': 'printer', 'Study Rooms': 'study'};

const _fallbackPins = [
  MapPin(id: '1', label: 'Science Center', x: 58, y: 38, kind: 'study'),
  MapPin(id: '2', label: 'Library', x: 30, y: 60, kind: 'study'),
  MapPin(id: '3', label: 'Union Café', x: 72, y: 66, kind: 'cafe'),
  MapPin(id: '4', label: 'Print Hub', x: 42, y: 28, kind: 'printer'),
];

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});
  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  int _filter = -1;
  MapPin? _selected;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final offline = context.watch<ConnectivityProvider>().offline;
    final repo = context.read<MapRepo>();

    return ScreenScaffold(
      scrollable: false,
      header: SCAppBar(
        leading: Avatar(
            initials: auth.profile?.initials ?? 'U',
            size: 40,
            onTap: () => context.push(Routes.profile)),
        trailing: CircleIconButton(
            icon: Icons.notifications_outlined,
            onTap: () => context.push(Routes.notifications)),
      ),
      body: StreamBuilder<List<MapPin>>(
        stream: repo.watchPins(),
        builder: (context, snap) {
          final pins = (snap.data == null || snap.data!.isEmpty)
              ? _fallbackPins
              : snap.data!;
          _selected ??= pins.first;
          final visible = _filter == -1
              ? pins
              : pins.where((p) => p.kind == _kindOf[_filters[_filter]]).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: Column(
                  children: [
                    const AppTextField(
                      icon: Icons.search,
                      hint: 'Find a building or room',
                      trailing: Icon(Icons.mic_none, size: 19, color: AppColors.hint),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilterChipBar(
                            items: _filters,
                            active: _filter,
                            onChanged: (i) =>
                                setState(() => _filter = i == _filter ? -1 : i),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.layers_outlined,
                              size: 19, color: AppColors.primaryNavy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Stack(
                      children: [
                        const _MapCanvas(),
                        for (final p in visible) _Pin(
                          pin: p,
                          selected: _selected?.id == p.id,
                          onTap: () => setState(() => _selected = p),
                        ),
                        // My location
                        const Align(
                          alignment: Alignment(-0.08, 0.6),
                          child: _MyLocationDot(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _BuildingSheet(
                name: _selected?.label ?? 'Science Center',
                offline: offline,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.accentAcademic,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
              color: AppColors.accentAcademic.withValues(alpha: 0.25),
              spreadRadius: 6),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final MapPin pin;
  final bool selected;
  final VoidCallback onTap;
  const _Pin({required this.pin, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(pin.x / 50 - 1, pin.y / 50 - 1),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.tag),
                boxShadow: AppShadow.l1,
              ),
              child: Text(pin.label,
                  style: AppText.labelSm.copyWith(
                      color: AppColors.primaryNavy, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Container(
              width: selected ? 34 : 28,
              height: selected ? 34 : 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryNavy : AppColors.card,
                shape: BoxShape.circle,
                boxShadow: AppShadow.l2,
              ),
              child: Icon(
                pin.kind == 'cafe'
                    ? Icons.local_cafe_outlined
                    : pin.kind == 'printer'
                        ? Icons.print_outlined
                        : Icons.science_outlined,
                size: selected ? 17 : 15,
                color: selected ? Colors.white : AppColors.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas();
  @override
  Widget build(BuildContext context) {
    const green = Color(0xFFD8E8DC);
    const water = Color(0xFFCFE0EC);
    final road = Colors.white.withValues(alpha: 0.85);
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      Widget block(double l, double t, double bw, double bh, Color c) => Positioned(
            left: w * l,
            top: h * t,
            width: w * bw,
            height: h * bh,
            child: Container(
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
            ),
          );
      return Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFE8EDF2))),
          block(0.06, 0.08, 0.34, 0.30, green),
          block(0.62, 0.12, 0.30, 0.24, green),
          block(0.10, 0.66, 0.24, 0.24, green),
          block(0.62, 0.66, 0.34, 0.26, water),
          // roads
          Positioned(left: 0, right: 0, top: h * 0.48, height: 14, child: ColoredBox(color: road)),
          Positioned(top: 0, bottom: 0, left: w * 0.46, width: 14, child: ColoredBox(color: road)),
        ],
      );
    });
  }
}

class _BuildingSheet extends StatelessWidget {
  final String name;
  final bool offline;
  const _BuildingSheet({required this.name, required this.offline});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryNavy.withValues(alpha: 0.10),
              offset: const Offset(0, -8),
              blurRadius: 24),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text('Building B · $name',
                    style: AppText.headlineSm.copyWith(fontSize: 18)),
              ),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.fill, shape: BoxShape.circle),
                child: const Icon(Icons.ios_share, size: 17, color: AppColors.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const StatusChip(variant: ChipVariant.open),
              const SizedBox(width: 8),
              Expanded(
                child: Text('3 Labs · 10 Lecture Rooms · Café on Floor 1',
                    style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final x in ['Labs', 'Rooms', 'Café'])
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: x == 'Café' ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.fill, borderRadius: BorderRadius.circular(12)),
                    child: Text(x.toUpperCase(),
                        style: AppText.labelLg.copyWith(
                            fontSize: 12.5, color: AppColors.primaryNavy)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: offline ? 'Navigation Requires Connection' : 'Start Navigation',
            icon: offline ? Icons.wifi_off : Icons.navigation_outlined,
            disabled: offline,
            onPressed: offline
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Starting navigation to $name…'))),
          ),
        ],
      ),
    );
  }
}
