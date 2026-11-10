import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';

/// Halaman pemilihan peran (Role-Based Onboarding)
/// Mengimplementasikan sistem desain Healthcare Teal & Mint dengan kartu permukaan putih halus.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _selectRole(BuildContext context, UserRole role) {
    FeedbackService.instance.triggerSuccessFeedback();
    context.read<AuthProvider>().selectRole(role);

    if (role == UserRole.civicAdmin) {
      context.go('/admin');
    } else {
      context.go('/auth/rt-code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: const Text('Pilih Peran Anda'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLG, vertical: AppDimensions.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Peran dalam Komunitas',
                style: AppTypography.seniorHeadingMedium(color: AppColors.textDarkPrimary),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                'Pilih peran Anda untuk menyesuaikan tata letak dan fitur yang paling relevan.',
                style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceLG),

              // Kartu Peran 1: Care-Receiver
              _RoleCard(
                title: 'Penerima Bantuan (Lansia)',
                description: 'Antarmuka tombol besar, SOS satu ketukan, dan pengingat kondisi harian.',
                icon: Icons.elderly_rounded,
                accentColor: AppColors.primaryTeal,
                onTap: () => _selectRole(context, UserRole.careReceiver),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Kartu Peran 2: Responder
              _RoleCard(
                title: 'Relawan Warga',
                description: 'Klaim insiden darurat terdekat, navigasi cepat ke lokasi, dan bantu tugas tetangga.',
                icon: Icons.volunteer_activism_rounded,
                accentColor: AppColors.roleResponder,
                onTap: () => _selectRole(context, UserRole.responder),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Kartu Peran 3: Guardian
              _RoleCard(
                title: 'Keluarga / Wali',
                description: 'Pantau check-in kesehatan harian lansia, jadwal obat, dan terima notifikasi darurat.',
                icon: Icons.family_restroom_rounded,
                accentColor: AppColors.roleGuardian,
                onTap: () => _selectRole(context, UserRole.guardian),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Kartu Peran 4: Civic Admin
              _RoleCard(
                title: 'Pengurus RT/RW',
                description: 'Validasi identitas warga, kelola kode undangan lingkungan, dan rekap laporan.',
                icon: Icons.admin_panel_settings_rounded,
                accentColor: AppColors.roleAdmin,
                onTap: () => _selectRole(context, UserRole.civicAdmin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: const BorderSide(
          color: AppColors.mintBorder,
          width: 1.5,
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.seniorRecommendedTouchTarget,
          ),
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Row(
            children: [
              Container(
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 32.0),
              ),
              const SizedBox(width: AppDimensions.spaceLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      description,
                      style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textDarkTertiary,
                size: 20.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
