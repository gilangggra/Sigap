import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/theme/app_typography.dart';

/// Halaman pembuka untuk inisialisasi lingkungan dan pemeriksaan sesi login
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    // Jeda sejenak untuk visual branding dan kesiapan service
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final session = SupabaseService.instance.currentSession;
    if (session != null) {
      // User telah memiliki session aktif
      final authState = ref.read(authStateProvider);
      _navigateBasedOnRole(authState.role);
    } else {
      // Belum login, arahkan ke alur registrasi/login
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
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.0,
                height: 100.0,
                decoration: const BoxDecoration(
                  color: AppColors.emergencyRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergencyRedGlow,
                      blurRadius: 24.0,
                      spreadRadius: 4.0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 56.0,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceLG),
              Text(
                AppConstants.appName,
                style: AppTypography.seniorHeadingLarge(color: Colors.white),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.emergencyRed),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

