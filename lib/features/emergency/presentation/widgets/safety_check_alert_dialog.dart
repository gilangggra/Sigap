import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/safety_check_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Modal Verifikasi Keselamatan Perjalanan (Safety Check Prompt / Pre-Alarm)
class SafetyCheckAlertDialog extends StatelessWidget {
  const SafetyCheckAlertDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final safetyService = SafetyCheckService.instance;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          side: const BorderSide(color: AppColors.warningAmber, width: 3.0),
        ),
        insetPadding: const EdgeInsets.all(AppDimensions.spaceLG),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ikon Status Berkedip
              Center(
                child: Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: AppColors.warningAmberLight,
                    size: 48.0,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              Text(
                'WAKTU PERJALANAN SELESAI',
                style: AppTypography.seniorHeadingMedium(color: AppColors.warningAmberLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Apakah Anda sudah tiba di rumah dengan selamat?',
                style: AppTypography.seniorBodyPrimary(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceLG),

              // Countdown Pre-Alarm Buffer (15 Detik)
              ValueListenableBuilder<SafetyCheckStatus>(
                valueListenable: safetyService.statusNotifier,
                builder: (context, status, _) {
                  final bool isPreAlarm = status == SafetyCheckStatus.preAlarmTriggered;

                  return ValueListenableBuilder<int>(
                    valueListenable: isPreAlarm
                        ? safetyService.preAlarmSecondsNotifier
                        : safetyService.secondsRemainingNotifier,
                    builder: (context, seconds, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spaceMD,
                          horizontal: AppDimensions.spaceLG,
                        ),
                        decoration: BoxDecoration(
                          color: isPreAlarm
                              ? AppColors.emergencyRedDark.withValues(alpha: 0.3)
                              : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          border: Border.all(
                            color: isPreAlarm ? AppColors.emergencyRedLight : AppColors.darkBorderHighContrast,
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isPreAlarm ? '$seconds DETIK' : SafetyCheckService.formatSecondsToMinutes(seconds),
                              style: AppTypography.countdownDisplay(
                                color: isPreAlarm ? AppColors.emergencyRedLight : Colors.white,
                              ),
                            ),
                            Text(
                              isPreAlarm
                                  ? 'Menuju pengiriman sinyal SOS darurat otomatis ke relawan RT'
                                  : 'Tersisa sebelum alarm darurat aktif',
                              style: AppTypography.standardCaption(
                                color: isPreAlarm ? AppColors.emergencyRedLight : AppColors.textDarkSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Tombol Konfirmasi Raksasa (Target Sentuh Utama: 76dp)
              AccessibleButton(
                label: 'YA, SAYA SUDAH AMAN',
                onPressed: () {
                  safetyService.confirmSafe();
                  Navigator.of(context).pop();
                },
                backgroundColor: AppColors.safeGreenDark,
                borderColor: AppColors.safeGreenLight,
                customHeight: 76.0,
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Tambah Waktu (+15 Menit)
              AccessibleButton(
                label: 'BELUM SAMPAI (+15 MENIT LAGI)',
                onPressed: () {
                  safetyService.extendDuration(additionalMinutes: 15);
                  Navigator.of(context).pop();
                },
                backgroundColor: AppColors.infoBlueDark,
                borderColor: AppColors.infoBlueLight,
                customHeight: 64.0,
                icon: Icons.add_alarm_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
