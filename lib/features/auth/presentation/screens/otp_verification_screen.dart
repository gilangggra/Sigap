import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman verifikasi kode OTP 6-digit
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    final String otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Masukkan 6 digit kode verifikasi yang benar.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulasi verifikasi OTP sukses -> arahkan ke pemilihan peran
    context.go('/auth/role');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                'Masukkan Kode 6 Digit',
                style: AppTypography.seniorHeadingMedium(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Kode verifikasi telah dikirim melalui SMS ke ${widget.phoneNumber}.',
                style: AppTypography.seniorBodyPrimary(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.emergencyRed
                        : AppColors.darkBorderHighContrast,
                    width: AppDimensions.highContrastBorderWidth,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceLG,
                  vertical: AppDimensions.spaceMD,
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32.0,
                    letterSpacing: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '------',
                    hintStyle: TextStyle(
                      color: AppColors.textDarkTertiary,
                      letterSpacing: 12.0,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppDimensions.spaceSM),
                Text(
                  _errorMessage!,
                  style: AppTypography.seniorBodySecondary(color: AppColors.emergencyRedLight),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppDimensions.space2XL),
              AccessibleButton(
                label: _isLoading ? 'Memverifikasi...' : 'Verifikasi & Lanjutkan',
                onPressed: _isLoading ? null : _verifyOtp,
                isSimplified: true,
                backgroundColor: AppColors.safeGreen,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              AccessibleButton(
                label: 'Kirim Ulang Kode (SMS)',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kode OTP baru telah dikirimkan')),
                  );
                },
                isSimplified: true,
                isSecondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

