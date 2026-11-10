import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';

/// Bilah Pencarian / Filter cepat modern standar mobile (sesuai referensi UI).
/// Menggunakan wadah putih bersih, radius pill (24dp), bayangan ambient lembut,
/// ikon pencarian di kiri, dan tombol reset di kanan.
class AppSearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;
  final bool hasFilterButton;

  const AppSearchField({
    super.key,
    this.hintText = 'Cari...',
    this.onChanged,
    this.onFilterTap,
    this.controller,
    this.hasFilterButton = false,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _internalController;
  bool _canClear = false;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _internalController.addListener(_updateClearState);
  }

  void _updateClearState() {
    final hasText = _internalController.text.isNotEmpty;
    if (_canClear != hasText) {
      setState(() => _canClear = hasText);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.lightBorder, width: 0.8),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDimensions.spaceMD),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textDarkTertiary,
            size: 20.0,
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          Expanded(
            child: TextField(
              controller: _internalController,
              onChanged: widget.onChanged,
              style: AppTypography.standardBody(color: AppColors.textDarkPrimary),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_canClear)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18.0, color: AppColors.textDarkTertiary),
              onPressed: () {
                _internalController.clear();
                widget.onChanged?.call('');
              },
            ),
          if (widget.hasFilterButton) ...[
            Container(
              height: 24.0,
              width: 1.0,
              color: AppColors.lightBorder,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded, size: 18.0, color: AppColors.primaryTealDark),
              tooltip: 'Filter',
              onPressed: widget.onFilterTap,
            ),
          ],
          const SizedBox(width: AppDimensions.spaceSM),
        ],
      ),
    );
  }
}

