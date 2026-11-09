import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_input_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/emergency/presentation/screens/care_receiver_home_screen.dart';
import '../../features/emergency/presentation/screens/responder_home_screen.dart';
import '../../features/wellness/presentation/screens/guardian_home_screen.dart';

/// Konfigurasi routing deklaratif modular aplikasi SIGAP menggunakan GoRouter
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: false,
  routes: <RouteBase>[
    // Rute Splash & Inisialisasi
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),

    // Rute Autentikasi: Input Nomor Telepon
    GoRoute(
      path: '/auth/phone',
      builder: (BuildContext context, GoRouterState state) {
        return const PhoneInputScreen();
      },
    ),

    // Rute Autentikasi: Verifikasi Kode OTP
    GoRoute(
      path: '/auth/otp',
      builder: (BuildContext context, GoRouterState state) {
        final phoneNumber = state.extra as String? ?? '+628123456789';
        return OtpVerificationScreen(phoneNumber: phoneNumber);
      },
    ),

    // Rute Onboarding: Pemilihan Peran Pengguna
    GoRoute(
      path: '/auth/role',
      builder: (BuildContext context, GoRouterState state) {
        return const RoleSelectionScreen();
      },
    ),

    // Rute Beranda Peran 1: Care-Receiver (Lansia / Simplified Mode)
    GoRoute(
      path: '/care-receiver',
      builder: (BuildContext context, GoRouterState state) {
        return const CareReceiverHomeScreen();
      },
    ),

    // Rute Beranda Peran 2: Community Responder (Relawan Warga)
    GoRoute(
      path: '/responder',
      builder: (BuildContext context, GoRouterState state) {
        return const ResponderHomeScreen();
      },
    ),

    // Rute Beranda Peran 3: Primary Guardian (Keluarga / Wali)
    GoRoute(
      path: '/guardian',
      builder: (BuildContext context, GoRouterState state) {
        return const GuardianHomeScreen();
      },
    ),

    // Rute Beranda Peran 4: Civic Administrator (Pengurus RT/RW)
    GoRoute(
      path: '/admin',
      builder: (BuildContext context, GoRouterState state) {
        return const AdminHomeScreen();
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Halaman tidak ditemukan: ${state.uri}'),
    ),
  ),
);

