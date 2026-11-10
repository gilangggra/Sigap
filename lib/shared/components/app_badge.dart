import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

enum AppBadgeVariant {
  brand,
  success,
  warning,
  danger,
  neutral,
  outline,
}

/// Badge status berbentuk pill standar mobile modern.
/// Menggunakan warna pastel lembut dengan teks kontras tinggi untuk keterbacaan optimal.
class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppBadgeVariant variant;
  final bool isSmall;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AppBadgeVariant.neutral,
    this.isSmall = false,
  });

  factory AppBadge.brand(String label, {IconData? icon, bool isSmall = false}) =>
      AppBadge(label: label, icon: icon, variant: AppBadgeVariant.brand, isSmall: isSmall);

  factory AppBadge.success(String label, {IconData? icon, bool isSmall = false}) =>
      AppBadge(label: label, icon: icon, variant: AppBadgeVariant.success, isSmall: isSmall);

  factory AppBadge.warning(String label, {IconData? icon, bool isSmall = false}) =>
      AppBadge(label: label, icon: icon, variant: AppBadgeVariant.warning, isSmall: isSmall);

  factory AppBadge.danger(String label, {IconData? icon, bool isSmall = false}) =>
      AppBadge(label: label, icon: icon, variant: AppBadgeVariant.danger, isSmall: isSmall);

  factory AppBadge.neutral(String label, {IconData? icon, bool isSmall = false}) =>
      AppBadge(label: label, icon: icon, variant: AppBadgeVariant.neutral, isSmall: isSmall);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case AppBadgeVariant.brand:
        bg = AppColors.primaryTealWash;
        fg = AppColors.primaryTealDark;
        border = Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3), width: 1.0);
        break;
      case AppBadgeVariant.success:
        bg = AppColors.safeGreenWash;
        fg = AppColors.safeGreenDark;
        border = Border.all(color: AppColors.safeGreen.withValues(alpha: 0.3), width: 1.0);
        break;
      case AppBadgeVariant.warning:
        bg = AppColors.warningAmberWash;
        fg = AppColors.warningAmberDark;
        border = Border.all(color: AppColors.warningAmber.withValues(alpha: 0.3), width: 1.0);
        break;
      case AppBadgeVariant.danger:
        bg = AppColors.emergencyRedWash;
        fg = AppColors.emergencyRedDark;
        border = Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3), width: 1.0);
        break;
      case AppBadgeVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.textDarkSecondary;
        border = Border.all(color: AppColors.lightBorder, width: 1.0);
        break;
      case AppBadgeVariant.neutral:
        bg = AppColors.neutralWash;
        fg = AppColors.textDarkSecondary;
        border = Border.all(color: AppColors.lightBorder, width: 0.8);
        break;
    }

    final verticalPadding = isSmall ? 2.0 : 4.0;
    final horizontalPadding = isSmall ? 8.0 : 10.0;
    final iconSize = isSmall ? 12.0 : 14.0;
    final textStyle = isSmall
        ? AppTypography.standardCaption(color: fg).copyWith(fontWeight: FontWeight.w600, fontSize: 11.0)
        : AppTypography.standardCaption(color: fg).copyWith(fontWeight: FontWeight.w600);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: 4.0),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

