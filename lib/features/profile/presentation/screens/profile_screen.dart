import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman Profil Pengguna & Pengaturan Mode Lansia (Simplified Mode)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;
    final areaName = authProvider.rtArea?.formattedAreaName ?? 'RT 03 / RW 05, Menteng';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Header Profil
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  border: Border.all(color: AppColors.darkBorderHighContrast),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36.0,
                      backgroundColor: AppColors.infoBlue.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: AppColors.infoBlueLight, size: 44.0),
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? authProvider.fullName ?? 'Warga SIGAP',
                            style: AppTypography.seniorTitle(color: Colors.white),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            user?.phoneNumber ?? authProvider.phoneNumber ?? '+628123456789',
                            style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.infoBlue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.infoBlueLight),
                                ),
                                child: Text(
                                  authProvider.role.label,
                                  style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: authProvider.isVerified ? AppColors.safeGreenDark : AppColors.warningAmberDark,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  authProvider.isVerified ? 'Terverifikasi' : 'Menunggu RT',
                                  style: const TextStyle(color: Colors.white, fontSize: 11.0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // Wilayah Domisili RT/RW
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_city_rounded, color: AppColors.infoBlueLight, size: 28.0),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lingkungan Domisili', style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
                          Text(areaName, style: AppTypography.standardBody(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Toggle Mode Lansia (Simplified Mode)
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.darkBorderHighContrast),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.accessibility_new_rounded, color: AppColors.safeGreenLight, size: 30.0),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Aksesibilitas Lansia',
                            style: AppTypography.seniorBodyPrimary(color: Colors.white),
                          ),
                          Text(
                            'Perbesar tombol (min 72dp) dan teks (min 18sp) berstandar WCAG AA.',
                            style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: authProvider.simplifiedMode,
                      activeColor: AppColors.safeGreenLight,
                      onChanged: (val) {
                        FeedbackService.instance.triggerSuccessFeedback();
                        authProvider.setSimplifiedMode(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Tombol Lihat Kartu Medis Digital & QR Code
              AccessibleButton(
                label: 'Kartu Medis Digital & QR (ICE)',
                onPressed: () => context.push('/profile/ice-card-view'),
                isSimplified: authProvider.simplifiedMode,
                backgroundColor: AppColors.emergencyRed,
                icon: Icons.qr_code_2_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Kelola ICE Card Medis
              AccessibleButton(
                label: 'Kelola Data Medis Darurat (ICE Card)',
                onPressed: () => context.push('/profile/ice-card'),
                isSimplified: authProvider.simplifiedMode,
                backgroundColor: AppColors.darkCard,
                borderColor: AppColors.darkBorderHighContrast,
                icon: Icons.medical_services_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Ganti Peran
              AccessibleButton(
                label: 'Ganti Peran Pengguna',
                onPressed: () => context.go('/auth/role'),
                isSimplified: authProvider.simplifiedMode,
                isSecondary: true,
                icon: Icons.swap_horiz_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // Tombol Keluar
              TextButton.icon(
                onPressed: () {
                  authProvider.reset();
                  context.go('/auth/phone');
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.emergencyRedLight),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(color: AppColors.emergencyRedLight, fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

