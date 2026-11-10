import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/services/safety_check_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Dialog Pemilihan Durasi Perjalanan Aman (Walk-Safe Timer Setup Dialog)
/// Berstandar tombol pill ramah lansia dengan estetika modern Healthcare Teal & Mint.
class SafetyCheckDialog extends StatefulWidget {
  final VoidCallback onStart;

  const SafetyCheckDialog({
    super.key,
    required this.onStart,
  });

  @override
  State<SafetyCheckDialog> createState() => _SafetyCheckDialogState();
}

class _SafetyCheckDialogState extends State<SafetyCheckDialog> {
  int _selectedMinutes = 30;

  final List<int> _durations = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: const BorderSide(color: AppColors.mintBorder, width: 1.5),
      ),
      insetPadding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    size: 32.0,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perjalanan Aman',
                        style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                      ),
                      Text(
                        'Berapa lama Anda akan bepergian?',
                        style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceLG),

            // Pilihan Durasi Ramah Lansia (Grid 2 Kolom)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                crossAxisSpacing: AppDimensions.spaceMD,
                mainAxisSpacing: AppDimensions.spaceMD,
              ),
              itemCount: _durations.length,
              itemBuilder: (context, index) {
                final int mins = _durations[index];
                final bool isSelected = _selectedMinutes == mins;

                return InkWell(
                  onTap: () {
                    unawaited(FeedbackService.instance.triggerSuccessFeedback());
                    setState(() => _selectedMinutes = mins);
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryTeal : AppColors.mintSurface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryTealDark : AppColors.mintBorder,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: AppColors.primaryTealGlow,
                                blurRadius: 10.0,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$mins Menit',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDarkPrimary,
                        fontSize: 18.0,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.spaceMD),

            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              decoration: BoxDecoration(
                color: AppColors.primaryTealLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primaryTealDark, size: 22.0),
                  const SizedBox(width: AppDimensions.spaceSM),
                  Expanded(
                    child: Text(
                      'Jika waktu habis tanpa konfirmasi aman, alarm darurat otomatis dikirim ke relawan.',
                      style: AppTypography.standardCaption(color: AppColors.primaryTealDeep),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),

            // Tombol Mulai
            AccessibleButton(
              label: 'MULAI PENGAWASAN ($_selectedMinutes MENIT)',
              onPressed: () {
                SafetyCheckService.instance.startSafetyCheck(
                  durationMinutes: _selectedMinutes,
                  onEmergencyTriggered: widget.onStart,
                );
                Navigator.of(context).pop();
              },
              backgroundColor: AppColors.primaryTeal,
              customHeight: 64.0,
              icon: Icons.play_arrow_rounded,
            ),
            const SizedBox(height: AppDimensions.spaceSM),

            // Tombol Batal
            AccessibleButton(
              label: 'Batal',
              onPressed: () => Navigator.of(context).pop(),
              isSecondary: true,
              customHeight: 52.0,
            ),
          ],
        ),
      ),
    );
  }
}
