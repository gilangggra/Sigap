import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/components.dart';
import '../../domain/models/incident.dart';
import '../state/emergency_provider.dart';

/// Halaman Beranda Relawan Warga (Community Responder Dashboard)
/// Menampilkan radar darurat terdekat, tombol klaim insiden ("Saya Meluncur"),
/// dan papan tugas bantuan mikro tetangga dengan standar tata letak mobile dan font Poppins.
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
      final responderId = SupabaseService.instance.currentUser?.id ?? AppConstants.demoUserId;
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
    final responderId = SupabaseService.instance.currentUser?.id ?? AppConstants.demoUserId;
    unawaited(LocationService.instance.stopStandbyTracking(responderId: responderId, clearCloudLocation: false));
    super.dispose();
  }

  Future<void> _claimIncident(Incident incident) async {
    final authProvider = context.read<AuthProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();
    final responderId = authProvider.userId ?? AppConstants.demoUserId;

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
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // =============================================================
          // Top Hero Header Banner Khas Mobile Modern
          // =============================================================
          AppHeaderBanner(
            title: 'Halo, $responderName',
            subtitle: 'Pusat Koordinasi Relawan Lingkungan RT',
            leading: AppAvatar(
              name: responderName,
              radius: 22.0,
              isOnline: _isOnline,
              showBadge: true,
              borderColor: Colors.white,
            ),
            actions: [
              _HeaderIconButton(
                icon: Icons.person_outline_rounded,
                tooltip: 'Profil Saya',
                onTap: () => context.push('/profile'),
              ),
              const SizedBox(width: 6.0),
              _HeaderIconButton(
                icon: Icons.swap_horiz_rounded,
                tooltip: 'Ganti Peran',
                onTap: () => context.go('/auth/role'),
              ),
            ],
            bottomSlot: Row(
              children: [
                // Toggle Siaga Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnline ? AppColors.safeGreen : AppColors.textDarkTertiary,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        _isOnline ? 'Siaga Aktif' : 'Mode Istirahat',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: _isOnline ? AppColors.primaryTealDark : AppColors.textDarkSecondary,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: _isOnline,
                          activeColor: AppColors.primaryTeal,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            setState(() => _isOnline = val);
                            unawaited(FeedbackService.instance.triggerSuccessFeedback());
                            final responderId = SupabaseService.instance.currentUser?.id ?? AppConstants.demoUserId;
                            if (val) {
                              unawaited(LocationService.instance.startStandbyTracking(responderId: responderId));
                            } else {
                              unawaited(LocationService.instance.stopStandbyTracking(responderId: responderId));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppBadge.brand('+120 Poin Sosial', icon: Icons.stars_rounded),
              ],
            ),
          ),

          // =============================================================
          // Konten Scrollable
          // =============================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
                vertical: AppDimensions.spaceMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =============================================================
                  // 1. Kartu Status Radar & GPS Siaga Relawan
                  // =============================================================
                  ValueListenableBuilder<Position?>(
                    valueListenable: LocationService.instance.standbyPositionNotifier,
                    builder: (context, position, _) {
                      return AppCard(
                        padding: const EdgeInsets.all(AppDimensions.spaceMD),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: _isOnline ? AppColors.primaryTealLight : AppColors.mintSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isOnline ? Icons.radar_rounded : Icons.location_off_rounded,
                                color: _isOnline ? AppColors.primaryTealDark : AppColors.textDarkTertiary,
                                size: 20.0,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isOnline ? 'Radar Hyperlocal Aktif' : 'GPS Dinonaktifkan',
                                    style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                                  ),
                                  Text(
                                    _isOnline
                                        ? position != null
                                            ? 'Koordinat: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)} (Radius 500m)'
                                            : 'Menghubungkan satelit GPS...'
                                        : 'Mode Istirahat • Lokasi tidak dibagikan (Privasi terjaga)',
                                    style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (_isOnline)
                              const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen, size: 18.0),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppDimensions.spaceMD),

                  // =============================================================
                  // 2. Banner Insiden Darurat Aktif
                  // =============================================================
                  if (activeIncidents.isEmpty) ...[
                    AppCard(
                      padding: const EdgeInsets.all(AppDimensions.spaceLG),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14.0),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTealLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, color: AppColors.primaryTealDark, size: 36.0),
                          ),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Text(
                            'STATUS SIAGA: LINGKUNGAN AMAN',
                            style: AppTypography.standardHeadline(color: AppColors.primaryTealDeep),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spaceXS),
                          Text(
                            'Tidak ada panggilan darurat aktif dalam radius 500m. Radar tetap memantau sinyal darurat warga sekitar secara real-time.',
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

                      return AppCard.emergency(
                        margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppBadge.danger('DARURAT AKTIF', icon: Icons.emergency_rounded),
                                const SizedBox(width: AppDimensions.spaceSM),
                                AppBadge.warning(distStr, icon: Icons.near_me_rounded),
                                const Spacer(),
                                AppBadge.neutral(inc.status.label, isSmall: true),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spaceMD),
                            Text(
                              inc.careReceiverName ?? 'Lansia SIGAP',
                              style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              'Lokasi: ${inc.address ?? "Koordinat (${inc.latitude.toStringAsFixed(4)}, ${inc.longitude.toStringAsFixed(4)})"}',
                              style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                            ),
                            const SizedBox(height: AppDimensions.spaceMD),

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
                                borderColor: AppColors.lightBorder,
                                textColor: AppColors.textDarkPrimary,
                                icon: Icons.map_rounded,
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: AppColors.safeGreenDark,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
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
                                  '/emergency/ice-card-view',
                                  extra: 'EMERGENCY-TOKEN-${inc.id}',
                                ),
                                backgroundColor: AppColors.mintSurface,
                                borderColor: AppColors.lightBorder,
                                textColor: AppColors.primaryTealDark,
                                icon: Icons.medical_services_outlined,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: AppDimensions.spaceLG),

                  // =============================================================
                  // 3. Papan Tugas Bantuan Mikro Sekitar
                  // =============================================================
                  AppSectionHeader(
                    title: 'Tugas Bantuan Mikro',
                    subtitle: 'Bantu tetangga dan kumpulkan poin kebaikan',
                    actionLabel: 'Lihat Semua',
                    onActionTap: () => context.push('/tasks'),
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),

                  const _TaskItemCard(
                    category: 'Ambil Resep Obat',
                    targetPerson: 'Bapak Hartono (68 thn)',
                    address: 'Jl. Melati RT 02 / RW 05 (450m)',
                    points: '+10 Poin',
                    icon: Icons.medication_liquid_rounded,
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),
                  const _TaskItemCard(
                    category: 'Belanja Kebutuhan Pokok',
                    targetPerson: 'Ibu Sutrisno (74 thn)',
                    address: 'Jl. Dahlia RT 01 / RW 05 (600m)',
                    points: '+10 Poin',
                    icon: Icons.shopping_basket_rounded,
                  ),

                  const SizedBox(height: AppDimensions.spaceMD),

                  Row(
                    children: [
                      Expanded(
                        child: AccessibleButton(
                          label: 'Radar Tugas',
                          onPressed: () => context.push('/tasks'),
                          backgroundColor: AppColors.cardWhite,
                          textColor: AppColors.primaryTealDark,
                          borderColor: AppColors.lightBorder,
                          icon: Icons.radar_rounded,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: AccessibleButton(
                          label: 'Peringkat',
                          onPressed: () => context.push('/tasks/leaderboard'),
                          backgroundColor: AppColors.cardWhite,
                          textColor: AppColors.warningAmberDark,
                          borderColor: AppColors.lightBorder,
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
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: Colors.white, size: 20.0),
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
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: const BoxDecoration(
              color: AppColors.primaryTealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryTealDark, size: 22.0),
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
                        category,
                        style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppBadge.brand(points, isSmall: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(targetPerson, style: AppTypography.standardBody(color: AppColors.textDarkSecondary)),
                Text(address, style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
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
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            ),
            child: const Text('Bantu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
