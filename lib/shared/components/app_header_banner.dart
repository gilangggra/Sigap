import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';

/// Top Hero Header Banner khas aplikasi mobile modern (seperti pada desain referensi).
/// Menampilkan gradien Teal yang teduh, kurva sudut bawah anggun (28dp),
/// teks sapaan ramah, ikon aksi, dan slot bawah fleksibel (e.g. search bar atau chip status).
class AppHeaderBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottomSlot;
  final double bottomCornerRadius;

  const AppHeaderBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottomSlot,
    this.bottomCornerRadius = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.headerBanner,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(bottomCornerRadius),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0D9488),
            blurRadius: 16.0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spaceMD,
            AppDimensions.spaceMD,
            AppDimensions.spaceMD,
            AppDimensions.spaceLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action / Navigation Row
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppDimensions.spaceMD),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.standardDisplayLarge(color: Colors.white).copyWith(
                            fontSize: 24.0,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            subtitle!,
                            style: AppTypography.standardCaption(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),

              // Bottom Slot (e.g. Search Bar or Quick Metric Filter)
              if (bottomSlot != null) ...[
                const SizedBox(height: AppDimensions.spaceMD),
                bottomSlot!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
