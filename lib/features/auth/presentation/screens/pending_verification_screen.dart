import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../../data/repositories/auth_repository.dart';

/// Halaman tunggu verifikasi warga oleh Pengurus RT/RW setempat.
/// Mengadopsi standar desain mobile kesehatan modern yang bersih, konsisten, dan rapi.
class PendingVerificationScreen extends StatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  State<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  final AuthRepository _authRepository = AuthRepository();
  bool _isChecking = false;

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    final authProvider = context.read<AuthProvider>();
    await FeedbackService.instance.triggerSuccessFeedback();

    if (!mounted) return;

    if (authProvider.userId != null) {
      final profile = await _authRepository.getUserProfile(authProvider.userId!);
      if (profile != null && profile.isVerified) {
        authProvider.setAuthenticated(
          userId: profile.id,
          phone: profile.phoneNumber,
          userRole: profile.role,
          isVerifiedStatus: true,
          name: profile.fullName,
          areaId: profile.rtAreaId,
        );

        if (!mounted) return;
        _navigateToRoleHome(profile.role);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isChecking = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status Anda masih dalam antrean peninjauan oleh Pengurus RT.'),
      ),
    );
  }

  void _simulateImmediateApproval() {
    unawaited(FeedbackService.instance.triggerSuccessFeedback());
    final authProvider = context.read<AuthProvider>();

    authProvider.setAuthenticated(
      userId: authProvider.userId ?? AppConstants.demoUserId,
      phone: authProvider.phoneNumber ?? '+628123456789',
      userRole: authProvider.role,
      isVerifiedStatus: true,
      name: authProvider.fullName ?? 'Warga SIGAP',
      areaId: authProvider.rtAreaId ?? AppConstants.demoRtAreaId,
    );

    _navigateToRoleHome(authProvider.role);
  }

  void _navigateToRoleHome(UserRole role) {
    switch (role) {
      case UserRole.careReceiver:
        context.go('/care-receiver');
        break;
      case UserRole.responder:
        context.go('/responder');
        break;
      case UserRole.guardian:
        context.go('/guardian');
        break;
      case UserRole.civicAdmin:
        context.go('/admin');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final String areaName = authProvider.rtArea?.formattedAreaName ?? 'RT 03 / RW 05, Menteng';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Menunggu Verifikasi'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.spaceMD),

              // Ikon Status Jam Pasir Lembut
              Center(
                child: Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.warningAmber.withValues(alpha: 0.4),
                      width: 2.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.warningAmber,
                    size: 40.0,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              Text(
                'Pendaftaran Sedang Ditinjau',
                style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4.0),

              Text(
                'Pengurus RT setempat akan memverifikasi identitas Anda untuk mengaktifkan akses fitur saling bantu.',
                style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // Kartu Rincian Domisili Terdaftar
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 6.0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTealLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primaryTealDeep,
                        size: 22.0,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wilayah Domisili Terdaftar',
                            style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            areaName,
                            style: GoogleFonts.poppins(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDarkPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space2XL),

              // Tombol Periksa Status
              AccessibleButton(
                label: _isChecking ? 'Memeriksa...' : 'Periksa Status Persetujuan',
                onPressed: _isChecking ? null : _checkVerificationStatus,
                isSimplified: true,
                backgroundColor: AppColors.primaryTeal,
                icon: Icons.refresh_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Demo Langsung Setuju
              AccessibleButton(
                label: 'Simulasikan Persetujuan (Demo)',
                onPressed: _simulateImmediateApproval,
                isSimplified: true,
                isSecondary: true,
                icon: Icons.verified_user_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // Tombol Kembali / Ganti Peran
              Center(
                child: TextButton.icon(
                  onPressed: () => context.go('/auth/role'),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18.0, color: AppColors.textDarkSecondary),
                  label: Text(
                    'Ganti Peran Lain',
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
