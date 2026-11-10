import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';

/// Halaman pembuka untuk inisialisasi lingkungan dan pemeriksaan sesi login
/// Didesain dengan estetika Medis & Healthcare Modern (Sesuai Referensi Gambar).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final session = SupabaseService.instance.currentSession;
    if (session != null) {
      final auth = context.read<AuthProvider>();
      _navigateBasedOnRole(auth.role);
    } else {
      context.go('/auth/phone');
    }
  }

  void _navigateBasedOnRole(UserRole role) {
    switch (role) {
      case UserRole.careReceiver:
        context.go('/care-receiver');
        break;
      case UserRole.responder:
        context.go('/responder');
        break;
      case UserRole.guardian:
        context.go('/guardian');
        break;
      case UserRole.civicAdmin:
        context.go('/admin');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110.0,
                height: 110.0,
                decoration: const BoxDecoration(
                  color: AppColors.cardWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTealGlow,
                      blurRadius: 28.0,
                      spreadRadius: 4.0,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/branding/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryTealLight,
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.primaryTeal,
                        size: 56.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              Text(
                AppConstants.appName,
                style: AppTypography.seniorHeadingLarge(color: AppColors.primaryTealDeep),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: AppTypography.seniorBodySecondary(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.space3XL),
              const SizedBox(
                width: 32.0,
                height: 32.0,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
