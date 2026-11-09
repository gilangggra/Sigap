import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman Dasbor Keluarga / Wali (Primary Guardian Dashboard)
/// Menampilkan ringkasan kondisi lansia yang dipantau, riwayat check-in harian,
/// dan jadwal kepatuhan konsumsi obat harian.
class GuardianHomeScreen extends ConsumerWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('SIGAP — Dasbor Wali'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Ganti Peran',
            onPressed: () => context.go('/auth/role'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Status Lansia yang Dipantau
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  border: Border.all(color: AppColors.roleGuardian, width: 2.0),
                ),
                padding: const EdgeInsets.all(AppDimensions.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28.0,
                          backgroundColor: AppColors.roleGuardian.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppColors.roleGuardian, size: 36.0),
                        ),
                        const SizedBox(width: AppDimensions.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ibu Aminah (71 thn)',
                                style: AppTypography.standardHeadline(color: Colors.white),
                              ),
                              Text(
                                'Tinggal di: RT 03 / RW 05',
                                style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.safeGreenDark,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: const Text('Aman', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceLG),
                    const Divider(color: AppColors.darkBorder),
                    const SizedBox(height: AppDimensions.spaceMD),

                    // Detail Check-in Terakhir
                    Row(
                      children: [
                        const Text('😊', style: TextStyle(fontSize: 32.0)),
                        const SizedBox(width: AppDimensions.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check-in Hari Ini (07:45 WIB)',
                                style: AppTypography.standardTitle(color: Colors.white),
                              ),
                              Text(
                                'Menyatakan kondisi baik dan sehat.',
                                style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Pemantauan Jadwal Obat
              Text(
                'Jadwal & Kepatuhan Minum Obat',
                style: AppTypography.standardTitle(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              const _MedicationItemCard(
                medicineName: 'Amlodipine 5mg',
                dosage: '1 tablet sesudah makan',
                scheduledTime: 'Pagi (08:00 WIB)',
                isTaken: true,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              const _MedicationItemCard(
                medicineName: 'Metformin 500mg',
                dosage: '1 tablet bersama makan siang',
                scheduledTime: 'Siang (12:30 WIB)',
                isTaken: false,
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              AccessibleButton(
                label: 'Buat Tiket Bantuan Mikro untuk Lansia',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Form pembuatan bantuan mikro siap dibuka')),
                  );
                },
                backgroundColor: AppColors.roleGuardian,
                icon: Icons.add_task_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicationItemCard extends StatelessWidget {
  final String medicineName;
  final String dosage;
  final String scheduledTime;
  final bool isTaken;

  const _MedicationItemCard({
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: isTaken ? AppColors.safeGreenDark : AppColors.darkBorder,
        ),
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Row(
        children: [
          Icon(
            isTaken ? Icons.check_circle_rounded : Icons.alarm_rounded,
            color: isTaken ? AppColors.safeGreenLight : AppColors.warningAmber,
            size: 32.0,
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicineName, style: AppTypography.standardTitle(color: Colors.white)),
                Text(dosage, style: AppTypography.standardBody(color: AppColors.textDarkSecondary)),
                Text(scheduledTime, style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isTaken ? AppColors.safeGreenDark : AppColors.darkSurfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Text(
              isTaken ? 'Sudah Diminum' : 'Menunggu',
              style: TextStyle(
                color: isTaken ? Colors.white : AppColors.warningAmberLight,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

