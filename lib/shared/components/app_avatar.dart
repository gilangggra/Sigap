import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Avatar profil modern dengan ring border halus dan opsional indikator status online/siaga.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final bool isOnline;
  final bool showBadge;
  final Color borderColor;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24.0,
    this.isOnline = false,
    this.showBadge = false,
    this.borderColor = AppColors.primaryTealLight,
    this.onTap,
  });

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'S';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    final avatarWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.0),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primaryTealLight,
            backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                ? NetworkImage(imageUrl!)
                : null,
            child: (imageUrl == null || imageUrl!.isEmpty)
                ? Text(
                    initials,
                    style: AppTypography.standardTitle(color: AppColors.primaryTealDark).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: radius * 0.75,
                    ),
                  )
                : null,
          ),
        ),
        if (showBadge)
          Positioned(
            right: 2.0,
            bottom: 2.0,
            child: Container(
              width: radius * 0.45,
              height: radius * 0.45,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.safeGreen : AppColors.textDarkTertiary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarWidget);
    }
    return avatarWidget;
  }
}
