import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman tunggu verifikasi warga oleh Pengurus RT/RW setempat.
class PendingVerificationScreen extends ConsumerStatefulWidget {
  const PendingVerificationScreen({super.key});

  @override
  ConsumerState<PendingVerificationScreen> createState() => _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends ConsumerState<PendingVerificationScreen> {
  bool _isChecking = false;

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    await FeedbackService.instance.triggerSuccessFeedback();

    final authState = ref.read(authStateProvider);

    if (authState.userId != null) {
      final repository = ref.read(authRepositoryProvider);
      final profile = await repository.getUserProfile(authState.userId!);
      if (profile != null && profile.isVerified) {
        ref.read(authStateProvider.notifier).setAuthenticated(
              userId: profile.id,
              phoneNumber: profile.phoneNumber,
              role: profile.role,
              isVerified: true,
              fullName: profile.fullName,
              rtAreaId: profile.rtAreaId,
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
    final authState = ref.read(authStateProvider);

    ref.read(authStateProvider.notifier).setAuthenticated(
          userId: authState.userId ?? 'demo-user-id',
          phoneNumber: authState.phoneNumber ?? '+628123456789',
          role: authState.role,
          isVerified: true,
          fullName: authState.fullName ?? 'Warga SIGAP',
          rtAreaId: authState.rtAreaId ?? '00000000-0000-0000-0000-000000000001',
        );

    _navigateToRoleHome(authState.role);
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
    final authState = ref.watch(authStateProvider);
    final String areaName = authState.rtArea?.formattedAreaName ?? 'RT 03 / RW 05, Menteng';

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
