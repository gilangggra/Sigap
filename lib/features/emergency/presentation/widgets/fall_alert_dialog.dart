import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/fall_detection_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Dialog Layar Penuh Darurat Deteksi Jatuh Berstandar Aksesibilitas Lansia (WCAG AA).
/// Menampilkan hitung mundur 10 detik, tombol pembatalan berukuran ekstra besar (min 76dp),
/// dan tombol konfirmasi instan.
class FallAlertDialog extends StatelessWidget {
  const FallAlertDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final fallService = FallDetectionService.instance;

    return PopScope(
      canPop: false, // Mencegah ditutup sembarangan tanpa memilih aksi
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppDimensions.spaceMD),
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          side: const BorderSide(color: AppColors.emergencyRed, width: 3.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Peringatan Besar
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: const BoxDecoration(
                  color: AppColors.emergencyRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergencyRedGlow,
                      blurRadius: 24.0,
                      spreadRadius: 4.0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.personal_injury_rounded,
                  color: Colors.white,
                  size: 56.0,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),

              // Judul Peringatan Ekstra Besar
              Text(
                '🚨 TERDETEKSI JATUH!',
                textAlign: TextAlign.center,
                style: AppTypography.seniorHeadingLarge(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceSM),

              Text(
                'Sistem mendeteksi benturan dan tubuh diam tak bergerak. Panggilan bantuan darurat dikirim ke 5 relawan RT dalam:',
                textAlign: TextAlign.center,
                style: AppTypography.seniorBodyPrimary(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceLG),

              // Lingkaran Hitung Mundur 10 Detik
              ValueListenableBuilder<int>(
                valueListenable: fallService.countdownNotifier,
                builder: (context, seconds, _) {
                  return Container(
                    width: 90.0,
                    height: 90.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.emergencyRedLight, width: 4.0),
                      color: AppColors.darkSurfaceElevated,
                    ),
                    child: Text(
                      '$seconds',
                      style: AppTypography.countdownDisplay(color: AppColors.emergencyRedLight),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Tombol Pembatalan Raksasa (Target Sentuh Utama: 76dp)
              AccessibleButton(
                label: 'SAYA BAIK-BAIK SAJA (BATALKAN)',
                onPressed: () {
                  fallService.cancelPreAlarm();
                  Navigator.of(context).pop();
                },
                backgroundColor: AppColors.safeGreenDark,
                textColor: Colors.white,
                borderColor: AppColors.safeGreenLight,
                customHeight: 76.0,
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Konfirmasi Segera (Kirim Sekarang)
              AccessibleButton(
                label: 'KIRIM BANTUAN SEKARANG',
                onPressed: () {
                  fallService.confirmEmergencyNow();
                  Navigator.of(context).pop();
                },
                backgroundColor: AppColors.darkCard,
                textColor: AppColors.emergencyRedLight,
                borderColor: AppColors.emergencyRed,
                customHeight: 60.0,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

