import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../../domain/models/incident.dart';
import '../state/emergency_provider.dart';

/// Halaman Beranda Relawan Warga (Community Responder Dashboard)
/// Menampilkan radar darurat terdekat, tombol klaim insiden ("Saya Meluncur"),
/// dan papan tugas bantuan mikro tetangga dengan sistem desain Healthcare Teal & Mint.
class ResponderHomeScreen extends StatefulWidget {
  const ResponderHomeScreen({super.key});

  @override
  State<ResponderHomeScreen> createState() => _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends State<ResponderHomeScreen> {
  bool _isOnline = true;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _initStandbyTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyIncidents();
    });
  }

  void _initStandbyTracking() {
    if (_isOnline) {
      final responderId = SupabaseService.instance.currentUser?.id ?? 'mock-responder';
      unawaited(LocationService.instance.startStandbyTracking(responderId: responderId));
    }
  }

  void _loadNearbyIncidents() {
    final position = LocationService.instance.currentPosition;
    final lat = position?.latitude ?? -6.2088;
    final lng = position?.longitude ?? 106.8456;
    context.read<EmergencyProvider>().loadNearbyIncidents(latitude: lat, longitude: lng);
  }

  @override
  void dispose() {
    final responderId = SupabaseService.instance.currentUser?.id ?? 'mock-responder';
    unawaited(LocationService.instance.stopStandbyTracking(responderId: responderId, clearCloudLocation: false));
    super.dispose();
  }

  Future<void> _claimIncident(Incident incident) async {
    final authProvider = context.read<AuthProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();
    final responderId = authProvider.userId ?? 'responder-001';

    setState(() => _isClaiming = true);
    await FeedbackService.instance.triggerSuccessFeedback();

    final success = await emergencyProvider.lockIncident(
      incidentId: incident.id,
      responderId: responderId,
    );

    if (!mounted) return;
    setState(() => _isClaiming = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.safeGreenDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
          content: const Text('Anda berhasil mengunci insiden! Peta navigasi diaktifkan.'),
        ),
      );
      unawaited(context.push('/emergency/incident-detail', extra: incident));
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();
    final auth = context.watch<AuthProvider>();
    final activeIncidents = emergencyProvider.nearbyIncidents;
    final currentPos = LocationService.instance.currentPosition;
    final currentLat = currentPos?.latitude ?? -6.2088;
    final currentLng = currentPos?.longitude ?? 106.8456;
    final responderName = auth.fullName ?? 'Relawan Siaga';

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 1. Signature Curved Teal Header (Sesuai Desain Healthcare)
            // =================================================================
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + AppDimensions.spaceMD,
                left: AppDimensions.spaceLG,
                right: AppDimensions.spaceLG,
                bottom: AppDimensions.spaceXL,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryTeal, AppColors.primaryTealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppDimensions.radiusHeader),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44.0,
                            height: 44.0,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 24.0),
                          ),
                          const SizedBox(width: AppDimensions.spaceSM),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            ),
                            child: Text(
                              'Relawan Warga RT',
                              style: AppTypography.standardCaption(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Toggle Status Siaga Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.white : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _isOnline ? 'Siaga' : 'Istirahat',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: _isOnline ? AppColors.primaryTealDark : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Switch(
                                  value: _isOnline,
                                  activeColor: AppColors.primaryTeal,
                                  activeTrackColor: AppColors.primaryTealLight,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) {
                                    setState(() => _isOnline = val);
                                    unawaited(FeedbackService.instance.triggerSuccessFeedback());
                                    final responderId = SupabaseService.instance.currentUser?.id ?? 'mock-responder';
                                    if (val) {
                                      unawaited(LocationService.instance.startStandbyTracking(responderId: responderId));
                                    } else {
                                      unawaited(LocationService.instance.stopStandbyTracking(responderId: responderId));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28.0),
                            tooltip: 'Ganti Peran',
                            onPressed: () => context.go('/auth/role'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Text(
                    'Halo, Relawan!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    responderName,
                    style: AppTypography.seniorHeadingLarge(color: Colors.white),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Floating Pill Radar Status Bar
                  ValueListenableBuilder<Position?>(
                    valueListenable: LocationService.instance.standbyPositionNotifier,
                    builder: (context, position, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceMD,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 16.0,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isOnline ? Icons.radar_rounded : Icons.location_off_rounded,
                              color: _isOnline ? AppColors.primaryTeal : AppColors.textDarkTertiary,
                              size: 22.0,
                            ),
                            const SizedBox(width: AppDimensions.spaceSM),
                            Expanded(
                              child: Text(
                                _isOnline
                                    ? position != null
                                        ? 'Radar Siaga Aktif • GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'
                                        : 'Radar Siaga Aktif • Menghubungkan satelit GPS...'
                                    : 'Mode Istirahat • Lokasi tidak dibagikan (Privasi Terjaga)',
                                style: AppTypography.standardCaption(
                                  color: _isOnline ? AppColors.textDarkPrimary : AppColors.textDarkSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // =================================================================
            // 2. Konten Dashboard Relawan Pada Kanvas Mint
            // =================================================================
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Insiden Darurat Aktif (Paling Kritis)
                  if (activeIncidents.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceXL),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.mintBorder, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 16.0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTealLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, color: AppColors.primaryTealDark, size: 48.0),
                          ),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Text(
                            'STATUS SIAGA: LINGKUNGAN AMAN',
                            style: AppTypography.standardHeadline(color: AppColors.primaryTealDeep),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spaceSM),
                          Text(
                            'Tidak ada panggilan darurat aktif dalam radius 500m. Mode Siaga tetap memantau sinyal darurat warga sekitar secara real-time.',
                            style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...activeIncidents.map((inc) {
                      final double distMeters = LocationService.instance.calculateDistanceMeters(
                        startLatitude: currentLat,
                        startLongitude: currentLng,
                        endLatitude: inc.latitude,
                        endLongitude: inc.longitude,
                      );
                      final String distStr = LocationService.instance.formatDistance(distMeters);
                      final bool isLockedByMe = emergencyProvider.lockedIncidentId == inc.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                          border: Border.all(color: AppColors.emergencyRed, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.emergencyRedGlow,
                              blurRadius: 20.0,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(AppDimensions.spaceLG),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: const BoxDecoration(
                                    color: AppColors.emergencyRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24.0),
                                ),
                                const SizedBox(width: AppDimensions.spaceSM),
                                const Expanded(
                                  child: Text(
                                    'PANGGILAN DARURAT (500M)',
                                    style: TextStyle(
                                      color: AppColors.emergencyRed,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.0,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spaceMD),
                            Text(
                              inc.careReceiverName ?? 'Lansia SIGAP',
                              style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                            ),
                            const SizedBox(height: AppDimensions.spaceXS),
                            Text(
                              'Lokasi: ${inc.address ?? "Koordinat (${inc.latitude.toStringAsFixed(4)}, ${inc.longitude.toStringAsFixed(4)})"}',
                              style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                            ),
                            Text(
                              'Jarak: $distStr • Status: ${inc.status.label}',
                              style: const TextStyle(
                                color: AppColors.warningAmberDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceLG),

                            if (!isLockedByMe) ...[
                              AccessibleButton(
                                label: _isClaiming ? 'Mengunci Insiden...' : 'SAYA MELUNCUR (RESPON)',
                                onPressed: _isOnline && !_isClaiming ? () => _claimIncident(inc) : null,
                                backgroundColor: AppColors.emergencyRed,
                                textColor: Colors.white,
                                icon: Icons.navigation_rounded,
                              ),
                              const SizedBox(height: AppDimensions.spaceSM),
                              AccessibleButton(
                                label: 'Lihat Detail & Navigasi Peta',
                                onPressed: () => context.push('/emergency/incident-detail', extra: inc),
                                backgroundColor: AppColors.mintSurface,
                                borderColor: AppColors.mintBorder,
                                textColor: AppColors.textDarkPrimary,
                                icon: Icons.map_rounded,
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(AppDimensions.spaceSM),
                                decoration: BoxDecoration(
                                  color: AppColors.safeGreenDark,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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
                                onPressed: () => context.push('/emergency/incident-detail', extra: inc),
                                backgroundColor: AppColors.primaryTeal,
                                icon: Icons.navigation_rounded,
                              ),
                              const SizedBox(height: AppDimensions.spaceSM),
                              AccessibleButton(
                                label: 'Lihat Data Medis (ICE Card 2 Jam)',
                                onPressed: () => context.push(
                                  '/profile/ice-card-view',
                                  extra: 'EMERGENCY-TOKEN-${inc.id}',
                                ),
                                backgroundColor: AppColors.mintSurface,
                                borderColor: AppColors.mintBorder,
                                textColor: AppColors.primaryTealDark,
                                icon: Icons.medical_services_outlined,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: AppDimensions.spaceXL),

                  // =============================================================
                  // Papan Tugas Bantuan Mikro Sekitar
                  // =============================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tugas Bantuan Mikro',
                        style: AppTypography.categoryHeadline(),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/tasks'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryTealDark),
                        label: const Text(
                          'Lihat Semua',
                          style: TextStyle(color: AppColors.primaryTealDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),

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
                          backgroundColor: AppColors.cardWhite,
                          textColor: AppColors.primaryTealDark,
                          borderColor: AppColors.mintBorder,
                          icon: Icons.radar_rounded,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: AccessibleButton(
                          label: 'Peringkat Relawan RT',
                          onPressed: () => context.push('/tasks/leaderboard'),
                          backgroundColor: AppColors.cardWhite,
                          textColor: AppColors.warningAmberDark,
                          borderColor: AppColors.mintBorder,
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
                      final testIncidentId = activeIncidents.isNotEmpty ? activeIncidents.first.id : 'inc-demo-test';
                      final testVictimName = activeIncidents.isNotEmpty
                          ? (activeIncidents.first.careReceiverName ?? 'Warga SIGAP')
                          : 'Ibu Aminah (Uji Notifikasi)';
                      final testAddress = activeIncidents.isNotEmpty
                          ? (activeIncidents.first.address ?? 'RT 03 / RW 05')
                          : 'Jl. Kenanga No. 14, RT 03';

                      unawaited(
                        NotificationService.instance.showEmergencyAlert(
                          incidentId: testIncidentId,
                          victimName: testVictimName,
                          address: testAddress,
                          distanceMeters: 320,
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.emergencyRedDark,
                          behavior: SnackBarBehavior.floating,
                          content: Text('Notifikasi darurat SOS terkirim ke panel notifikasi HP Anda.'),
                        ),
                      );
                    },
                    backgroundColor: AppColors.mintSurface,
                    textColor: AppColors.emergencyRed,
                    borderColor: AppColors.emergencyRedLight,
                    icon: Icons.notifications_active_rounded,
                  ),
                  const SizedBox(height: AppDimensions.spaceXL),
                ],
              ),
            ),
          ],
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
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.mintBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceSM + 2),
            decoration: BoxDecoration(
              color: AppColors.primaryTealLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(icon, color: AppColors.primaryTealDark, size: 26.0),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: AppTypography.standardTitle(color: AppColors.textDarkPrimary)),
                const SizedBox(height: 2),
                Text(targetPerson, style: AppTypography.standardBody(color: AppColors.textDarkSecondary)),
                Text(address, style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              unawaited(FeedbackService.instance.triggerSuccessFeedback());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Tugas "$category" berhasil diambil'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            ),
            child: const Text('Bantu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
