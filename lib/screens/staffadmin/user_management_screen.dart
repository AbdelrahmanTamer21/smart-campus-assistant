import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/enums.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/admin_repo.dart';
import '../../services/activation_service.dart';
import '../../services/data_constraints.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

const _userFilters = ['All', 'Students', 'Faculty', 'Admin', 'Pending'];

/// Admin: list all campus users; unclaimed records get a one-time activation QR.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int _filter = 0;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _avatarBg(UserProfile u) => switch (u.primaryRole) {
        UserRole.admin => AppColors.accentSocial,
        UserRole.staff => AppColors.accentAcademic,
        _ => AppColors.primaryNavy,
      };

  List<UserProfile> _applyFilters(List<UserProfile> list) {
    final q = _search.text.trim().toLowerCase();
    return list.where((u) {
      final roleOk = switch (_filter) {
        1 => u.primaryRole == UserRole.student,
        2 => u.primaryRole == UserRole.staff,
        3 => u.primaryRole == UserRole.admin,
        4 => u.status == AccountStatus.unclaimed,
        _ => true,
      };
      if (!roleOk) return false;
      if (q.isEmpty) return true;
      final hay = '${u.name} ${u.idNumber} ${u.dept} ${u.program}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepo>();
    return ScreenScaffold(
      scrollable: false,
      header: SCAppBar(
        onBack: context.canPop() ? () => context.pop() : null,
        leading: Avatar(
          initials: context.read<AuthProvider>().profile?.initials ?? 'AD',
          size: 40,
          bg: AppColors.accentSocial,
        ),
        title: 'Admin',
        subtitle: 'User Management',
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campus Users', style: AppText.headlineMd),
            const SizedBox(height: 4),
            Text(
              'All students, faculty, and admins. Tap QR on unclaimed accounts '
              'to issue a one-time activation code.',
              style: AppText.bodyMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            AppTextField(
              icon: Icons.search,
              hint: 'Search by name or ID',
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            FilterChipBar(
              items: _userFilters,
              active: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 14),
            const SectionHeader(title: 'All Users', small: true),
            Expanded(
              child: StreamBuilder<List<UserProfile>>(
                stream: repo.watchAllUsers(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const LoadingState();
                  }
                  final all = snap.data ?? const [];
                  if (all.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'No users yet',
                      sub: 'Institutional records will appear here once imported.',
                    );
                  }
                  final list = _applyFilters(all);
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.filter_list_off,
                      title: 'No matches',
                      sub: 'Try a different filter or search term.',
                    );
                  }
                  return ListView(
                    children: [
                      for (final u in list)
                        ListRow(
                          leading: Avatar(initials: u.initials, size: 42, bg: _avatarBg(u)),
                          title: u.name,
                          meta: 'ID ${u.idNumber} · ${u.primaryRole.label}',
                          trailing: u.status == AccountStatus.unclaimed
                              ? TextButton.icon(
                                  onPressed: () => _issue(context, u),
                                  icon: const Icon(Icons.qr_code_2, size: 18),
                                  label: const Text('QR'),
                                )
                              : const StatusChip(variant: ChipVariant.confirmed, label: 'Active'),
                          chevron: false,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _issue(BuildContext context, UserProfile record) async {
    final adminUid = context.read<AuthProvider>().service.currentUser?.uid ?? '';
    final messenger = ScaffoldMessenger.of(context);
    String? token;
    try {
      token = await ActivationService().issueToken(record, adminUid);
    } on DataConstraintException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Couldn\'t issue an activation code.')));
      return;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 16, AppSpacing.screen, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            ),
            Text('Activation QR for ${record.first}', style: AppText.headlineSm),
            const SizedBox(height: 4),
            Text('Single-use · expires in 7 days',
                style: AppText.labelSm.copyWith(color: AppColors.hint)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: AppShadow.l1),
              child: QrImageView(
                data: token!,
                size: 200,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: AppColors.primaryNavy),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.primaryNavy),
              ),
            ),
            const SizedBox(height: 16),
            SelectableText('Code: $token',
                style: AppText.labelSm.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
