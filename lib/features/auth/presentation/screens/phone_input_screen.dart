import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman input nomor telepon untuk proses verifikasi OTP
/// Menggunakan standar antarmuka mobile yang rapi dan konsisten dengan font Poppins.
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
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

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendOtp(formattedPhone);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      unawaited(context.push('/auth/otp', extra: formattedPhone));
    } else {
      setState(() {
        _errorMessage = authProvider.errorMessage ?? 'Gagal mengirim OTP.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Masuk / Daftar'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Selamat Datang di SIGAP',
                style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
              ),
              const SizedBox(height: 2.0),
              Text(
                'Masukkan nomor telepon aktif Anda untuk menerima kode verifikasi OTP.',
                style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.emergencyRed
                        : AppColors.lightBorder,
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 6.0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceMD,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTealLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: const Text(
                        '🇮🇩 +62',
                        style: TextStyle(
                          color: AppColors.primaryTealDeep,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                        decoration: InputDecoration(
                          hintText: '812-3456-7890',
                          hintStyle: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
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
                  style: AppTypography.standardCaption(color: AppColors.emergencyRed),
                ),
              ],
              const SizedBox(height: AppDimensions.spaceLG),
              AccessibleButton(
                label: _isLoading ? 'Mengirim Kode...' : 'Kirim Kode Verifikasi',
                onPressed: _isLoading ? null : _handleSendOtp,
                isSimplified: true,
                backgroundColor: AppColors.primaryTeal,
                icon: Icons.sms_outlined,
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              AccessibleButton(
                label: 'Lanjutkan Sebagai Tamu / Demo',
                onPressed: () => context.push('/auth/role'),
                isSimplified: true,
                isSecondary: true,
                backgroundColor: AppColors.cardWhite,
                borderColor: AppColors.lightBorder,
                textColor: AppColors.textDarkPrimary,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
            ],
          ),
        ),
      ),
    );
  }
}
