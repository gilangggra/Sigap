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
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/components.dart';
import '../../../wellness/presentation/state/wellness_provider.dart';
import '../state/emergency_provider.dart';
import '../widgets/fall_alert_dialog.dart';
import '../widgets/safety_check_alert_dialog.dart';
import '../widgets/safety_check_card.dart';

/// Halaman Beranda Care-Receiver (Antarmuka Standar Mobile Khusus Lansia / Simplified Mode)
/// Mengimplementasikan tata letak standar mobile yang rapi, bersih, dan konsisten dengan font Poppins.
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
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          Column(
            children: [
              // =============================================================
              // Top Hero Header Banner Khas Mobile Modern
              // =============================================================
              AppHeaderBanner(
                title: 'Halo, $userName',
                subtitle: 'Sistem Siaga RT 04 / RW 02 Aktif',
                leading: AppAvatar(
                  name: userName,
                  radius: 22.0,
                  isOnline: true,
                  showBadge: true,
                  borderColor: Colors.white,
                ),
                actions: [
                  _HeaderIconButton(
                    icon: Icons.qr_code_2_rounded,
                    tooltip: 'Kartu Medis ICE',
                    onTap: () => context.push('/profile/ice-card-view'),
                  ),
                  const SizedBox(width: 6.0),
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
                    AppBadge.success('Siaga Aktif', icon: Icons.check_circle_rounded),
                    const SizedBox(width: 8.0),
                    AppBadge.neutral('RT 04 / RW 02'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.battery_charging_full_rounded, size: 14.0, color: Colors.white),
                          SizedBox(width: 4.0),
                          Text(
                            '95% • GPS OK',
                            style: TextStyle(fontSize: 11.0, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
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
                      // Banner Status Darurat Terkirim
                      if (emergencyProvider.isDispatched) ...[
                        AppCard.emergency(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 32.0),
                                  const SizedBox(width: AppDimensions.spaceMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sinyal Darurat Aktif!',
                                          style: AppTypography.seniorTitle(color: AppColors.emergencyRed),
                                        ),
                                        Text(
                                          'Relawan tetangga dan keluarga sedang meluncur.',
                                          style: AppTypography.seniorBodySecondary(color: AppColors.emergencyRedDark),
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
                                backgroundColor: AppColors.emergencyRed,
                                textColor: Colors.white,
                                customHeight: 64.0,
                                icon: Icons.check_circle_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceMD),
                      ],

                      // =============================================================
                      // 1. Kartu Tombol SOS Darurat Utama (Concentric Pulse Rings)
                      // =============================================================
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceXL,
                          horizontal: AppDimensions.spaceMD,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'PANGGILAN BANTUAN DARURAT',
                              style: AppTypography.seniorTitle(color: AppColors.emergencyRed),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimensions.spaceXS),
                            Text(
                              'Tekan tombol satu kali jika butuh pertolongan cepat',
                              style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimensions.spaceLG),
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
                                  width: 172.0,
                                  height: 172.0,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.emergencyRedWash,
                                  ),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 144.0,
                                    height: 144.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.emergencyRed.withValues(alpha: 0.12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 118.0,
                                      height: 118.0,
                                      decoration: const BoxDecoration(
                                        gradient: AppGradients.emergency,
                                        shape: BoxShape.circle,
                                        boxShadow: AppShadows.emergencyGlow,
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.sos_rounded,
                                            color: Colors.white,
                                            size: 46.0,
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
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spaceMD),

                      // =============================================================
                      // 2. Kartu Cek Perjalanan Aman (Safety Check / Walk-Safe Timer)
                      // =============================================================
                      SafetyCheckCard(
                        onEmergencyTriggered: _handleSafetyCheckEmergency,
                      ),

                      const SizedBox(height: AppDimensions.spaceMD),

                      // =============================================================
                      // 3. Kartu AI Fall Guard (Deteksi Jatuh Otomatis)
                      // =============================================================
                      AppCard(
                        border: _isFallGuardActive ? AppBorders.tealActive : AppBorders.standard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: _isFallGuardActive
                                        ? AppColors.primaryTealLight
                                        : AppColors.mintSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.personal_injury_rounded,
                                    color: _isFallGuardActive ? AppColors.primaryTealDark : AppColors.textDarkTertiary,
                                    size: 24.0,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'AI Fall Guard',
                                            style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                                          ),
                                          const SizedBox(width: 8.0),
                                          if (_isFallGuardActive)
                                            AppBadge.brand('Aktif', isSmall: true)
                                          else
                                            AppBadge.neutral('Mati', isSmall: true),
                                        ],
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        _isFallGuardActive
                                            ? 'Sensor memantau benturan & imobilitas otomatis.'
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
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                ),
                                onPressed: () {
                                  unawaited(FeedbackService.instance.triggerSuccessFeedback());
                                  FallDetectionService.instance.simulateFallEvent();
                                },
                                icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.warningAmber, size: 20),
                                label: Text(
                                  'Uji Simulasi Deteksi Jatuh (10s Pre-Alarm)',
                                  style: AppTypography.standardCaption(color: AppColors.warningAmberDark),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppDimensions.spaceLG),

                      // =============================================================
                      // 4. Bagian Check-in Kondisi Harian
                      // =============================================================
                      const AppSectionHeader(
                        title: 'Kondisi Anda Hari Ini?',
                        subtitle: 'Pilih salah satu agar keluarga dan RT mengetahui kabar Anda',
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),

                      _CheckinOptionCard(
                        status: CheckinStatus.baik,
                        isSelected: _selectedCheckinStatus == CheckinStatus.baik,
                        onTap: () => _submitCheckin(CheckinStatus.baik),
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      _CheckinOptionCard(
                        status: CheckinStatus.kurangEnak,
                        isSelected: _selectedCheckinStatus == CheckinStatus.kurangEnak,
                        onTap: () => _submitCheckin(CheckinStatus.kurangEnak),
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      _CheckinOptionCard(
                        status: CheckinStatus.butuhBantuan,
                        isSelected: _selectedCheckinStatus == CheckinStatus.butuhBantuan,
                        onTap: () => _submitCheckin(CheckinStatus.butuhBantuan),
                      ),

                      const SizedBox(height: AppDimensions.spaceLG),

                      // =============================================================
                      // 5. Bagian Pengingat Obat Lansia
                      // =============================================================
                      const AppSectionHeader(
                        title: 'Jadwal Minum Obat',
                        subtitle: 'Tekan tombol setelah Anda meminum obat',
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),

                      ...context.watch<WellnessProvider>().medicationSchedules.map((med) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
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
              ),
            ],
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
    return AppCard.interactive(
      isSelected: isSelected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMD,
        vertical: AppDimensions.spaceMD,
      ),
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryTealLight : AppColors.mintSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              status.emoji,
              style: const TextStyle(fontSize: 24.0),
            ),
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
            const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 24.0),
        ],
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
            size: 72.0,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            'MENGIRIM ALARM DARURAT',
            style: AppTypography.seniorHeadingLarge(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Container(
            width: 110.0,
            height: 110.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emergencyRed, width: 5.0),
            ),
            alignment: Alignment.center,
            child: Text(
              '$secondsRemaining',
              style: AppTypography.countdownDisplay(),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            'Bantuan akan segera dipanggil dalam $secondsRemaining detik.',
            style: AppTypography.seniorBodyPrimary(color: AppColors.textLightSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceXL),
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
    return AppCard(
      border: isTaken
          ? Border.all(color: AppColors.safeGreen, width: 1.0)
          : AppBorders.standard,
      backgroundColor: isTaken ? AppColors.safeGreenWash : AppColors.cardWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isTaken ? AppColors.safeGreenWash : AppColors.primaryTealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                  color: isTaken ? AppColors.safeGreenDark : AppColors.primaryTealDark,
                  size: 24.0,
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
              if (isTaken)
                AppBadge.success('Sudah', isSmall: true),
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
