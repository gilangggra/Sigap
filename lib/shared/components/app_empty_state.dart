import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'accessible_button.dart';

/// Komponen Empty State standar mobile.
/// Memberikan panduan visual yang bersahabat ketika tidak ada data atau tugas yang aktif.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color iconColor;
  final Color iconContainerColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
    this.iconColor = AppColors.primaryTeal,
    this.iconContainerColor = AppColors.primaryTealLight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: iconContainerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38.0,
                color: iconColor,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceLG),
            Text(
              title,
              style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            Text(
              description,
              style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: AppDimensions.spaceXL),
              AccessibleButton(
                label: actionLabel!,
                onPressed: onActionPressed,
                customHeight: 48.0,
                customRadius: AppDimensions.radiusMD,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
