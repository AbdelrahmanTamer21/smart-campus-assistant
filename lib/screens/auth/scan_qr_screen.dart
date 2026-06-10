import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

/// Scans an admin-issued activation token (or accepts a pasted code as a
/// camera-less fallback), validates it, then continues to set a password.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});
  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _handling = false;
  String? _error;
  final _manual = TextEditingController();

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _validate(String token) async {
    if (_handling) return;
    setState(() {
      _handling = true;
      _error = null;
    });
    try {
      final db = FirebaseFirestore.instance;
      final trimmed = token.trim();
      final snap = await db.collection('signupTokens').doc(trimmed).get();
      if (!snap.exists) throw 'This activation code is invalid.';
      final t = snap.data()!;
      if (t['used'] == true) throw 'This code has already been used.';
      final exp = (t['expiresAt'] as Timestamp?)?.toDate();
      if (exp != null && exp.isBefore(DateTime.now())) {
        throw 'This code has expired. Ask your admin for a new one.';
      }

      final idNumber = (t['idNumber'] as String?)?.trim() ?? '';
      if (idNumber.isEmpty) throw 'This activation code is invalid.';

      var name = (t['name'] as String?)?.trim() ?? '';
      final recId = t['targetUserDocId'] as String?;
      if (recId != null) {
        try {
          final rec = await db.collection('users').doc(recId).get();
          if (!rec.exists || rec.data()?['status'] != 'unclaimed') {
            throw 'This account is already activated.';
          }
          if (name.isEmpty) name = rec.data()?['name'] as String? ?? '';
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            throw 'This account is already activated.';
          }
          rethrow;
        }
      }

      if (!mounted) return;
      context.pushReplacement(Routes.completeSignup, extra: {
        'token': trimmed,
        'name': name,
        'idNumber': idNumber,
      });
    } catch (e) {
      setState(() {
        _error = e is FirebaseException
            ? _friendlyFirestore(e)
            : e.toString().replaceFirst('Exception: ', '');
        _handling = false;
      });
    }
  }

  String _friendlyFirestore(FirebaseException e) => switch (e.code) {
        'permission-denied' =>
          'This account is already activated or the code is no longer valid.',
        'unavailable' => 'No connection. Check your network and try again.',
        _ => 'Could not verify this code. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDarkest,
      body: SafeArea(
        child: Column(
          children: [
            SCAppBar(
              dark: true,
              onBack: () => context.pop(),
              title: 'Activate',
              subtitle: 'Scan your code',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: _Scanner(onCode: _validate),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Point the camera at the activation QR your admin issued.',
                      textAlign: TextAlign.center,
                      style: AppText.bodyMd.copyWith(color: Colors.white70),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: AppText.labelSm.copyWith(
                                color: AppColors.errorContainer)),
                      ),
                    const SizedBox(height: 16),
                    // Camera-less fallback (web/desktop testing).
                    AppTextField(
                      icon: Icons.keyboard_alt_outlined,
                      hint: 'Or paste your activation code',
                      controller: _manual,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: _handling ? 'Checking…' : 'Continue',
                      onPressed: _handling
                          ? null
                          : () => _validate(_manual.text),
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

class _Scanner extends StatefulWidget {
  final ValueChanged<String> onCode;
  const _Scanner({required this.onCode});

  @override
  State<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        final raw = capture.barcodes.isNotEmpty
            ? capture.barcodes.first.rawValue
            : null;
        if (raw != null && raw.isNotEmpty) widget.onCode(raw);
      },
      errorBuilder: (_, error) => _CameraFallback(message: error.errorDetails?.message),
      placeholderBuilder: (_) => Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white54),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  final String? message;
  const _CameraFallback({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2, size: 64, color: Colors.white38),
          const SizedBox(height: 12),
          Text(
            message ?? 'Camera unavailable',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste your activation code below instead.',
            textAlign: TextAlign.center,
            style: AppText.labelSm.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
