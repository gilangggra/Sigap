import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/components.dart';

/// Halaman Profil Pengguna & Pengaturan Mode Aksesibilitas Lansia
/// Menggunakan tata letak standar mobile yang bersih, rapi, dan konsisten dengan font Poppins.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;
    final areaName = authProvider.rtArea?.formattedAreaName ?? 'RT 04 / RW 02, Menteng';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20.0),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceSM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Header Profil
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                child: Row(
                  children: [
                    AppAvatar(
                      name: user?.fullName ?? authProvider.fullName ?? 'Warga SIGAP',
                      radius: 30.0,
                      isOnline: authProvider.isVerified,
                      showBadge: true,
                      borderColor: AppColors.primaryTealLight,
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? authProvider.fullName ?? 'Warga SIGAP',
                            style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            user?.phoneNumber ?? authProvider.phoneNumber ?? '+62 812-3456-7890',
                            style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                          ),
                          const SizedBox(height: 6.0),
                          Row(
                            children: [
                              AppBadge.brand(authProvider.role.label, isSmall: true),
                              const SizedBox(width: 6.0),
                              if (authProvider.isVerified)
                                AppBadge.success('Terverifikasi', isSmall: true)
                              else
                                AppBadge.warning('Menunggu RT', isSmall: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Wilayah Domisili RT/RW
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTealLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_city_rounded, color: AppColors.primaryTealDark, size: 22.0),
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lingkungan Domisili', style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
                          Text(areaName, style: AppTypography.standardTitle(color: AppColors.textDarkPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Toggle Mode Lansia (Simplified Mode)
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(
                        color: AppColors.safeGreenWash,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.accessibility_new_rounded, color: AppColors.safeGreenDark, size: 22.0),
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Aksesibilitas Lansia',
                            style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                          ),
                          Text(
                            'Tombol lebih besar (min 72dp) dan teks diperbesar.',
                            style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: authProvider.simplifiedMode,
                      activeColor: AppColors.primaryTeal,
                      onChanged: (val) {
                        FeedbackService.instance.triggerSuccessFeedback();
                        authProvider.setSimplifiedMode(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              const AppSectionHeader(title: 'Data Medis Darurat'),
              const SizedBox(height: AppDimensions.spaceSM),

              // Tombol Lihat Kartu Medis Digital & QR Code
              AccessibleButton(
                label: 'Lihat Kartu Medis Digital & QR (ICE)',
                onPressed: () => context.push('/profile/ice-card-view'),
                isSimplified: authProvider.simplifiedMode,
                backgroundColor: AppColors.primaryTeal,
                icon: Icons.qr_code_2_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceSM),

              // Tombol Kelola ICE Card Medis
              AccessibleButton(
                label: 'Kelola Data Medis Darurat (ICE Card)',
                onPressed: () => context.push('/profile/ice-card'),
                isSimplified: authProvider.simplifiedMode,
                backgroundColor: AppColors.cardWhite,
                borderColor: AppColors.lightBorder,
                textColor: AppColors.textDarkPrimary,
                icon: Icons.medical_services_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              const AppSectionHeader(title: 'Pengaturan Akun'),
              const SizedBox(height: AppDimensions.spaceSM),

              // Tombol Ganti Peran
              AccessibleButton(
                label: 'Ganti Peran Pengguna',
                onPressed: () => context.go('/auth/role'),
                isSimplified: authProvider.simplifiedMode,
                isSecondary: true,
                backgroundColor: AppColors.mintSurface,
                borderColor: AppColors.lightBorder,
                textColor: AppColors.textDarkPrimary,
                icon: Icons.swap_horiz_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Keluar
              TextButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go('/auth/phone');
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.emergencyRed, size: 20),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: AppColors.emergencyRed,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
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
