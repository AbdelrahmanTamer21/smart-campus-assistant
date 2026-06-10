import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/biometric_vault.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _vault = BiometricVault();
  bool _push = true;
  bool _biometric = false;
  bool _biometricLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPref();
  }

  Future<void> _loadBiometricPref() async {
    final enabled = await _vault.isEnabled();
    if (mounted) {
      setState(() {
        _biometric = enabled;
        _biometricLoaded = true;
      });
    }
  }

  Future<void> _setBiometric(bool enabled) async {
    if (enabled) {
      final hasCreds = await _vault.hasCredentials();
      if (!hasCreds && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Sign out, then log in again with "Remember me" checked to link Face ID.'),
        ));
        return;
      }
      await _vault.setEnabled(true);
    } else {
      await _vault.clear();
    }
    if (mounted) setState(() => _biometric = enabled);
  }

  Future<void> _changePhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final docId = context.read<AuthProvider>().profile?.docId;
    if (docId == null) return;
    try {
      final picker = ImagePicker();
      // Small images keep the base64 well under Firestore's 1 MB doc limit.
      final file = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 256, imageQuality: 70);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update({'photoBase64': base64Encode(bytes)});
      messenger.showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Couldn\'t update photo right now.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final offline = context.watch<ConnectivityProvider>().offline;
    final p = auth.profile;
    final role = auth.activeRole;
    final bg = switch (role) {
      UserRole.admin => AppColors.accentSocial,
      UserRole.staff => AppColors.accentAcademic,
      _ => AppColors.primaryNavy,
    };
    final roleLabel = switch (role) {
      UserRole.admin => 'Administrator',
      UserRole.staff => 'Faculty',
      _ => 'Undergraduate',
    };

    return ScreenScaffold(
      header: SCAppBar(
          onBack: context.canPop() ? () => context.pop() : null,
          title: 'Account',
          subtitle: 'Profile'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, 40),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Stack(
              children: [
                Avatar(initials: p?.initials ?? 'U', bg: bg, size: 88, photoBase64: p?.photoBase64),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _changePhoto,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadow.l1,
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          size: 16, color: AppColors.primaryNavy),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(p?.name ?? '', style: AppText.headlineMd),
            const SizedBox(height: 2),
            Text('ID ${p?.idNumber ?? ''} · $roleLabel',
                style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 14),
            SizedBox(
              width: 160,
              child: OutlineButton(
                label: 'Edit Profile',
                icon: Icons.edit_outlined,
                height: 42,
                onPressed: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Editing profile…'))),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: SectionHeader(title: 'Preferences', small: true),
            ),
            AppCard(
              pad: 18,
              child: Column(
                children: [
                  AppToggle(
                      label: 'Push Notifications',
                      sub: 'Announcements, reminders & alerts',
                      value: _push,
                      onChanged: (v) => setState(() => _push = v)),
                  const Divider(height: 28),
                  AppToggle(
                      label: 'Biometric Unlock',
                      sub: 'Use Face ID to sign in',
                      value: _biometric,
                      onChanged: (v) {
                        if (_biometricLoaded) _setBiometric(v);
                      }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: SectionHeader(title: 'Sync', small: true),
            ),
            AppCard(
              child: Row(
                children: [
                  IconCircle(
                    icon: offline ? Icons.wifi_off : Icons.check_circle_outline,
                    tint: offline ? AppColors.errorContainer : AppColors.successContainer,
                    color: offline ? AppColors.error : AppColors.success,
                    size: 42,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(offline ? 'Offline — showing saved data' : 'All data synced',
                            style: AppText.labelLg.copyWith(fontSize: 14)),
                        Text('Last updated just now',
                            style: AppText.bodyMd
                                .copyWith(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthProvider>().signOut(),
                icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                label: Text('Sign Out',
                    style: AppText.labelLg.copyWith(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
