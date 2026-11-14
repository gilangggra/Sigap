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
import '../../../wellness/presentation/state/wellness_provider.dart';
import '../../domain/models/incident.dart';
import '../state/emergency_provider.dart';

/// Halaman Beranda Warga Siaga (Unified Resident Dashboard).
/// Mengintegrasikan kesiapsiagaan darurat tetangga (Responder),
/// pemantauan keluarga lansia (Guardian), dan akses administrasi RT (Civic Admin)
/// dalam satu antarmuka mobile yang bersih, elegan, dan tanpa gesekan peran.
class ResidentHomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const ResidentHomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  late int _selectedTab;
  bool _isOnline = true;
  bool _isClaiming = false;
  static const String _defaultMonitoredId = AppConstants.demoUserId;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _initStandbyTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _initStandbyTracking() {
    if (_isOnline) {
      final responderId = SupabaseService.instance.currentUser?.id ?? AppConstants.demoUserId;
      unawaited(LocationService.instance.startStandbyTracking(responderId: responderId));
    }
  }

  void _loadDashboardData() {
    final position = LocationService.instance.currentPosition;
    final lat = position?.latitude ?? -6.2088;
    final lng = position?.longitude ?? 106.8456;
    context.read<EmergencyProvider>().loadNearbyIncidents(latitude: lat, longitude: lng);
    context.read<WellnessProvider>().loadTodayWellness(_defaultMonitoredId);
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
          content: const Text('Anda berhasil merespons insiden! Peta rute aktif.'),
        ),
      );
      unawaited(context.push('/emergency/incident-detail', extra: incident));
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  void _showAddMedicationSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 tablet sesudah makan');
    final timeCtrl = TextEditingController(text: '08:00');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLG)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.spaceMD,
            right: AppDimensions.spaceMD,
            top: AppDimensions.spaceMD,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.spaceMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Atur Jadwal Obat Orang Tua',
                    style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20.0),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              Text(
                'Jadwal obat ini akan langsung muncul di HP orang tua dengan tombol konfirmasi satu sentuhan.',
                style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 14.0, color: AppColors.textDarkPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Obat',
                  hintText: 'Contoh: Amlodipine 5mg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              TextField(
                controller: dosageCtrl,
                style: const TextStyle(fontSize: 14.0, color: AppColors.textDarkPrimary),
                decoration: InputDecoration(
                  labelText: 'Dosis / Aturan Pakai',
                  hintText: 'Contoh: 1 tablet setelah sarapan pagi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              TextField(
                controller: timeCtrl,
                style: const TextStyle(fontSize: 14.0, color: AppColors.textDarkPrimary),
                decoration: InputDecoration(
                  labelText: 'Jam Pengingat (WIB)',
                  hintText: 'Contoh: 08:00',
                  suffixIcon: const Icon(Icons.access_time_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              AccessibleButton(
                label: 'Simpan Jadwal Obat',
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final wellness = context.read<WellnessProvider>();
                  Navigator.of(ctx).pop();

                  final success = await wellness.addMedicationSchedule(
                    careReceiverId: _defaultMonitoredId,
                    medicationName: nameCtrl.text.trim(),
                    dosage: dosageCtrl.text.trim(),
                    reminderTimes: [timeCtrl.text.trim()],
                  );
                  if (mounted && success) {
                    unawaited(FeedbackService.instance.triggerSuccessFeedback());
                    messenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.safeGreenDark,
                        behavior: SnackBarBehavior.floating,
                        content: Text('Jadwal obat berhasil ditambahkan dan tersinkron ke HP orang tua.'),
                      ),
                    );
                  }
                },
                backgroundColor: AppColors.primaryTeal,
                icon: Icons.check_rounded,
                isSimplified: false,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();
    final wellness = context.watch<WellnessProvider>();
    final auth = context.watch<AuthProvider>();
    final activeIncidents = emergencyProvider.nearbyIncidents;
    final currentPos = LocationService.instance.currentPosition;
    final currentLat = currentPos?.latitude ?? -6.2088;
    final currentLng = currentPos?.longitude ?? 106.8456;
    final residentName = auth.fullName ?? 'Warga Siaga';
    final isCivicAdmin = auth.role == UserRole.civicAdmin || (auth.userProfile?.isCivicAdmin ?? false);

    final todayCheckin = wellness.todayCheckin;
    final hasCheckedIn = todayCheckin?.status != null;
    final checkinStatus = todayCheckin?.status;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // =============================================================
          // 1. Header Banner Warga Siaga
          // =============================================================
          AppHeaderBanner(
            title: 'Halo, $residentName',
            subtitle: isCivicAdmin
                ? 'Pengurus RT • Lingkungan Siaga RT 03'
                : 'Keluarga & Relawan Lingkungan RT',
            leading: AppAvatar(
              name: residentName,
              radius: 22.0,
              isOnline: _isOnline,
              showBadge: true,
              borderColor: Colors.white,
            ),
            actions: [
              if (isCivicAdmin)
                _HeaderIconButton(
                  icon: Icons.admin_panel_settings_rounded,
                  tooltip: 'Panel Pengurus RT',
                  onTap: () => context.push('/admin'),
                ),
              _HeaderIconButton(
                icon: Icons.person_outline_rounded,
                tooltip: 'Profil Saya',
                onTap: () => context.push('/profile'),
              ),
              const SizedBox(width: 4.0),
              _HeaderIconButton(
                icon: Icons.swap_horiz_rounded,
                tooltip: 'Ganti Tampilan (Mode Lansia)',
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
                AppBadge.brand(
                  isCivicAdmin ? 'Pengurus Lingkungan' : 'Warga Siaga',
                  icon: isCivicAdmin ? Icons.shield_rounded : Icons.volunteer_activism_rounded,
                ),
              ],
            ),
          ),

          // =============================================================
          // 2. Segmented Navigation Bar (Lingkungan RT vs Keluarga Saya)
          // =============================================================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMD, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentTabButton(
                    label: 'Lingkungan RT',
                    icon: Icons.radar_rounded,
                    isSelected: _selectedTab == 0,
                    badgeCount: activeIncidents.isNotEmpty ? activeIncidents.length : null,
                    onTap: () {
                      FeedbackService.instance.triggerSuccessFeedback();
                      setState(() => _selectedTab = 0);
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceSM),
                Expanded(
                  child: _SegmentTabButton(
                    label: 'Keluarga Saya',
                    icon: Icons.family_restroom_rounded,
                    isSelected: _selectedTab == 1,
                    onTap: () {
                      FeedbackService.instance.triggerSuccessFeedback();
                      setState(() => _selectedTab = 1);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0, color: AppColors.lightBorder),

          // =============================================================
          // 3. Konten Utama
          // =============================================================
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadDashboardData(),
              color: AppColors.primaryTeal,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceMD,
                  vertical: AppDimensions.spaceMD,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. PANGGILAN DARURAT AKTIF (Selalu Muncul Jika Ada Insiden P0)
                    if (activeIncidents.isNotEmpty) ...[
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
                              ],
                            ],
                          ),
                        );
                      }),
                    ],

                    // B. KONTEN BERDASARKAN TAB AKTIF
                    if (_selectedTab == 0) ...[
                      // ---------------------------------------------------------
                      // TAB 0: LINGKUNGAN RT
                      // ---------------------------------------------------------
                      // 1. Status Radar Hyperlocal
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
                                        _isOnline ? 'Radar Hyperlocal Siaga' : 'GPS Dinonaktifkan',
                                        style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                                      ),
                                      Text(
                                        _isOnline
                                            ? 'Memantau radius 500m dari koordinat Anda secara real-time.'
                                            : 'Mode Istirahat • Lokasi tidak dibagikan (Privasi terjaga).',
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

                      if (activeIncidents.isEmpty) ...[
                        const SizedBox(height: AppDimensions.spaceMD),
                        AppCard(
                          padding: const EdgeInsets.all(AppDimensions.spaceMD),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: const BoxDecoration(
                                  color: AppColors.safeGreenWash,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_rounded, color: AppColors.safeGreenDark, size: 24.0),
                              ),
                              const SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lingkungan RT Kondusif & Aman',
                                      style: AppTypography.standardTitle(color: AppColors.safeGreenDark),
                                    ),
                                    Text(
                                      'Tidak ada panggilan darurat aktif dalam radius sekitar.',
                                      style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Banner Akses Cepat Pengurus RT (Khusus Admin)
                      if (isCivicAdmin) ...[
                        const SizedBox(height: AppDimensions.spaceMD),
                        AppCard(
                          onTap: () => context.push('/admin'),
                          backgroundColor: AppColors.cardWhite,
                          border: Border.all(color: AppColors.roleAdmin.withValues(alpha: 0.4)),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.roleAdmin.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.roleAdmin, size: 22.0),
                              ),
                              const SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Panel Administrasi Lingkungan RT',
                                      style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                                    ),
                                    Text(
                                      'Kelola verifikasi warga baru dan kode domisili lingkungan.',
                                      style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16.0, color: AppColors.textDarkTertiary),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppDimensions.spaceLG),

                      // Papan Gotong Royong Warga
                      AppSectionHeader(
                        title: 'Gotong Royong Warga',
                        subtitle: 'Bantu kebutuhan harian tetangga sekitar',
                        actionLabel: 'Lihat Semua',
                        onActionTap: () => context.push('/tasks'),
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),

                      const _TaskPreviewCard(
                        category: 'Ambil Resep Obat',
                        targetPerson: 'Bapak Hartono (68 thn)',
                        address: 'Jl. Melati RT 02 / RW 05 (450m)',
                        tag: 'Butuh Hari Ini',
                        icon: Icons.medication_liquid_rounded,
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      const _TaskPreviewCard(
                        category: 'Belanja Kebutuhan Pokok',
                        targetPerson: 'Ibu Sutrisno (74 thn)',
                        address: 'Jl. Dahlia RT 01 / RW 05 (600m)',
                        tag: 'Kebutuhan Dapur',
                        icon: Icons.shopping_basket_rounded,
                      ),

                      const SizedBox(height: AppDimensions.spaceMD),

                      Row(
                        children: [
                          Expanded(
                            child: AccessibleButton(
                              label: 'Papan Gotong Royong',
                              onPressed: () => context.push('/tasks'),
                              backgroundColor: AppColors.cardWhite,
                              textColor: AppColors.primaryTealDark,
                              borderColor: AppColors.lightBorder,
                              icon: Icons.handshake_outlined,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceMD),
                          Expanded(
                            child: AccessibleButton(
                              label: 'Solidaritas RT',
                              onPressed: () => context.push('/tasks/impact'),
                              backgroundColor: AppColors.cardWhite,
                              textColor: AppColors.roleGuardian,
                              borderColor: AppColors.lightBorder,
                              icon: Icons.volunteer_activism_outlined,
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
                    ] else ...[
                      // ---------------------------------------------------------
                      // TAB 1: KELUARGA SAYA
                      // ---------------------------------------------------------
                      // Kartu Lansia Keluarga yang Dipantau
                      AppCard(
                        border: hasCheckedIn
                            ? Border.all(color: AppColors.safeGreen, width: 1.5)
                            : AppBorders.standard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const AppAvatar(
                                  name: 'Ibu Aminah',
                                  radius: 24.0,
                                  borderColor: AppColors.primaryTeal,
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
                                if (hasCheckedIn)
                                  AppBadge.success('Aman', isSmall: true)
                                else
                                  AppBadge.warning('Menunggu', isSmall: true),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spaceMD),
                            const Divider(color: AppColors.lightBorder),
                            const SizedBox(height: AppDimensions.spaceSM),

                            // Sapaan Pagi / Check-in Hari Ini
                            if (hasCheckedIn) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 40.0,
                                    height: 40.0,
                                    decoration: const BoxDecoration(
                                      color: AppColors.safeGreenWash,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      checkinStatus?.emoji ?? '😊',
                                      style: const TextStyle(fontSize: 22.0),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.spaceMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sapaan Pagi: ${checkinStatus?.label ?? "Kondisi Baik"}',
                                          style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                                        ),
                                        Text(
                                          'Waktu Konfirmasi: ${_formatTime(todayCheckin?.respondedAt ?? todayCheckin?.createdAt)}',
                                          style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen, size: 22.0),
                                ],
                              ),
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: const BoxDecoration(
                                      color: AppColors.warningAmberWash,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.schedule_rounded,
                                      color: AppColors.warningAmber,
                                      size: 20.0,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.spaceMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Belum Mengirim Sapaan Pagi',
                                          style: AppTypography.standardTitle(color: AppColors.warningAmberDark),
                                        ),
                                        const SizedBox(height: 2.0),
                                        Text(
                                          'Pengingat ramah otomatis terkirim jika hingga jam 10:30 WIB belum ada respons.',
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

                      // Jadwal & Kepatuhan Minum Obat
                      AppSectionHeader(
                        title: 'Jadwal & Kepatuhan Obat',
                        subtitle: 'Pantau riwayat obat harian Ibu Aminah',
                        actionLabel: '+ Tambah Resep',
                        onActionTap: () => _showAddMedicationSheet(context),
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),

                      if (wellness.medicationSchedules.isEmpty) ...[
                        AppEmptyState(
                          icon: Icons.medication_rounded,
                          title: 'Belum Ada Jadwal Obat',
                          description: 'Tambahkan jadwal obat harian untuk memantau kepatuhan minum obat orang tua.',
                          actionLabel: 'Tambah Resep Obat',
                          onActionPressed: () => _showAddMedicationSheet(context),
                        ),
                      ] else ...[
                        ...wellness.medicationSchedules.map((schedule) {
                          final timesStr = schedule.reminderTimes.isNotEmpty
                              ? schedule.reminderTimes.map((t) => '$t WIB').join(', ')
                              : 'Waktu belum diatur';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
                            child: _ResidentMedicationItemCard(
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

                      // Tindakan Terkait Lansia Keluarga
                      Row(
                        children: [
                          Expanded(
                            child: AccessibleButton(
                              label: 'Kartu Medis (ICE)',
                              onPressed: () => context.push('/profile/ice-card-view'),
                              backgroundColor: AppColors.primaryTeal,
                              textColor: Colors.white,
                              icon: Icons.medical_information_rounded,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceMD),
                          Expanded(
                            child: AccessibleButton(
                              label: 'Telepon Ibu',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Menghubungi telepon Ibu Aminah...'),
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
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppDimensions.spaceXL),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol segmen tab atas (Lingkungan vs Keluarga)
class _SegmentTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _SegmentTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: isSelected ? AppColors.primaryTealDark : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textDarkSecondary,
              size: 18.0,
            ),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDarkPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.0,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: const BoxDecoration(
                  color: AppColors.emergencyRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
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

class _TaskPreviewCard extends StatelessWidget {
  final String category;
  final String targetPerson;
  final String address;
  final String tag;
  final IconData icon;

  const _TaskPreviewCard({
    required this.category,
    required this.targetPerson,
    required this.address,
    required this.tag,
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
            child: Icon(icon, color: AppColors.primaryTealDark, size: 20.0),
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
                    AppBadge.neutral(tag, isSmall: true),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(targetPerson, style: AppTypography.standardBody(color: AppColors.textDarkSecondary)),
                Text(address, style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          ElevatedButton(
            onPressed: () => context.push('/tasks'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
            ),
            child: const Text('Bantu', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ResidentMedicationItemCard extends StatelessWidget {
  final String medicineName;
  final String dosage;
  final String scheduledTime;
  final bool isTaken;
  final DateTime? takenAt;

  const _ResidentMedicationItemCard({
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
    return AppCard(
      border: isTaken
          ? Border.all(color: AppColors.safeGreen, width: 1.0)
          : AppBorders.standard,
      backgroundColor: isTaken ? AppColors.safeGreenWash : AppColors.cardWhite,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isTaken ? AppColors.safeGreenLight.withValues(alpha: 0.3) : AppColors.warningAmberWash,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTaken ? Icons.check_circle_rounded : Icons.alarm_rounded,
              color: isTaken ? AppColors.safeGreenDark : AppColors.warningAmber,
              size: 20.0,
            ),
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
          if (isTaken)
            AppBadge.success('Diminum${_formatTime(takenAt)}', isSmall: true)
          else
            AppBadge.warning('Menunggu', isSmall: true),
        ],
      ),
    );
  }
}
