import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/fall_detection_service.dart';
import '../../../../core/services/safety_check_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../../../wellness/presentation/state/wellness_provider.dart';
import '../state/emergency_provider.dart';
import '../widgets/fall_alert_dialog.dart';
import '../widgets/safety_check_alert_dialog.dart';
import '../widgets/safety_check_card.dart';

/// Halaman Beranda Care-Receiver (Antarmuka Khusus Lansia / Simplified Mode)
/// Diperbarui dengan Sistem Desain Healthcare Modern (Teal & Mint, Curved Header, Pill Buttons).
class CareReceiverHomeScreen extends StatefulWidget {
  const CareReceiverHomeScreen({super.key});

  @override
  State<CareReceiverHomeScreen> createState() => _CareReceiverHomeScreenState();
}

class _CareReceiverHomeScreenState extends State<CareReceiverHomeScreen> {
  CheckinStatus? _selectedCheckinStatus;
  bool _isFallGuardActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<WellnessProvider>().loadTodayWellness(auth.userId ?? 'care-receiver-001');
      _initFallDetection();
      _initSafetyCheck();
    });
  }

  void _initFallDetection() {
    final fallService = FallDetectionService.instance;
    fallService.startMonitoring(
      onFallEmergencyTriggered: () {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();

          final authProvider = context.read<AuthProvider>();
          final emergencyProvider = context.read<EmergencyProvider>();

          unawaited(emergencyProvider.dispatchEmergency(
            careReceiverId: authProvider.userId ?? 'care-receiver-001',
            senderName: '${authProvider.fullName ?? "Lansia SIGAP"} (Deteksi Jatuh Otomatis)',
          ));
        }
      },
    );

    fallService.stateNotifier.removeListener(_handleFallStateChanged);
    fallService.stateNotifier.addListener(_handleFallStateChanged);
  }

  void _initSafetyCheck() {
    final safetyService = SafetyCheckService.instance;
    safetyService.statusNotifier.removeListener(_handleSafetyCheckStateChanged);
    safetyService.statusNotifier.addListener(_handleSafetyCheckStateChanged);
  }

  void _handleSafetyCheckStateChanged() {
    if (!mounted) return;
    final status = SafetyCheckService.instance.statusNotifier.value;
    if (status == SafetyCheckStatus.verificationPrompt || status == SafetyCheckStatus.preAlarmTriggered) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const SafetyCheckAlertDialog(),
      );
    }
  }

  void _handleSafetyCheckEmergency() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      final authProvider = context.read<AuthProvider>();
      final emergencyProvider = context.read<EmergencyProvider>();

      unawaited(emergencyProvider.dispatchEmergency(
        careReceiverId: authProvider.userId ?? 'care-receiver-001',
        senderName: '${authProvider.fullName ?? "Lansia SIGAP"} (Cek Keselamatan Perjalanan Habis)',
      ));
    }
  }

  void _handleFallStateChanged() {
    if (!mounted) return;
    final state = FallDetectionService.instance.stateNotifier.value;
    if (state == FallEngineState.fallConfirmed) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const FallAlertDialog(),
      );
    }
  }

  @override
  void dispose() {
    FallDetectionService.instance.stateNotifier.removeListener(_handleFallStateChanged);
    SafetyCheckService.instance.statusNotifier.removeListener(_handleSafetyCheckStateChanged);
    super.dispose();
  }

  void _triggerSosCountdown() {
    final emergencyProvider = context.read<EmergencyProvider>();
    final auth = context.read<AuthProvider>();

    FeedbackService.instance.triggerEmergencyVibration();
    emergencyProvider.startSosCountdown(
      careReceiverId: auth.userId ?? 'care-receiver-001',
      senderName: auth.fullName ?? 'Lansia SIGAP',
    );
  }

  void _cancelSosCountdown() {
    final emergencyProvider = context.read<EmergencyProvider>();
    FeedbackService.instance.triggerWarningFeedback();
    emergencyProvider.cancelSosCountdown();
  }

  void _submitCheckin(CheckinStatus status) {
    setState(() => _selectedCheckinStatus = status);
    FeedbackService.instance.triggerSuccessFeedback();

    final auth = context.read<AuthProvider>();
    context.read<WellnessProvider>().submitCheckin(
      careReceiverId: auth.userId ?? 'care-receiver-001',
      status: status,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.safeGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
        content: Text(
          'Status berhasil dicatat: ${status.label} ${status.emoji}',
          style: AppTypography.seniorBodyPrimary(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();
    final auth = context.watch<AuthProvider>();
    final userName = auth.fullName ?? 'Ibu Aminah';

    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // =================================================================
                // 1. Signature Curved Teal Header (Sesuai Referensi Desain)
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
                      // Top Row: Avatar & Switch Role
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
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 26.0,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceSM),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                ),
                                child: Text(
                                  'RT 04 / RW 02',
                                  style: AppTypography.standardCaption(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28.0),
                                tooltip: 'Kartu Medis ICE',
                                onPressed: () => context.push('/profile/ice-card-view'),
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

                      // Greeting Text
                      Text(
                        'Selamat Datang,',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '$userName!',
                        style: AppTypography.seniorHeadingLarge(color: Colors.white),
                      ),
                      const SizedBox(height: AppDimensions.spaceLG),

                      // Floating Pill Search / Info Bar (Sesuai Referensi Gambar)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMD, vertical: 12.0),
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
                            const Icon(Icons.search_rounded, color: AppColors.primaryTeal, size: 24.0),
                            const SizedBox(width: AppDimensions.spaceSM),
                            Expanded(
                              child: Text(
                                'Cari kontak darurat, obat, atau bantuan...',
                                style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================================
                // 2. Konten Halaman Pada Kanvas Mint Lembut
                // =================================================================
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner Status Darurat Terkirim
                      if (emergencyProvider.isDispatched) ...[
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceLG),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.emergencyRedGlow,
                                blurRadius: 20.0,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36.0),
                                  const SizedBox(width: AppDimensions.spaceMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sinyal Darurat Aktif!',
                                          style: AppTypography.seniorTitle(color: Colors.white),
                                        ),
                                        Text(
                                          'Relawan tetangga dan keluarga sedang meluncur.',
                                          style: AppTypography.seniorBodySecondary(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spaceMD),
                              AccessibleButton(
                                label: 'BATALKAN DARURAT (SAYA AMAN)',
                                onPressed: _cancelSosCountdown,
                                backgroundColor: Colors.white,
                                textColor: AppColors.emergencyRed,
                                customHeight: 64.0,
                                icon: Icons.check_circle_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceLG),
                      ],

                      // =============================================================
                      // Kategori Cepat (Sesuai Referensi Gambar "Categories")
                      // =============================================================
                      Text(
                        'Kategori Layanan',
                        style: AppTypography.categoryHeadline(),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),

                      Row(
                        children: [
                          Expanded(
                            child: _CategoryPillCard(
                              title: 'ICE Medis',
                              subtitle: 'Data Darurat',
                              icon: Icons.badge_rounded,
                              iconBg: AppColors.primaryTealLight,
                              iconColor: AppColors.primaryTealDark,
                              onTap: () => context.push('/profile/ice-card-view'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceMD),
                          Expanded(
                            child: _CategoryPillCard(
                              title: 'Jadwal Obat',
                              subtitle: 'Pengingat Harian',
                              icon: Icons.medication_liquid_rounded,
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: AppColors.warningAmber,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.spaceLG),

                      // =============================================================
                      // Bagian Tombol SOS Utama (Ukuran Ramah Lansia 160x160dp)
                      // =============================================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceXL,
                          horizontal: AppDimensions.spaceLG,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                          border: Border.all(color: AppColors.mintBorder, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 18.0,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'BUTUH BANTUAN DARURAT?',
                              style: AppTypography.seniorTitle(color: AppColors.emergencyRed),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimensions.spaceMD),
                            Semantics(
                              button: true,
                              label: 'Tombol Darurat SOS, tekan untuk memanggil bantuan',
                              child: GestureDetector(
                                onTap: emergencyProvider.isDispatched
                                    ? () {
                                        FeedbackService.instance.triggerWarningFeedback();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: AppColors.emergencyRedDark,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                              'Panggilan darurat sedang aktif. Tekan tombol batalkan jika sudah aman.',
                                            ),
                                          ),
                                        );
                                      }
                                    : _triggerSosCountdown,
                                child: Container(
                                  width: AppDimensions.sosButtonSize + 40.0, // 160dp
                                  height: AppDimensions.sosButtonSize + 40.0,
                                  decoration: BoxDecoration(
                                    color: AppColors.emergencyRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 5.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.emergencyRedGlow,
                                        blurRadius: 28.0,
                                        spreadRadius: 6.0,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.sos_rounded,
                                        color: Colors.white,
                                        size: AppDimensions.sosIconSize + 8.0,
                                      ),
                                      Text(
                                        'SOS',
                                        style: AppTypography.seniorSosLabel(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceMD),
                            Text(
                              'Tekan satu kali untuk panggil bantuan tetangga',
                              style: AppTypography.seniorBodySecondary(color: AppColors.textDarkSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spaceLG),

                      // =============================================================
                      // Kartu Cek Perjalanan Aman (Safety Check / Walk-Safe Timer)
                      // =============================================================
                      SafetyCheckCard(
                        onEmergencyTriggered: _handleSafetyCheckEmergency,
                      ),

                      const SizedBox(height: AppDimensions.spaceLG),

                      // =============================================================
                      // Kartu AI Fall Guard (Deteksi Jatuh Otomatis)
                      // =============================================================
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                          border: Border.all(
                            color: _isFallGuardActive ? AppColors.primaryTeal : AppColors.mintBorder,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 16.0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(AppDimensions.spaceLG),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                                  decoration: BoxDecoration(
                                    color: (_isFallGuardActive
                                            ? AppColors.primaryTealLight
                                            : AppColors.mintSurface)
                                        .withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.personal_injury_rounded,
                                    color: _isFallGuardActive ? AppColors.primaryTealDark : AppColors.textDarkTertiary,
                                    size: 28.0,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Fall Guard',
                                        style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isFallGuardActive
                                            ? 'Sensor memantau benturan & imobilitas secara otomatis.'
                                            : 'Fitur deteksi jatuh dinonaktifkan.',
                                        style: AppTypography.standardCaption(
                                          color: _isFallGuardActive
                                              ? AppColors.primaryTealDark
                                              : AppColors.textDarkSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isFallGuardActive,
                                  activeColor: AppColors.primaryTeal,
                                  onChanged: (val) {
                                    setState(() => _isFallGuardActive = val);
                                    unawaited(FeedbackService.instance.triggerSuccessFeedback());
                                    if (val) {
                                      _initFallDetection();
                                    } else {
                                      FallDetectionService.instance.stopMonitoring();
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (_isFallGuardActive) ...[
                              const SizedBox(height: AppDimensions.spaceMD),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.warningAmberDark,
                                  side: const BorderSide(color: AppColors.warningAmber),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSM),
                                ),
                                onPressed: () {
                                  unawaited(FeedbackService.instance.triggerSuccessFeedback());
                                  FallDetectionService.instance.simulateFallEvent();
                                },
                                icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.warningAmber, size: 22),
                                label: const Text(
                                  'Uji Simulasi Deteksi Jatuh (10s Pre-Alarm)',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spaceXL),

                      // =============================================================
                      // Bagian Check-in Harian
                      // =============================================================
                      Text(
                        'Kondisi Anda Hari Ini?',
                        style: AppTypography.categoryHeadline(),
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Text(
                        'Pilih salah satu agar keluarga dan RT mengetahui kabar Anda:',
                        style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),

                      // 3 Tombol Check-in Berukuran Ramah Lansia (min 72dp)
                      _CheckinOptionCard(
                        status: CheckinStatus.baik,
                        isSelected: _selectedCheckinStatus == CheckinStatus.baik,
                        onTap: () => _submitCheckin(CheckinStatus.baik),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      _CheckinOptionCard(
                        status: CheckinStatus.kurangEnak,
                        isSelected: _selectedCheckinStatus == CheckinStatus.kurangEnak,
                        onTap: () => _submitCheckin(CheckinStatus.kurangEnak),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      _CheckinOptionCard(
                        status: CheckinStatus.butuhBantuan,
                        isSelected: _selectedCheckinStatus == CheckinStatus.butuhBantuan,
                        onTap: () => _submitCheckin(CheckinStatus.butuhBantuan),
                      ),

                      const SizedBox(height: AppDimensions.spaceXL),

                      // =============================================================
                      // Bagian Pengingat Obat Lansia
                      // =============================================================
                      Text(
                        'Jadwal Minum Obat',
                        style: AppTypography.categoryHeadline(),
                      ),
                      const SizedBox(height: AppDimensions.spaceXS),
                      Text(
                        'Tekan tombol setelah Anda meminum obat:',
                        style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),

                      ...context.watch<WellnessProvider>().medicationSchedules.map((med) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                          child: _SeniorMedicationCard(
                            scheduleName: med.medicationName,
                            dosage: med.dosage,
                            reminderTime: med.reminderTimes.isNotEmpty ? med.reminderTimes.first : '08:00',
                            isTaken: med.isTakenToday,
                            onTake: () {
                              final authUser = context.read<AuthProvider>();
                              context.read<WellnessProvider>().markMedicationTaken(
                                scheduleId: med.id,
                                careReceiverId: authUser.userId ?? 'care-receiver-001',
                              );
                              unawaited(FeedbackService.instance.triggerSuccessFeedback());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.safeGreenDark,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'Konfirmasi: ${med.medicationName} sudah diminum.',
                                    style: AppTypography.seniorBodyPrimary(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: AppDimensions.spaceXL),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Overlay Countdown Pembatalan 8 Detik
          if (emergencyProvider.isCountingDown)
            _CountdownOverlay(
              secondsRemaining: emergencyProvider.countdownRemaining,
              onCancel: _cancelSosCountdown,
            ),
        ],
      ),
    );
  }
}

class _CategoryPillCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _CategoryPillCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: const BorderSide(color: AppColors.mintBorder, width: 1.5),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Icon(icon, color: iconColor, size: 24.0),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckinOptionCard extends StatelessWidget {
  final CheckinStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _CheckinOptionCard({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryTealLight : AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: BorderSide(
          color: isSelected ? AppColors.primaryTeal : AppColors.mintBorder,
          width: isSelected ? 2.0 : 1.5,
        ),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.seniorRecommendedTouchTarget, // 72dp
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceLG,
            vertical: AppDimensions.spaceMD,
          ),
          child: Row(
            children: [
              Text(
                status.emoji,
                style: const TextStyle(fontSize: 34.0),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Text(
                  status.label,
                  style: AppTypography.seniorTitle(
                    color: isSelected ? AppColors.primaryTealDeep : AppColors.textDarkPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 28.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int secondsRemaining;
  final VoidCallback onCancel;

  const _CountdownOverlay({
    required this.secondsRemaining,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.emergencyRed,
            size: 80.0,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            'MENGIRIM ALARM DARURAT',
            style: AppTypography.seniorHeadingLarge(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          Container(
            width: 120.0,
            height: 120.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emergencyRed, width: 6.0),
            ),
            alignment: Alignment.center,
            child: Text(
              '$secondsRemaining',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          Text(
            'Bantuan akan segera dipanggil dalam $secondsRemaining detik.',
            style: AppTypography.seniorBodyPrimary(color: AppColors.textLightSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.space2XL),
          AccessibleButton(
            label: 'BATALKAN PANGGILAN',
            onPressed: onCancel,
            isSimplified: true,
            backgroundColor: Colors.white,
            textColor: AppColors.emergencyRed,
            borderColor: Colors.white,
            icon: Icons.close_rounded,
          ),
        ],
      ),
    );
  }
}

class _SeniorMedicationCard extends StatelessWidget {
  final String scheduleName;
  final String dosage;
  final String reminderTime;
  final bool isTaken;
  final VoidCallback onTake;

  const _SeniorMedicationCard({
    required this.scheduleName,
    required this.dosage,
    required this.reminderTime,
    required this.isTaken,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      decoration: BoxDecoration(
        color: isTaken ? AppColors.mintSurface : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isTaken ? AppColors.safeGreen : AppColors.mintBorder,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isTaken ? AppColors.safeGreen.withValues(alpha: 0.15) : AppColors.primaryTealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                  color: isTaken ? AppColors.safeGreen : AppColors.primaryTealDark,
                  size: 28.0,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheduleName,
                      style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                    ),
                    Text(
                      '$dosage • Jam $reminderTime WIB',
                      style: AppTypography.seniorBodySecondary(color: AppColors.textDarkSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AccessibleButton(
            label: isTaken ? 'Sudah Diminum ✓' : 'Saya Sudah Minum Obat Ini',
            onPressed: isTaken ? null : onTake,
            isSimplified: true,
            backgroundColor: isTaken ? AppColors.mintSurface : AppColors.primaryTeal,
            textColor: isTaken ? AppColors.textDarkTertiary : Colors.white,
            icon: isTaken ? Icons.done_all_rounded : Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}
