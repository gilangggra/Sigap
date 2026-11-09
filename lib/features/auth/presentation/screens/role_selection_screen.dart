import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/theme/app_typography.dart';

/// Halaman pemilihan peran (Role-Based Onboarding)
class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  void _selectRole(BuildContext context, WidgetRef ref, UserRole role) {
    ref.read(authStateProvider.notifier).setRole(role);

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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Pilih Peran Anda'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Peran dalam Komunitas',
                style: AppTypography.seniorHeadingMedium(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Pilih peran Anda untuk menyesuaikan tata letak dan fitur yang paling relevan.',
                style: AppTypography.seniorBodyPrimary(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Kartu Peran 1: Care-Receiver
              _RoleCard(
                title: 'Penerima Bantuan (Lansia)',
                description: 'Antarmuka tombol besar, SOS satu ketukan, dan pengingat kondisi harian.',
                icon: Icons.elderly_rounded,
                accentColor: AppColors.roleCareReceiver,
                onTap: () => _selectRole(context, ref, UserRole.careReceiver),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Kartu Peran 2: Responder
              _RoleCard(
                title: 'Relawan Warga',
                description: 'Klaim insiden darurat terdekat, navigasi cepat ke lokasi, dan bantu tugas tetangga.',
                icon: Icons.volunteer_activism_rounded,
                accentColor: AppColors.roleResponder,
                onTap: () => _selectRole(context, ref, UserRole.responder),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Kartu Peran 3: Guardian
              _RoleCard(
                title: 'Keluarga / Wali',
                description: 'Pantau check-in kesehatan harian lansia, jadwal obat, dan terima notifikasi darurat.',
                icon: Icons.family_restroom_rounded,
                accentColor: AppColors.roleGuardian,
                onTap: () => _selectRole(context, ref, UserRole.guardian),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Kartu Peran 4: Civic Admin
              _RoleCard(
                title: 'Pengurus RT/RW',
                description: 'Validasi identitas warga, kelola kode undangan lingkungan, dan rekap laporan.',
                icon: Icons.admin_panel_settings_rounded,
                accentColor: AppColors.roleAdmin,
                onTap: () => _selectRole(context, ref, UserRole.civicAdmin),
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
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: const BorderSide(
          color: AppColors.darkBorderHighContrast,
          width: AppDimensions.highContrastBorderWidth,
        ),
      ),
      elevation: AppDimensions.elevationLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Row(
            children: [
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2.0),
                ),
                child: Icon(icon, color: accentColor, size: 30.0),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.seniorTitle(color: Colors.white),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      description,
                      style: AppTypography.seniorBodySecondary(color: AppColors.textDarkSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 22.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

