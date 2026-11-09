import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';

/// Halaman input kode RT/RW unik untuk verifikasi domisili warga di lingkungan terkait.
class RtCodeInputScreen extends StatefulWidget {
  const RtCodeInputScreen({super.key});

  @override
  State<RtCodeInputScreen> createState() => _RtCodeInputScreenState();
}

class _RtCodeInputScreenState extends State<RtCodeInputScreen> {
  final TextEditingController _codeController = TextEditingController(text: 'SIGAP-RT03-26');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleValidateCode() async {
    final String code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length < 6) {
      setState(() {
        _errorMessage = 'Masukkan kode RT yang valid (contoh: SIGAP-RT03-26).';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.joinWithInviteCode(code);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      unawaited(FeedbackService.instance.triggerSuccessFeedback());
      if (mounted) {
        context.go('/auth/pending-verification');
      }
    } else {
      unawaited(FeedbackService.instance.triggerWarningFeedback());
      if (mounted) {
        setState(() {
          _errorMessage = authProvider.errorMessage ??
              'Kode RT tidak ditemukan atau sudah kedaluwarsa.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Verifikasi Domisili RT/RW'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masukkan Kode RT Anda',
                style: AppTypography.seniorHeadingMedium(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Text(
                'Kode unik ini diperoleh dari Pengurus RT setempat untuk memastikan Anda adalah warga yang terdaftar.',
                style: AppTypography.seniorBodyPrimary(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.emergencyRed
                        : AppColors.darkBorderHighContrast,
                    width: AppDimensions.highContrastBorderWidth,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceLG,
                  vertical: AppDimensions.spaceMD,
                ),
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'SIGAP-RTXX-XX',
                    hintStyle: TextStyle(
                      color: AppColors.textDarkTertiary,
                      letterSpacing: 2.0,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppDimensions.spaceSM),
                Text(
                  _errorMessage!,
                  style: AppTypography.seniorBodySecondary(color: AppColors.emergencyRedLight),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppDimensions.spaceMD),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.infoBlueLight),
                    const SizedBox(width: AppDimensions.spaceMD),
                    Expanded(
                      child: Text(
                        'Untuk demonstrasi, kode default lingkungan aktif adalah: SIGAP-RT03-26',
                        style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space2XL),
              AccessibleButton(
                label: _isLoading ? 'Memverifikasi Lingkungan...' : 'Gabung Lingkungan RT',
                onPressed: _isLoading ? null : _handleValidateCode,
                isSimplified: true,
                backgroundColor: AppColors.infoBlue,
                icon: Icons.domain_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
