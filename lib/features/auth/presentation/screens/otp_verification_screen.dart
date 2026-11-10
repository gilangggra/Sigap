import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman verifikasi kode OTP 6-digit.
/// Mengadopsi standar desain mobile kesehatan modern yang bersih, konsisten, dan rapi.
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
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

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(
      phone: widget.phoneNumber,
      token: otp,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      context.go('/auth/role');
    } else {
      setState(() {
        _errorMessage = authProvider.errorMessage ??
            'Kode OTP salah atau telah kedaluwarsa.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
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
                'Masukkan Kode 6 Digit',
                style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Kode verifikasi telah dikirim melalui SMS ke ${widget.phoneNumber}.',
                style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Kartu Input OTP
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.emergencyRed
                        : AppColors.lightBorder,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceLG,
                  vertical: AppDimensions.spaceLG,
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.textDarkPrimary,
                    fontSize: 30.0,
                    letterSpacing: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textDarkTertiary,
                      letterSpacing: 10.0,
                      fontSize: 30.0,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),

              // Alert pesan kesalahan jika ada
              if (_errorMessage != null) ...[
                const SizedBox(height: AppDimensions.spaceSM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceMD,
                    vertical: AppDimensions.spaceSM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                    border: Border.all(
                      color: AppColors.emergencyRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.emergencyRed,
                        size: 18.0,
                      ),
                      const SizedBox(width: AppDimensions.spaceSM),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.standardCaption(color: AppColors.emergencyRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.space2XL),

              // Tombol Verifikasi Utama
              AccessibleButton(
                label: _isLoading ? 'Memverifikasi...' : 'Verifikasi & Lanjutkan',
                onPressed: _isLoading ? null : _verifyOtp,
                isSimplified: true,
                backgroundColor: AppColors.primaryTeal,
                icon: Icons.check_circle_outline_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Kirim Ulang OTP
              AccessibleButton(
                label: 'Kirim Ulang Kode (SMS)',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.primaryTealDeep,
                      content: Text('Kode OTP baru telah dikirimkan ke nomor Anda'),
                    ),
                  );
                },
                isSimplified: true,
                isSecondary: true,
                icon: Icons.sms_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
