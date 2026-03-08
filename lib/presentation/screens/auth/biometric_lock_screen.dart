import 'package:flutter/material.dart';

import '../../../core/auth/biometric_service.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const BiometricLockScreen({super.key, required this.onAuthenticated});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final _biometricService = sl<BiometricService>();
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);

    final success = await _biometricService.authenticate();
    if (success && mounted) {
      widget.onAuthenticated();
    } else if (mounted) {
      setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text('MGMess', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                context.l10n.authenticationRequired,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 32),
              if (_authenticating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(context.l10n.unlock),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
