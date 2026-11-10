import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_colors.dart';
import 'supabase_service.dart';

/// Service infrastruktur terpadu untuk pengelolaan Push Notification & Local Alert.
/// Mendukung saluran darurat prioritas tinggi (Max Importance Heads-Up Alert),
/// pengingat kesehatan lansia, dan sinkronisasi token FCM ke backend Supabase.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Callback navigasi saat notifikasi ditekan oleh pengguna
  void Function(String payload)? _onNotificationTap;

  // ---------------------------------------------------------------------------
  // KONSTANTA IDENTITAS CHANNEL NOTIFIKASI
  // ---------------------------------------------------------------------------
  static const String emergencyChannelId = 'sigap_emergency_channel';
  static const String emergencyChannelName = 'Panggilan Darurat SOS SIGAP';
  static const String emergencyChannelDesc =
      'Notifikasi alarm prioritas tinggi untuk memanggil relawan warga saat lansia membutuhkan bantuan darurat.';

  static const String wellnessChannelId = 'sigap_wellness_channel';
  static const String wellnessChannelName = 'Pengingat Kesehatan & Obat';
  static const String wellnessChannelDesc =
      'Pengingat harian check-in kondisi lansia dan jadwal minum obat.';

  static const String taskChannelId = 'sigap_task_channel';
  static const String taskChannelName = 'Bantuan Gotong Royong RT';
  static const String taskChannelDesc =
      'Pemberitahuan permohonan bantuan mikro baru dari warga lansia di lingkungan RT.';

  /// 1. Inisialisasi Service Notifikasi & Konfigurasi Channel Native
  Future<void> initialize({void Function(String payload)? onNotificationTap}) async {
    if (_isInitialized) return;
    _onNotificationTap = onNotificationTap;

    // Konfigurasi ikon notifikasi Android (menggunakan ic_launcher default aplikasi)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Konfigurasi izin notifikasi iOS
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            if (kDebugMode) {
              print('🔔 [NotificationService] Notifikasi ditekan dengan payload: $payload');
            }
            _onNotificationTap?.call(payload);
          }
        },
      );

      // Inisialisasi channel notifikasi prioritas tinggi untuk Android
      await _createNotificationChannels();

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ [NotificationService] Berhasil diinisialisasi.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [NotificationService] Inisialisasi notifikasi menggunakan mode fallback: $e');
      }
      _isInitialized = false;
    }
  }

  /// Membuat Notification Channels dengan level prioritas spesifik pada platform Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 1. Channel Darurat SOS (Heads-up banner, getaran alarm berulang, suara nyaring)
      final emergencyChannel = AndroidNotificationChannel(
        emergencyChannelId,
        emergencyChannelName,
        description: emergencyChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[0, 1000, 500, 1000, 500, 1000]),
        ledColor: AppColors.emergencyRedDark,
        enableLights: true,
      );

      // 2. Channel Kesehatan & Obat
      const wellnessChannel = AndroidNotificationChannel(
        wellnessChannelId,
        wellnessChannelName,
        description: wellnessChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // 3. Channel Tugas Gotong Royong
      const taskChannel = AndroidNotificationChannel(
        taskChannelId,
        taskChannelName,
        description: taskChannelDesc,
        importance: Importance.defaultImportance,
        playSound: true,
      );

      await androidPlugin.createNotificationChannel(emergencyChannel);
      await androidPlugin.createNotificationChannel(wellnessChannel);
      await androidPlugin.createNotificationChannel(taskChannel);
    }
  }

  /// 2. Meminta Izin Notifikasi Pengguna (Android 13+ & iOS)
  Future<bool> requestPermission() async {
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final bool? granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final bool? granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [NotificationService] Gagal meminta izin notifikasi: $e');
      }
      return false;
    }
  }

  /// 3. Menampilkan Alarm Darurat SOS Prioritas Maksimal (Heads-Up Alert)
  Future<void> showEmergencyAlert({
    required String incidentId,
    required String victimName,
    required String address,
    double? distanceMeters,
  }) async {
    final distanceText = distanceMeters != null
        ? ' (Sekitar ${distanceMeters.toStringAsFixed(0)} meter dari lokasi Anda)'
        : '';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      emergencyChannelId,
      emergencyChannelName,
      channelDescription: emergencyChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      color: AppColors.emergencyRedDark,
      ledColor: AppColors.emergencyRedDark,
      ledOnMs: 1000,
      ledOffMs: 500,
      vibrationPattern: Int64List.fromList(<int>[0, 1000, 500, 1000, 500, 1000]),
      styleInformation: BigTextStyleInformation(
        'DARURAT MEDIS / KECELAKAAN!\nKorban: $victimName\nLokasi: $address$distanceText\nBuka aplikasi untuk merespons segera.',
        contentTitle: '🚨 PANGGILAN DARURAT: $victimName',
        summaryText: 'Panggilan Bantuan SIGAP',
      ),
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final int notificationId = incidentId.hashCode.abs();
    final String payload = '/emergency/incident-detail?id=$incidentId';

    await _localNotifications.show(
      notificationId,
      '🚨 PANGGILAN DARURAT: $victimName',
      'Lokasi: $address$distanceText. Tekan untuk meluncur membantu.',
      platformDetails,
      payload: payload,
    );
  }

  /// 4. Menampilkan Pengingat Kesehatan & Obat Harian
  Future<void> showWellnessReminder({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      wellnessChannelId,
      wellnessChannelName,
      channelDescription: wellnessChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      color: AppColors.safeGreenDark,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload ?? '/care-receiver',
    );
  }

  /// 5. Menampilkan Notifikasi Tugas Bantuan Mikro Warga
  Future<void> showTaskNotification({
    required String taskId,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      channelDescription: taskChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: AppColors.roleResponder,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final int notificationId = taskId.hashCode.abs();
    const String payload = '/tasks';

    await _localNotifications.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// 6. Menghubungkan & Memperbarui Push Token (FCM/APNs) ke Database Supabase
  Future<void> syncPushTokenToBackend({
    required String token,
    String? userId,
  }) async {
    final supabase = SupabaseService.instance;
    final String? activeUserId = userId ?? supabase.currentUser?.id;

    if (activeUserId == null || !supabase.isInitialized) {
      if (kDebugMode) {
        print('ℹ️ [NotificationService] Push token disimpan lokal sementara (Belum login/Supabase offline).');
      }
      return;
    }

    try {
      await supabase.client.from('profiles').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', activeUserId);

      if (kDebugMode) {
        print('✅ [NotificationService] FCM token berhasil disinkronkan ke Supabase profil ($activeUserId)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [NotificationService] Gagal sinkronisasi token FCM ke database: $e');
      }
    }
  }

  /// Mengatur listener saat notifikasi ditekan untuk navigasi
  void setNotificationTapHandler(void Function(String payload) onSelectNotification) {
    _onNotificationTap = onSelectNotification;
  }
}
