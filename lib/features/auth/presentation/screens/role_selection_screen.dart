import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/components.dart';

/// Halaman Pemilihan Profil Pengguna (Natural Persona Selection).
/// Menyederhanakan peran kaku menjadi pilihan intuitif: Warga Siaga (Keluarga & Relawan) vs Mode Lansia.
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
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        elevation: 0,
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
              Text(
                'Pilih Tipe Tampilan',
                style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
              ),
              const SizedBox(height: 2.0),
              Text(
                'Sesuaikan antarmuka aplikasi dengan kebutuhan Anda atau keluarga.',
                style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Pilihan 1: Warga Siaga Lingkungan (All-in-One: Keluarga + Relawan Tetangga)
              _RoleCard(
                title: 'Warga Siaga Lingkungan',
                subtitleTag: 'Direkomendasikan untuk Warga & Keluarga',
                description:
                    'Antarmuka lengkap: pantau kesehatan orang tua/keluarga tercinta, siaga respons darurat tetangga sekitar, dan saling gotong royong.',
                icon: Icons.groups_rounded,
                accentColor: AppColors.primaryTeal,
                onTap: () => _selectRole(context, UserRole.resident),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Pilihan 2: Mode Khusus Lansia (Penerima Bantuan)
              _RoleCard(
                title: 'Mode Khusus Lansia',
                subtitleTag: 'Antarmuka Sangat Sederhana',
                description:
                    'Tampilan ramah orang tua dengan tombol darurat SOS raksasa, teks kontras tinggi, sapaan pagi harian, dan pengingat obat.',
                icon: Icons.elderly_rounded,
                accentColor: AppColors.safeGreenDark,
                onTap: () => _selectRole(context, UserRole.careReceiver),
              ),
              const SizedBox(height: AppDimensions.spaceLG),

              const Divider(color: AppColors.lightBorder),
              const SizedBox(height: AppDimensions.spaceMD),

              // Pilihan Khusus: Pengurus RT/RW (Aparatur Lingkungan)
              Text(
                'Aparatur Lingkungan RT/RW',
                style: AppTypography.standardTitle(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              _RoleCard(
                title: 'Pengurus RT / RW',
                description:
                    'Masuk sebagai pengurus lingkungan untuk memvalidasi pendaftaran warga baru, mengelola kode RT, dan memantau rekap insiden.',
                icon: Icons.admin_panel_settings_rounded,
                accentColor: AppColors.roleAdmin,
                onTap: () => _selectRole(context, UserRole.civicAdmin),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String? subtitleTag;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    this.subtitleTag,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 24.0),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary).copyWith(
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitleTag != null) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    subtitleTag!,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceXS),
          const Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDarkTertiary,
              size: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}
