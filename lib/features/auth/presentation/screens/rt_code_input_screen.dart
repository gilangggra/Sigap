import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman input kode RT/RW unik untuk verifikasi domisili warga di lingkungan terkait.
/// Mengadopsi standar desain mobile kesehatan modern yang bersih, konsisten, dan rapi.
class RtCodeInputScreen extends StatefulWidget {
  const RtCodeInputScreen({super.key});

  @override
  State<RtCodeInputScreen> createState() => _RtCodeInputScreenState();
}

class _RtCodeInputScreenState extends State<RtCodeInputScreen> {
  final TextEditingController _codeController = TextEditingController(text: 'SIGAP-RT03-26');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleValidateCode() async {
    final String code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length < 6) {
      setState(() {
        _errorMessage = 'Masukkan kode RT yang valid (contoh: SIGAP-RT03-26).';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.joinWithInviteCode(code);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      unawaited(FeedbackService.instance.triggerSuccessFeedback());
      if (mounted) {
        context.go('/auth/pending-verification');
      }
    } else {
      unawaited(FeedbackService.instance.triggerWarningFeedback());
      if (mounted) {
        setState(() {
          _errorMessage = authProvider.errorMessage ??
              'Kode RT tidak ditemukan atau sudah kedaluwarsa.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Verifikasi Domisili RT/RW'),
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
                'Masukkan Kode RT Anda',
                style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Kode unik ini diperoleh dari Pengurus RT setempat untuk memastikan Anda adalah warga yang terdaftar.',
                style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Kartu Input Kode RT
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
                  vertical: AppDimensions.spaceMD,
                ),
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.textDarkPrimary,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'SIGAP-RTXX-XX',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textDarkTertiary,
                      letterSpacing: 2.0,
                      fontSize: 18.0,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),

              // Pesan Kesalahan yang Ramah (Tanpa exception teknis mentah)
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

              const SizedBox(height: AppDimensions.spaceLG),

              // Banner Informasi Kode Demo
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.primaryTealLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primaryTealDeep,
                      size: 20.0,
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Lingkungan Demo',
                            style: GoogleFonts.poppins(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTealDeep,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          RichText(
                            text: TextSpan(
                              style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                              children: [
                                const TextSpan(text: 'Untuk demonstrasi, kode aktif lingkungan adalah: '),
                                TextSpan(
                                  text: 'SIGAP-RT03-26',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTealDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space2XL),

              // Tombol Aksi Utama
              AccessibleButton(
                label: _isLoading ? 'Memverifikasi Lingkungan...' : 'Gabung Lingkungan RT',
                onPressed: _isLoading ? null : _handleValidateCode,
                isSimplified: true,
                backgroundColor: AppColors.primaryTeal,
                icon: Icons.domain_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Navigasi Kembali ke Pilihan Peran
              Center(
                child: TextButton.icon(
                  onPressed: () => context.go('/auth/role'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16.0, color: AppColors.textDarkSecondary),
                  label: Text(
                    'Kembali ke Pemilihan Peran',
                    style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
