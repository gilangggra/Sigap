import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman input nomor telepon untuk proses verifikasi OTP
class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final String rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty || rawPhone.length < 8) {
      setState(() {
        _errorMessage = 'Nomor telepon tidak valid. Masukkan minimal 8 digit.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String formattedPhone = rawPhone.startsWith('0')
        ? '+62${rawPhone.substring(1)}'
        : (rawPhone.startsWith('+62') ? rawPhone : '+62$rawPhone');

    final success = await ref.read(authStateProvider.notifier).sendOtp(formattedPhone);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Arahkan ke layar verifikasi OTP
      unawaited(context.push('/auth/otp', extra: formattedPhone));
    } else {
      setState(() {
        _errorMessage = ref.read(authStateProvider).errorMessage ?? 'Gagal mengirim OTP.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Masuk / Daftar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                'Selamat Datang di SIGAP',
                style: AppTypography.seniorHeadingMedium(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Masukkan nomor telepon aktif Anda untuk menerima kode verifikasi OTP.',
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
                  horizontal: AppDimensions.spaceMD,
                  vertical: AppDimensions.spaceXS,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceSM,
                        vertical: AppDimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: Text(
                        '🇮🇩 +62',
                        style: AppTypography.seniorBodyPrimary(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.seniorBodyPrimary(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '812-3456-7890',
                          hintStyle: TextStyle(color: AppColors.textDarkTertiary, fontSize: 18.0),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppDimensions.spaceSM),
                Text(
                  _errorMessage!,
                  style: AppTypography.seniorBodySecondary(color: AppColors.emergencyRedLight),
                ),
              ],
              const SizedBox(height: AppDimensions.space2XL),
              AccessibleButton(
                label: _isLoading ? 'Mengirim Kode...' : 'Kirim Kode Verifikasi',
                onPressed: _isLoading ? null : _handleSendOtp,
                isSimplified: true,
                backgroundColor: AppColors.infoBlue,
                icon: Icons.sms_outlined,
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              AccessibleButton(
                label: 'Lanjutkan Sebagai Tamu / Demo',
                onPressed: () => context.push('/auth/role'),
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

