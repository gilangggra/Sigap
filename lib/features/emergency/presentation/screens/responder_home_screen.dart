import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman Beranda Relawan Warga (Community Responder Dashboard)
/// Menampilkan radar darurat terdekat, tombol klaim insiden ("Saya Meluncur"),
/// dan papan tugas bantuan mikro tetangga.
class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key});

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  bool _isOnline = true;
  bool _isClaiming = false;
  String? _lockedIncidentId;

  // Mock data insiden aktif terdekat
  final Map<String, dynamic> _activeEmergency = {
    'id': 'inc-001',
    'victimName': 'Ibu Aminah (71 thn)',
    'address': 'Jl. Kenanga No. 14, RT 03 / RW 05',
    'distance': '320 m',
    'timeAgo': '1 menit yang lalu',
    'isLocked': false,
  };

  void _claimIncident() async {
    setState(() {
      _isClaiming = true;
    });

    await FeedbackService.instance.triggerSuccessFeedback();

    if (SupabaseService.instance.isInitialized) {
      final responderId = SupabaseService.instance.currentUser?.id ?? 'mock-responder';
      await SupabaseService.instance.lockIncident(
        incidentId: _activeEmergency['id'] as String,
        responderId: responderId,
      );
    }

    setState(() {
      _isClaiming = false;
      _lockedIncidentId = _activeEmergency['id'] as String;
      _activeEmergency['isLocked'] = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.safeGreenDark,
          content: Text('Anda berhasil mengunci insiden! Peta navigasi diaktifkan.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('SIGAP — Relawan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spaceSM),
            child: Row(
              children: [
                Text(
                  _isOnline ? 'Siaga' : 'Istirahat',
                  style: AppTypography.standardCaption(
                    color: _isOnline ? AppColors.safeGreenLight : AppColors.textDarkTertiary,
                  ),
                ),
                Switch(
                  value: _isOnline,
                  activeColor: AppColors.safeGreenLight,
                  onChanged: (val) {
                    setState(() => _isOnline = val);
                    unawaited(FeedbackService.instance.triggerSuccessFeedback());
                  },
                ),
              ],
            ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Insiden Darurat Aktif (Paling Kritis)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.emergencyRedDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                padding: const EdgeInsets.all(AppDimensions.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: Colors.white, size: 28.0),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Text(
                          'PANGGILAN DARURAT RADIUS 500M',
                          style: AppTypography.standardHeadline(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    Text(
                      _activeEmergency['victimName'] as String,
                      style: AppTypography.seniorTitle(color: Colors.white),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      'Lokasi: ${_activeEmergency['address']}',
                      style: AppTypography.standardBody(color: Colors.white),
                    ),
                    Text(
                      'Jarak: ${_activeEmergency['distance']} • ${_activeEmergency['timeAgo']}',
                      style: AppTypography.standardBody(color: AppColors.warningAmberLight),
                    ),
                    const SizedBox(height: AppDimensions.spaceLG),

                    if (_lockedIncidentId == null) ...[
                      AccessibleButton(
                        label: _isClaiming ? 'Mengunci Insiden...' : 'SAYA MELUNCUR (RESPON)',
                        onPressed: _isOnline && !_isClaiming ? _claimIncident : null,
                        backgroundColor: Colors.white,
                        textColor: AppColors.emergencyRedDark,
                        icon: Icons.navigation_rounded,
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      AccessibleButton(
                        label: 'Lihat Detail & Navigasi Peta',
                        onPressed: () => context.push('/emergency/incident-detail'),
                        backgroundColor: AppColors.darkSurfaceElevated,
                        textColor: Colors.white,
                        icon: Icons.map_rounded,
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spaceSM),
                        decoration: BoxDecoration(
                          color: AppColors.safeGreenDark,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white),
                            SizedBox(width: AppDimensions.spaceSM),
                            Text(
                              'Insiden Sedang Anda Tangani',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      AccessibleButton(
                        label: 'Detail Rute Navigasi & Selesaikan',
                        onPressed: () => context.push('/emergency/incident-detail'),
                        backgroundColor: AppColors.infoBlue,
                        icon: Icons.navigation_rounded,
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      AccessibleButton(
                        label: 'Lihat Data Medis (ICE Card 2 Jam)',
                        onPressed: () => context.push('/emergency/ice-card-view'),
                        backgroundColor: AppColors.darkSurfaceElevated,
                        icon: Icons.medical_services_outlined,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Papan Tugas Bantuan Mikro Sekitar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tugas Bantuan Mikro (Radius 800m)',
                    style: AppTypography.standardTitle(color: Colors.white),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/tasks'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.infoBlueLight),
                    label: const Text('Lihat Semua', style: TextStyle(color: AppColors.infoBlueLight)),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSM),

              const _TaskItemCard(
                category: 'Ambil Resep Obat',
                targetPerson: 'Bapak Hartono (68 thn)',
                address: 'Jl. Melati RT 02 / RW 05 (450m)',
                points: '+10 Poin',
                icon: Icons.medication_liquid_rounded,
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              const _TaskItemCard(
                category: 'Belanja Kebutuhan Pokok',
                targetPerson: 'Ibu Sutrisno (74 thn)',
                address: 'Jl. Dahlia RT 01 / RW 05 (600m)',
                points: '+10 Poin',
                icon: Icons.shopping_basket_rounded,
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              Row(
                children: [
                  Expanded(
                    child: AccessibleButton(
                      label: 'Radar Tugas Lengkap',
                      onPressed: () => context.push('/tasks'),
                      backgroundColor: AppColors.darkCard,
                      textColor: Colors.white,
                      borderColor: AppColors.darkBorderHighContrast,
                      icon: Icons.radar_rounded,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: AccessibleButton(
                      label: 'Peringkat Relawan RT',
                      onPressed: () => context.push('/tasks/leaderboard'),
                      backgroundColor: AppColors.darkCard,
                      textColor: AppColors.warningAmberLight,
                      borderColor: AppColors.warningAmber,
                      icon: Icons.leaderboard_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Uji Notifikasi Alarm SOS
              AccessibleButton(
                label: 'Uji Alarm Notifikasi Darurat (Heads-Up SOS)',
                onPressed: () {
                  unawaited(FeedbackService.instance.triggerSuccessFeedback());
                  unawaited(
                    NotificationService.instance.showEmergencyAlert(
                      incidentId: _activeEmergency['id'] as String,
                      victimName: _activeEmergency['victimName'] as String,
                      address: _activeEmergency['address'] as String,
                      distanceMeters: 320,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.emergencyRedDark,
                      content: Text('Notifikasi darurat SOS terkirim ke panel notifikasi HP Anda.'),
                    ),
                  );
                },
                backgroundColor: AppColors.darkCard,
                textColor: AppColors.emergencyRedLight,
                borderColor: AppColors.emergencyRed,
                icon: Icons.notifications_active_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskItemCard extends StatelessWidget {
  final String category;
  final String targetPerson;
  final String address;
  final String points;
  final IconData icon;

  const _TaskItemCard({
    required this.category,
    required this.targetPerson,
    required this.address,
    required this.points,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceSM),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, color: AppColors.infoBlueLight, size: 28.0),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: AppTypography.standardTitle(color: Colors.white)),
                Text(targetPerson, style: AppTypography.standardBody(color: AppColors.textDarkSecondary)),
                Text(address, style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              unawaited(FeedbackService.instance.triggerSuccessFeedback());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tugas "$category" berhasil diambil')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.infoBlue,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Bantu'),
          ),
        ],
      ),
    );
  }
}
