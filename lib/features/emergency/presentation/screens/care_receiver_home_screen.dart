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
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: const BoxDecoration(
                color: AppColors.primaryTealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, color: AppColors.primaryTeal, size: 22.0),
            ),
            const SizedBox(width: AppDimensions.spaceSM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIGAP',
                  style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
                ),
                Text(
                  'Mode Bantuan Lansia',
                  style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, size: 26.0),
            tooltip: 'Kartu Medis ICE',
            onPressed: () => context.push('/profile/ice-card-view'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 26.0),
            tooltip: 'Profil Saya',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, size: 26.0),
            tooltip: 'Ganti Peran',
            onPressed: () => context.go('/auth/role'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceMD,
                vertical: AppDimensions.spaceSM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =============================================================
                  // 1. Kartu Profil & Wilayah RT (Standar Mobile Card)
                  // =============================================================
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.lightBorder, width: 1.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 8.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26.0,
                          backgroundColor: AppColors.primaryTealLight,
                          child: Icon(Icons.person_rounded, color: AppColors.primaryTeal, size: 30.0),
                        ),
                        const SizedBox(width: AppDimensions.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $userName',
                                style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                              ),
                              const SizedBox(height: 2.0),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.mintSurface,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                    ),
                                    child: Text(
                                      'RT 04 / RW 02',
                                      style: AppTypography.standardCaption(color: AppColors.primaryTealDark),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.spaceSM),
                                  const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen, size: 14.0),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    'Siaga Aktif',
                                    style: AppTypography.standardCaption(color: AppColors.safeGreen),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceMD),

                  // Banner Status Darurat Terkirim
                  if (emergencyProvider.isDispatched) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.emergencyRedGlow,
                            blurRadius: 12.0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32.0),
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
                    const SizedBox(height: AppDimensions.spaceMD),
                  ],

                  // =============================================================
                  // 2. Kartu Tombol SOS Darurat Utama
                  // =============================================================
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceLG,
                      horizontal: AppDimensions.spaceMD,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.lightBorder, width: 1.0),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10.0,
                          offset: Offset(0, 2),
                        ),
                      ],
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
                              width: 140.0,
                              height: 140.0,
                              decoration: BoxDecoration(
                                color: AppColors.emergencyRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.emergencyRedGlow,
                                    blurRadius: 24.0,
                                    spreadRadius: 4.0,
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
                                    size: 52.0,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceMD),

                  // =============================================================
                  // 3. Kartu Cek Perjalanan Aman (Safety Check / Walk-Safe Timer)
                  // =============================================================
                  SafetyCheckCard(
                    onEmergencyTriggered: _handleSafetyCheckEmergency,
                  ),

                  const SizedBox(height: AppDimensions.spaceMD),

                  // =============================================================
                  // 4. Kartu AI Fall Guard (Deteksi Jatuh Otomatis)
                  // =============================================================
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(
                        color: _isFallGuardActive ? AppColors.primaryTeal : AppColors.lightBorder,
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
                                  Text(
                                    'AI Fall Guard',
                                    style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                                  ),
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
                          const SizedBox(height: AppDimensions.spaceSM),
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
                  // 5. Bagian Check-in Kondisi Harian
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
                  // 6. Bagian Pengingat Obat Lansia
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
          color: isSelected ? AppColors.primaryTeal : AppColors.lightBorder,
          width: isSelected ? 1.5 : 1.0,
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
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceSM,
          ),
          child: Row(
            children: [
              Text(
                status.emoji,
                style: const TextStyle(fontSize: 30.0),
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
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: isTaken ? AppColors.mintSurface : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isTaken ? AppColors.safeGreen : AppColors.lightBorder,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isTaken ? AppColors.safeGreen.withValues(alpha: 0.15) : AppColors.primaryTealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                  color: isTaken ? AppColors.safeGreen : AppColors.primaryTealDark,
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
