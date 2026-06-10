import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routing/routes.dart';
import '../../services/biometric_vault.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _vault = BiometricVault();
  bool _remember = true;
  bool _showPw = false;
  bool _biometricReady = false;
  bool _deviceBiometric = false;
  String? _idErr;
  String? _pwErr;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    try {
      final la = LocalAuthentication();
      final supported = await la.isDeviceSupported();
      final ready = await _vault.canUseBiometricLogin();
      if (mounted) {
        setState(() {
          _deviceBiometric = supported;
          _biometricReady = supported && ready;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _id.text.trim();
    setState(() {
      _idErr = id.isEmpty
          ? 'Enter your university ID.'
          : !RegExp(r'^\d{6,}$').hasMatch(id)
              ? 'IDs are at least 6 digits (e.g. 202400123).'
              : null;
      _pwErr = _pw.text.isEmpty ? 'Enter your password.' : null;
    });
    if (_idErr != null || _pwErr != null) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(id, _pw.text);
    if (!ok && mounted) {
      setState(() => _pwErr = auth.error);
      auth.clearError();
      return;
    }
    if (ok && mounted) {
      if (_remember) {
        await _vault.save(idNumber: id, password: _pw.text);
      } else {
        await _vault.clear();
      }
      await _loadBiometricState();
    }
    // On success, the router redirect handles navigation.
  }

  Future<void> _biometric() async {
    try {
      final la = LocalAuthentication();
      if (!await la.isDeviceSupported()) {
        _toast('Biometric unlock isn\'t available on this device.');
        return;
      }
      final creds = await _vault.readCredentials();
      if (creds == null) {
        _toast('Sign in with "Remember me" checked to link Face ID.');
        return;
      }
      final ok = await la.authenticate(
        localizedReason: 'Unlock Campus Assistant',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!ok || !mounted) return;

      final auth = context.read<AuthProvider>();
      final signedIn = await auth.signIn(creds.idNumber, creds.password);
      if (!signedIn && mounted) {
        setState(() => _pwErr = auth.error ?? 'Biometric sign-in failed.');
        auth.clearError();
        await _vault.clear();
        await _loadBiometricState();
      }
    } catch (_) {
      _toast('Biometric unlock isn\'t available right now.');
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, 50, AppSpacing.screen, 32),
          child: Column(
            children: [
              const Logo(size: 64),
              const SizedBox(height: 18),
              Text('Campus Assistant',
                  style: AppText.headlineLg
                      .copyWith(fontSize: 28, color: AppColors.primaryNavy)),
              const SizedBox(height: 6),
              Text('Sign in to your university account',
                  style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 24),
              AppCard(
                pad: 20,
                shadow: AppShadow.l2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Student or Staff ID'),
                    AppTextField(
                      icon: Icons.person_outline,
                      hint: 'e.g. 202400123',
                      controller: _id,
                      keyboardType: TextInputType.number,
                      error: _idErr,
                      onChanged: (_) => setState(() => _idErr = null),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Password', style: AppText.labelLg),
                        GestureDetector(
                          onTap: () {
                            final id = _id.text.trim();
                            if (id.isEmpty) {
                              setState(() => _idErr = 'Enter your ID first.');
                              return;
                            }
                            context.read<AuthProvider>().sendReset(id);
                            _toast('Password reset link sent to your university email.');
                          },
                          child: Text('Forgot Password?',
                              style: AppText.labelSm.copyWith(
                                  color: AppColors.primaryNavy,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    AppTextField(
                      icon: Icons.lock_outline,
                      hint: 'Enter password',
                      controller: _pw,
                      obscure: !_showPw,
                      error: _pwErr,
                      trailing: Icon(
                          _showPw ? Icons.visibility_off : Icons.visibility,
                          size: 19,
                          color: AppColors.hint),
                      onTrailingTap: () => setState(() => _showPw = !_showPw),
                      onChanged: (_) => setState(() => _pwErr = null),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _remember = !_remember),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _remember ? AppColors.primaryNavy : AppColors.fill,
                              borderRadius: BorderRadius.circular(6),
                              border: _remember
                                  ? null
                                  : Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: _remember
                                ? const Icon(Icons.check, size: 15, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text('Remember me for 30 days',
                              style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: busy ? 'Signing in…' : 'Log In',
                      onPressed: busy ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: AppText.labelSm.copyWith(color: AppColors.hint)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ]),
                    const SizedBox(height: 12),
                    // First-time activation: scan the admin-issued QR or paste
                    // the code (both handled on the same screen).
                    SecondaryButton(
                      label: 'Activate Account',
                      icon: Icons.qr_code_scanner,
                      onPressed: () => context.push(Routes.scanQr),
                    ),
                    const SizedBox(height: 12),
                    if (_deviceBiometric) ...[
                      OutlineButton(
                        label: _biometricReady ? 'Unlock with Face ID' : 'Biometric',
                        icon: Icons.fingerprint,
                        onPressed: _biometric,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text.rich(
                TextSpan(
                  text: 'Need technical assistance? ',
                  style: AppText.bodyMd.copyWith(color: AppColors.textMuted),
                  children: const [
                    TextSpan(
                        text: 'Contact Support',
                        style: TextStyle(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Privacy Policy  ·  Terms of Service',
                  style: AppText.labelSm.copyWith(color: AppColors.hint)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(t, style: AppText.labelLg)),
      );
}
