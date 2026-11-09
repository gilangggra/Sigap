import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      userId: authProvider.userId ?? 'demo-user-id',
      phone: authProvider.phoneNumber ?? '+628123456789',
      userRole: authProvider.role,
      isVerifiedStatus: true,
      name: authProvider.fullName ?? 'Warga SIGAP',
      areaId: authProvider.rtAreaId ?? '00000000-0000-0000-0000-000000000001',
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
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Menunggu Verifikasi'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 88.0,
                height: 88.0,
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.warningAmber, width: 2.0),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.warningAmberLight,
                  size: 48.0,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              Text(
                'Pendaftaran Sedang Ditinjau',
                style: AppTypography.seniorHeadingMedium(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                'Akun Anda telah didaftarkan untuk wilayah:\n$areaName\n\nPengurus RT setempat akan memverifikasi identitas Anda untuk mengaktifkan akses fitur saling bantu.',
                style: AppTypography.seniorBodyPrimary(color: AppColors.textDarkSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.space2XL),
              AccessibleButton(
                label: _isChecking ? 'Memeriksa...' : 'Periksa Status Persetujuan',
                onPressed: _isChecking ? null : _checkVerificationStatus,
                isSimplified: true,
                backgroundColor: AppColors.infoBlue,
                icon: Icons.refresh_rounded,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              AccessibleButton(
                label: 'Simulasikan Persetujuan (Demo)',
                onPressed: _simulateImmediateApproval,
                isSimplified: true,
                isSecondary: true,
                icon: Icons.verified_user_rounded,
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              TextButton(
                onPressed: () => context.go('/auth/role'),
                child: Text(
                  'Ganti Peran Lain',
                  style: AppTypography.standardButtonLabel(color: AppColors.textDarkSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
