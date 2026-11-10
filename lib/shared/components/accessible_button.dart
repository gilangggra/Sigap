import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/feedback_service.dart';
import '../../core/theme/app_typography.dart';

/// Tombol berstandar aksesibilitas tinggi untuk SIGAP dengan gaya modern Pill Button (Healthcare).
/// Memastikan ukuran target sentuh minimum (min 64dp untuk lansia, 72dp untuk simplified),
/// kontras warna WCAG AA/AAA, getaran konfirmasi saat ditekan, dan bentuk pill ergonomis.
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isSimplified;
  final bool isSecondary;
  final double? customHeight;
  final double? customRadius;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.primaryTeal,
    this.textColor = Colors.white,
    this.borderColor,
    this.isSimplified = false,
    this.isSecondary = false,
    this.customHeight,
    this.customRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Memenuhi standar aksesibilitas minimum (min 64dp, simplified 72dp)
    final double targetHeight = customHeight ??
        (isSimplified
            ? AppDimensions.seniorRecommendedTouchTarget
            : AppDimensions.seniorMinTouchTarget);

    final double effectiveRadius = customRadius ?? AppDimensions.radiusPill;

    final Color effectiveBg = isSecondary
        ? (isSimplified ? AppColors.mintSurface : Colors.transparent)
        : backgroundColor;

    final Color effectiveText = isSecondary
        ? (isSimplified ? AppColors.textDarkPrimary : AppColors.primaryTealDark)
        : textColor;

    final BorderSide borderSide = isSecondary || borderColor != null
        ? BorderSide(
            color: borderColor ??
                (isSimplified
                    ? AppColors.primaryTeal
                    : AppColors.primaryTeal.withValues(alpha: 0.6)),
            width: isSimplified
                ? AppDimensions.highContrastBorderWidth
                : AppDimensions.standardBorderWidth,
          )
        : BorderSide.none;

    final TextStyle textStyle = isSimplified
        ? AppTypography.seniorButtonLabel(color: effectiveText)
        : AppTypography.standardButtonLabel(color: effectiveText);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Material(
        color: effectiveBg,
        elevation: isSecondary ? 0 : AppDimensions.elevationLow,
        shadowColor: AppColors.primaryTealGlow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effectiveRadius),
          side: borderSide,
        ),
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  unawaited(FeedbackService.instance.triggerSuccessFeedback());
                  onPressed!();
                },
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: Container(
            constraints: BoxConstraints(
              minHeight: targetHeight,
              minWidth: double.infinity,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSimplified ? AppDimensions.spaceLG : AppDimensions.spaceMD,
              vertical: isSimplified ? AppDimensions.spaceMD : AppDimensions.spaceSM,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: effectiveText,
                    size: isSimplified ? 28.0 : 22.0,
                  ),
                  SizedBox(
                    width: isSimplified ? AppDimensions.spaceMD : AppDimensions.spaceSM,
                  ),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: textStyle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
