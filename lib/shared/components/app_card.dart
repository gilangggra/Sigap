import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_decorations.dart';

/// Kartu standar mobile modern untuk seluruh aplikasi SIGAP.
/// Menggabungkan permukaan putih bersih, radius sudut ergonomis (16dp),
/// ambient shadow lembut, border halus, serta dukungan tap ink-ripple.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Border? border;
  final double? borderRadius;
  final List<BoxShadow>? shadows;
  final bool hasGlow;
  final Color glowColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spaceMD),
    this.margin,
    this.onTap,
    this.backgroundColor = AppColors.cardWhite,
    this.border,
    this.borderRadius,
    this.shadows,
    this.hasGlow = false,
    this.glowColor = AppColors.primaryTealGlow,
  });

  /// Factory untuk kartu interaktif dengan border aksen saat disentuh
  factory AppCard.interactive({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool isSelected = false,
  }) {
    return AppCard(
      key: key,
      onTap: onTap,
      padding: padding,
      margin: margin,
      border: isSelected ? AppBorders.tealActive : AppBorders.standard,
      backgroundColor: isSelected ? AppColors.primaryTealWash : AppColors.cardWhite,
      shadows: isSelected ? AppShadows.tealGlow : AppShadows.card,
      child: child,
    );
  }

  /// Factory untuk kartu alert atau darurat
  factory AppCard.emergency({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AppCard(
      key: key,
      onTap: onTap,
      padding: padding,
      margin: margin,
      backgroundColor: AppColors.emergencyRedWash,
      border: AppBorders.emergency,
      shadows: AppShadows.emergencyGlow,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? AppDimensions.radiusCard;
    final effectiveBorder = border ?? AppBorders.standard;
    final effectiveShadows = shadows ?? (hasGlow
        ? [
            BoxShadow(
              color: glowColor,
              blurRadius: 16.0,
              offset: const Offset(0, 4),
            ),
          ]
        : AppShadows.card);

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: effectiveBorder,
        boxShadow: effectiveShadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: cardContent,
          ),
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: cardContent);
    }

    return cardContent;
  }
}

