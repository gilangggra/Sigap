import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/location_service.dart';
import 'core/services/supabase_service.dart';
import 'core/state/auth_state.dart';
import 'core/theme/app_theme.dart';

/// Titik masuk utama aplikasi SIGAP (Civic Mutual-Aid & Caregiver Network)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Muat environment variable (.env) jika tersedia
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      print('✅ [main] Berhasil memuat file konfigurasi .env');
    }
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env.example');
      if (kDebugMode) {
        print('ℹ️ [main] File .env tidak ditemukan, menggunakan .env.example sebagai fallback');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [main] Berjalan tanpa file .env lokal (menggunakan konfigurasi default)');
      }
    }
  }

  // 2. Inisialisasi Supabase Client & PostGIS Remote Procedures
  await SupabaseService.instance.initialize();

  // 3. Pra-pemeriksaan status perizinan geolokasi
  try {
    await LocationService.instance.checkPermission();
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ [main] Pemeriksaan perizinan lokasi ditunda: $e');
    }
  }

  // 4. Jalankan aplikasi dibungkus Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: SigapApp(),
    ),
  );
}

/// Widget root aplikasi SIGAP
class SigapApp extends ConsumerWidget {
  const SigapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Otomatis memilih tema:
    // Jika peran adalah Care-Receiver (Lansia) atau simplifiedMode aktif,
    // gunakan [AppTheme.seniorTheme] dengan rasio kontras maksimal dan tombol besar.
    final ThemeData activeTheme = (authState.simplifiedMode || authState.role == UserRole.careReceiver)
        ? AppTheme.seniorTheme
        : AppTheme.darkTheme;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: AppTheme.seniorTheme,
      themeMode: ThemeMode.dark, // Default gelap untuk aksesibilitas kontras tinggi
      routerConfig: appRouter,
    );
  }
}

