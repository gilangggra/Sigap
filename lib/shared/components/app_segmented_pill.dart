import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/feedback_service.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';

/// Item data model untuk [AppSegmentedPill]
class SegmentItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? badge;

  const SegmentItem({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
  });
}

/// Kontrol tersegmentasi berbentuk Pill bergaya modern (seperti "Info | Booking" pada desain referensi).
/// Mendukung transisi halus, indikator pill aktif berwarna Teal dengan teks putih, dan haptic feedback.
class AppSegmentedPill<T> extends StatelessWidget {
  final List<SegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final double height;

  const AppSegmentedPill({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onValueChanged,
    this.height = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.lightBorder, width: 0.8),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  FeedbackService.instance.triggerSuccessFeedback();
                  onValueChanged(item.value);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  boxShadow: isSelected ? AppShadows.subtle : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 16.0,
                        color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                      ),
                      const SizedBox(width: 6.0),
                    ],
                    Text(
                      item.label,
                      style: AppTypography.pillTabLabel(isSelected: isSelected),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(width: 6.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.primaryTealLight,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primaryTeal : AppColors.primaryTealDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
