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
/// Mengimplementasikan Tombol SOS ukuran min 120x120dp, Card Check-in Besar,
/// dan Countdown Pembatalan 8 detik dengan feedback haptic/audio.
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
          // Tutup FallAlertDialog jika masih terbuka di layar
          Navigator.of(context, rootNavigator: true).maybePop();

          final authProvider = context.read<AuthProvider>();
          final emergencyProvider = context.read<EmergencyProvider>();

          // Langsung dispatch sinyal darurat tanpa countdown kedua
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
    if (FallDetectionService.instance.stateNotifier.value == FallEngineState.fallConfirmed) {
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
    final authProvider = context.read<AuthProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();

    emergencyProvider.startSosCountdown(
      careReceiverId: authProvider.userId ?? 'care-receiver-001',
      senderName: authProvider.fullName ?? 'Lansia SIGAP',
    );
  }

  void _cancelSosCountdown() {
    context.read<EmergencyProvider>().cancelSosCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.darkSurfaceElevated,
        content: Text(
          'Panggilan darurat berhasil dibatalkan.',
          style: AppTypography.seniorBodyPrimary(color: Colors.white),
        ),
      ),
    );
  }

  void _submitCheckin(CheckinStatus status) {
    setState(() {
      _selectedCheckinStatus = status;
    });

    unawaited(FeedbackService.instance.triggerSuccessFeedback());

    final auth = context.read<AuthProvider>();
    context.read<WellnessProvider>().submitCheckin(
      careReceiverId: auth.userId ?? 'care-receiver-001',
      status: status,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.safeGreenDark,
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

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('SIGAP — Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 30.0),
            tooltip: 'Profil & ICE Card',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, size: 30.0),
            tooltip: 'Ganti Peran',
            onPressed: () => context.go('/auth/role'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Status Darurat Terkirim
                  if (emergencyProvider.isDispatched) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRedDark,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        border: Border.all(color: Colors.white, width: 2.0),
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
                                      'Relawan tetangga dan keluarga sedang dihubungi.',
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
                            backgroundColor: AppColors.darkSurfaceElevated,
                            borderColor: Colors.white,
                            customHeight: 64.0,
                            icon: Icons.check_circle_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceLG),
                  ],

                  // Bagian Tombol SOS Utama (Ukuran minimum 120x120dp)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'BUTUH BANTUAN DARURAT?',
                          style: AppTypography.seniorTitle(color: AppColors.emergencyRedLight),
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
                                        content: Text('Panggilan darurat sedang aktif. Tekan tombol batalkan di atas jika Anda sudah aman.'),
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
                                border: Border.all(color: Colors.white, width: 4.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.emergencyRedGlow,
                                    blurRadius: 30.0,
                                    spreadRadius: 8.0,
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
                        const SizedBox(height: AppDimensions.spaceSM),
                        Text(
                          'Tekan satu kali untuk panggil bantuan tetangga',
                          style: AppTypography.seniorBodySecondary(color: AppColors.textDarkSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceLG),

                  // Kartu Cek Perjalanan Aman (Safety Check / Walk-Safe Timer)
                  SafetyCheckCard(
                    onEmergencyTriggered: _handleSafetyCheckEmergency,
                  ),

                  const SizedBox(height: AppDimensions.spaceLG),

                  // Kartu AI Fall Guard (Deteksi Jatuh Otomatis)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                      border: Border.all(
                        color: _isFallGuardActive ? AppColors.safeGreenLight : AppColors.darkBorderHighContrast,
                        width: 2.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.spaceSM),
                              decoration: BoxDecoration(
                                color: (_isFallGuardActive ? AppColors.safeGreenDark : AppColors.darkSurfaceElevated)
                                    .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.personal_injury_rounded,
                                color: _isFallGuardActive ? AppColors.safeGreenLight : AppColors.textDarkTertiary,
                                size: 32.0,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Fall Guard',
                                    style: AppTypography.seniorTitle(color: Colors.white),
                                  ),
                                  Text(
                                    _isFallGuardActive
                                        ? 'Sensor memantau benturan & imobilitas secara otomatis.'
                                        : 'Fitur deteksi jatuh dinonaktifkan.',
                                    style: AppTypography.standardCaption(
                                      color: _isFallGuardActive ? AppColors.safeGreenLight : AppColors.textDarkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isFallGuardActive,
                              activeColor: AppColors.safeGreenLight,
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
                              side: const BorderSide(color: AppColors.darkBorderHighContrast),
                              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSM),
                            ),
                            onPressed: () {
                              unawaited(FeedbackService.instance.triggerSuccessFeedback());
                              FallDetectionService.instance.simulateFallEvent();
                            },
                            icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.warningAmberLight, size: 20),
                            label: const Text(
                              'Uji Simulasi Deteksi Jatuh (10s Pre-Alarm)',
                              style: TextStyle(color: AppColors.warningAmberLight, fontSize: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space2XL),
                  const Divider(color: AppColors.darkBorderHighContrast, thickness: 2.0),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Bagian Check-in Harian
                  Text(
                    'Kondisi Anda Pagi Ini?',
                    style: AppTypography.seniorHeadingMedium(color: Colors.white),
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),
                  Text(
                    'Pilih salah satu agar keluarga dan RT mengetahui kabar Anda:',
                    style: AppTypography.seniorBodyPrimary(color: AppColors.textDarkSecondary),
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

                  const SizedBox(height: AppDimensions.space2XL),
                  const Divider(color: AppColors.darkBorderHighContrast, thickness: 2.0),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // Bagian Pengingat Obat Lansia (PRD F2.3)
                  Text(
                    'Jadwal Minum Obat',
                    style: AppTypography.seniorHeadingMedium(color: Colors.white),
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),
                  Text(
                    'Tekan tombol hijau setelah Anda meminum obat:',
                    style: AppTypography.seniorBodyPrimary(color: AppColors.textDarkSecondary),
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
                          final auth = context.read<AuthProvider>();
                          context.read<WellnessProvider>().markMedicationTaken(
                            scheduleId: med.id,
                            careReceiverId: auth.userId ?? 'care-receiver-001',
                          );
                          unawaited(FeedbackService.instance.triggerSuccessFeedback());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.safeGreenDark,
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
      color: isSelected ? AppColors.safeGreenDark : AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: isSelected ? Colors.white : AppColors.darkBorderHighContrast,
          width: AppDimensions.highContrastBorderWidth,
        ),
      ),
      elevation: AppDimensions.elevationLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
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
                style: const TextStyle(fontSize: 36.0),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Text(
                  status.label,
                  style: AppTypography.seniorTitle(
                    color: isSelected ? Colors.white : AppColors.textDarkPrimary,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 30.0),
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
            style: AppTypography.seniorBodyPrimary(color: AppColors.textDarkSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.space2XL),
          AccessibleButton(
            label: 'BATALKAN PANGGILAN',
            onPressed: onCancel,
            isSimplified: true,
            backgroundColor: AppColors.darkSurfaceElevated,
            textColor: Colors.white,
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
        color: isTaken ? AppColors.darkSurfaceElevated : AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isTaken ? AppColors.safeGreenDark : AppColors.darkBorderHighContrast,
          width: AppDimensions.highContrastBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                color: isTaken ? AppColors.safeGreenLight : AppColors.warningAmberLight,
                size: 36.0,
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheduleName,
                      style: AppTypography.seniorTitle(color: Colors.white),
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
            backgroundColor: isTaken ? AppColors.darkSurface : AppColors.safeGreen,
            textColor: Colors.white,
            icon: isTaken ? Icons.done_all_rounded : Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

