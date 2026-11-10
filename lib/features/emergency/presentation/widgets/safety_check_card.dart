import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/safety_check_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import 'safety_check_dialog.dart';

/// Kartu Antarmuka Fitur Cek Keselamatan Perjalanan (Walk-Safe Timer Card)
/// Ditampilkan pada Beranda Lansia dengan estetika modern Healthcare Pill & White Surface.
class SafetyCheckCard extends StatelessWidget {
  final VoidCallback onEmergencyTriggered;

  const SafetyCheckCard({
    super.key,
    required this.onEmergencyTriggered,
  });

  @override
  Widget build(BuildContext context) {
    final safetyService = SafetyCheckService.instance;

    return ValueListenableBuilder<SafetyCheckStatus>(
      valueListenable: safetyService.statusNotifier,
      builder: (context, status, _) {
        final bool isActive = status != SafetyCheckStatus.idle;

        if (!isActive) {
          // Tampilan Mode Standby (Belum Berangkat)
          return Container(
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
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTealLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        color: AppColors.primaryTealDark,
                        size: 28.0,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cek Perjalanan Aman',
                            style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Atur pengatur waktu saat bepergian ke masjid atau jalan pagi.',
                            style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceLG),
                AccessibleButton(
                  label: 'MULAI PERJALANAN AMAN',
                  onPressed: () {
                    unawaited(FeedbackService.instance.triggerSuccessFeedback());
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => SafetyCheckDialog(
                        onStart: onEmergencyTriggered,
                      ),
                    );
                  },
                  backgroundColor: AppColors.primaryTealLight,
                  borderColor: AppColors.primaryTeal,
                  textColor: AppColors.primaryTealDeep,
                  customHeight: 64.0,
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          );
        }

        // Tampilan Mode Pengawasan Aktif (Sedang Berjalan)
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(
              color: status == SafetyCheckStatus.preAlarmTriggered
                  ? AppColors.emergencyRed
                  : AppColors.primaryTeal,
              width: 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 20.0,
                offset: Offset(0, 6),
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
                    width: 14.0,
                    height: 14.0,
                    decoration: BoxDecoration(
                      color: status == SafetyCheckStatus.preAlarmTriggered
                          ? AppColors.emergencyRed
                          : AppColors.safeGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSM),
                  Text(
                    status == SafetyCheckStatus.preAlarmTriggered
                        ? 'PRE-ALARM DARURAT AKTIF'
                        : 'PERJALANAN SEDANG DIPANTAU',
                    style: TextStyle(
                      color: status == SafetyCheckStatus.preAlarmTriggered
                          ? AppColors.emergencyRed
                          : AppColors.primaryTealDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Digital Countdown Teks Raksasa
              ValueListenableBuilder<int>(
                valueListenable: status == SafetyCheckStatus.preAlarmTriggered
                    ? safetyService.preAlarmSecondsNotifier
                    : safetyService.secondsRemainingNotifier,
                builder: (context, seconds, _) {
                  return Column(
                    children: [
                      Text(
                        status == SafetyCheckStatus.preAlarmTriggered
                            ? '$seconds DETIK'
                            : SafetyCheckService.formatSecondsToMinutes(seconds),
                        style: TextStyle(
                          color: status == SafetyCheckStatus.preAlarmTriggered
                              ? AppColors.emergencyRed
                              : AppColors.textDarkPrimary,
                          fontSize: 44.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        status == SafetyCheckStatus.preAlarmTriggered
                            ? 'Menuju pengiriman SOS otomatis ke relawan RT'
                            : 'Waktu tersisa sebelum verifikasi keselamatan',
                        style: AppTypography.standardCaption(
                          color: AppColors.textDarkSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spaceLG),

              // Tombol Konfirmasi Tiba Raksasa (Target Sentuh Utama: 72dp)
              AccessibleButton(
                label: 'SAYA SUDAH SAMPAI (AMAN)',
                onPressed: () {
                  safetyService.confirmSafe();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.safeGreenDark,
                      content: Text('Alhamdulillah, pengawasan perjalanan selesai.'),
                    ),
                  );
                },
                backgroundColor: AppColors.safeGreen,
                customHeight: 72.0,
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Baris Opsi Tambahan (+15 Menit & Batalkan)
              Row(
                children: [
                  Expanded(
                    child: AccessibleButton(
                      label: '+15 Menit',
                      onPressed: () => safetyService.extendDuration(additionalMinutes: 15),
                      backgroundColor: AppColors.mintSurface,
                      borderColor: AppColors.mintBorder,
                      textColor: AppColors.primaryTealDark,
                      customHeight: 56.0,
                      icon: Icons.more_time_rounded,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: AccessibleButton(
                      label: 'Batalkan',
                      onPressed: () => safetyService.cancelSafetyCheck(),
                      backgroundColor: AppColors.mintSurface,
                      borderColor: AppColors.mintBorder,
                      textColor: AppColors.textDarkSecondary,
                      customHeight: 56.0,
                      icon: Icons.close_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
