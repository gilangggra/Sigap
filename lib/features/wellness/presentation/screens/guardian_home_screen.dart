import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../state/wellness_provider.dart';

/// Halaman Dasbor Keluarga / Wali (Primary Guardian Dashboard)
/// Menampilkan ringkasan kondisi lansia yang dipantau dengan tata letak standar mobile dan font Poppins.
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  static const String _defaultMonitoredId = 'care-receiver-001';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    if (!mounted) return;
    context.read<WellnessProvider>().loadTodayWellness(_defaultMonitoredId);
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  @override
  Widget build(BuildContext context) {
    final wellness = context.watch<WellnessProvider>();
    final todayCheckin = wellness.todayCheckin;
    final hasCheckedIn = todayCheckin?.status != null;
    final checkinStatus = todayCheckin?.status;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('SIGAP — Dasbor Wali'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil Saya',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Ganti Peran',
            onPressed: () => context.go('/auth/role'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchData(),
          color: AppColors.roleGuardian,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMD,
              vertical: AppDimensions.spaceSM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kartu Profil Lansia Yang Dipantau
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(
                      color: hasCheckedIn ? AppColors.safeGreen : AppColors.lightBorder,
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 8.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26.0,
                            backgroundColor: AppColors.roleGuardian.withValues(alpha: 0.15),
                            child: const Icon(Icons.person, color: AppColors.roleGuardian, size: 30.0),
                          ),
                          const SizedBox(width: AppDimensions.spaceMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ibu Aminah (71 thn)',
                                  style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
                                ),
                                Text(
                                  'Domisili: RT 03 / RW 05 • Hubungan: Ibu Kandung',
                                  style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasCheckedIn ? AppColors.safeGreen.withValues(alpha: 0.15) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            ),
                            child: Text(
                              hasCheckedIn ? 'Aman' : 'Menunggu',
                              style: TextStyle(
                                color: hasCheckedIn ? AppColors.safeGreenDark : AppColors.warningAmberDark,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      const Divider(color: AppColors.lightBorder),
                      const SizedBox(height: AppDimensions.spaceMD),

                      // Status Check-in Harian
                      if (hasCheckedIn) ...[
                        Row(
                          children: [
                            Text(
                              checkinStatus?.emoji ?? '😊',
                              style: const TextStyle(fontSize: 30.0),
                            ),
                            const SizedBox(width: AppDimensions.spaceMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-in: ${checkinStatus?.label ?? "Sudah Merespons"}',
                                    style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                                  ),
                                  Text(
                                    'Waktu Respons: ${_formatTime(todayCheckin?.respondedAt ?? todayCheckin?.createdAt)}',
                                    style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen, size: 26.0),
                          ],
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: AppColors.warningAmber,
                              size: 30.0,
                            ),
                            const SizedBox(width: AppDimensions.spaceMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Belum Melakukan Check-in Hari Ini',
                                    style: AppTypography.standardTitle(color: AppColors.warningAmberDark),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    'Status Eskalasi: ${todayCheckin?.escalationStatus.label ?? "Menunggu Check-in"}',
                                    style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Sistem Dead-Man Switch akan mengirimkan notifikasi eskalasi otomatis ke wali dan admin RT jika belum ada konfirmasi.',
                                    style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceLG),

                // Pemantauan Kepatuhan Minum Obat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jadwal & Kepatuhan Obat',
                      style: AppTypography.categoryHeadline(),
                    ),
                    if (wellness.isLoading)
                      const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.roleGuardian),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceSM),

                if (wellness.medicationSchedules.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Center(
                      child: Text(
                        'Belum ada resep obat harian yang tercatat.',
                        style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                      ),
                    ),
                  ),
                ] else ...[
                  ...wellness.medicationSchedules.map((schedule) {
                    final timesStr = schedule.reminderTimes.isNotEmpty
                        ? schedule.reminderTimes.map((t) => '$t WIB').join(', ')
                        : 'Waktu belum diatur';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
                      child: _MedicationItemCard(
                        medicineName: schedule.medicationName,
                        dosage: schedule.dosage,
                        scheduledTime: timesStr,
                        isTaken: schedule.isTakenToday,
                        takenAt: schedule.takenAt,
                      ),
                    );
                  }),
                ],

                const SizedBox(height: AppDimensions.spaceMD),

                // Akses Data Medis Darurat (ICE Card)
                AccessibleButton(
                  label: 'Lihat / Perbarui Profil Medis (ICE Card)',
                  onPressed: () => context.push('/profile/ice-card'),
                  backgroundColor: AppColors.primaryTeal,
                  icon: Icons.medical_information_rounded,
                ),

                const SizedBox(height: AppDimensions.spaceSM),

                // Hubungi Kontak Lansia Langsung
                AccessibleButton(
                  label: 'Telepon Lansia (+628123456789)',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungi nomor telepon lansia terdaftar...'),
                        backgroundColor: AppColors.primaryTealDeep,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  backgroundColor: AppColors.cardWhite,
                  textColor: AppColors.textDarkPrimary,
                  borderColor: AppColors.lightBorder,
                  icon: Icons.phone_rounded,
                ),
                const SizedBox(height: AppDimensions.spaceXL),
              ],
            ),
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
  final DateTime? takenAt;

  const _MedicationItemCard({
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    required this.isTaken,
    this.takenAt,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return ' jam $hour:$minute WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isTaken ? AppColors.safeGreen : AppColors.lightBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Row(
        children: [
          Icon(
            isTaken ? Icons.check_circle_rounded : Icons.alarm_rounded,
            color: isTaken ? AppColors.safeGreen : AppColors.warningAmber,
            size: 28.0,
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicineName, style: AppTypography.standardTitle(color: AppColors.textDarkPrimary)),
                Text(dosage, style: AppTypography.standardBody(color: AppColors.textDarkSecondary)),
                Text(
                  'Jadwal: $scheduledTime',
                  style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isTaken ? AppColors.safeGreen.withValues(alpha: 0.15) : AppColors.mintSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Text(
              isTaken ? 'Sudah Diminum${_formatTime(takenAt)}' : 'Menunggu',
              style: TextStyle(
                color: isTaken ? AppColors.safeGreenDark : AppColors.warningAmberDark,
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
