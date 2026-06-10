import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

/// Final step of QR activation: identity is read-only (from the record), the
/// user only sets a password. Redeem binds the auth account to the record.
class CompleteSignupScreen extends StatefulWidget {
  final String token;
  final String name;
  final String idNumber;
  const CompleteSignupScreen({
    super.key,
    required this.token,
    required this.name,
    required this.idNumber,
  });

  @override
  State<CompleteSignupScreen> createState() => _CompleteSignupScreenState();
}

class _CompleteSignupScreenState extends State<CompleteSignupScreen> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  String? _pwErr;
  String? _confirmErr;

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() {
      _pwErr = _pw.text.length < 8 ? 'Use at least 8 characters.' : null;
      _confirmErr =
          _confirm.text != _pw.text ? 'Passwords don\'t match.' : null;
    });
    if (_pwErr != null || _confirmErr != null) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.redeem(widget.token, _pw.text);
    if (!ok && mounted) {
      setState(() => _pwErr = auth.error);
      auth.clearError();
    }
    // On success the router redirect routes by role.
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;
    final initials = widget.name.isEmpty
        ? '?'
        : widget.name
            .trim()
            .split(' ')
            .map((p) => p.isEmpty ? '' : p[0])
            .take(2)
            .join();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SCAppBar(
              onBack: () => context.pop(),
              title: 'Activate',
              subtitle: 'Set your password',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, 0, AppSpacing.screen, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Avatar(initials: initials, size: 72),
                    const SizedBox(height: 14),
                    Text(widget.name,
                        style: AppText.headlineMd, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('ID ${widget.idNumber}',
                        style: AppText.bodyMd.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 24),
                    AppCard(
                      pad: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Welcome! Your account and courses are ready — '
                              'just set a password to activate.',
                              style: AppText.bodyMd
                                  .copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 16),
                          AppTextField(
                            icon: Icons.lock_outline,
                            hint: 'New password',
                            controller: _pw,
                            obscure: true,
                            error: _pwErr,
                            onChanged: (_) => setState(() => _pwErr = null),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            icon: Icons.lock_outline,
                            hint: 'Confirm password',
                            controller: _confirm,
                            obscure: true,
                            error: _confirmErr,
                            onChanged: (_) => setState(() => _confirmErr = null),
                          ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: busy ? 'Activating…' : 'Activate & Sign In',
                            icon: Icons.check_circle_outline,
                            onPressed: busy ? null : _activate,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
