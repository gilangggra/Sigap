import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/sync_service.dart';
import 'core/state/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/emergency/presentation/state/emergency_provider.dart';
import 'features/microtask/presentation/state/task_provider.dart';
import 'features/profile/presentation/state/profile_provider.dart';
import 'features/wellness/presentation/state/wellness_provider.dart';

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

  // 4. Inisialisasi Service Notifikasi & Permintaan Izin
  try {
    await NotificationService.instance.initialize(
      onNotificationTap: (payload) {
        if (payload.isNotEmpty) {
          appRouter.push(payload);
        }
      },
    );
    await NotificationService.instance.requestPermission();
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ [main] Inisialisasi notifikasi ditunda: $e');
    }
  }

  // 5. Inisialisasi Autonomous Network Sync Manager
  try {
    await SyncService.instance.initialize();
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ [main] Inisialisasi SyncService ditunda: $e');
    }
  }

  // 6. Jalankan aplikasi dibungkus MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
        ChangeNotifierProvider<EmergencyProvider>(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider<WellnessProvider>(create: (_) => WellnessProvider()),
        ChangeNotifierProvider<TaskProvider>(create: (_) => TaskProvider()),
      ],
      child: const SigapApp(),
    ),
  );
}

/// Widget root aplikasi SIGAP
class SigapApp extends StatelessWidget {
  const SigapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Otomatis memilih tema:
    // Jika peran adalah Care-Receiver (Lansia) atau simplifiedMode aktif,
    // gunakan [AppTheme.seniorTheme] dengan rasio kontras tinggi dan tombol pill besar.
    // Untuk peran lainnya, gunakan [AppTheme.lightTheme] (Healthcare Teal-Mint Design System).
    final ThemeData activeTheme = (authProvider.simplifiedMode || authProvider.role == UserRole.careReceiver)
        ? AppTheme.seniorTheme
        : AppTheme.lightTheme;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default tema terang Healthcare Teal-Mint sesuai Design System
      routerConfig: appRouter,
    );
  }
}
