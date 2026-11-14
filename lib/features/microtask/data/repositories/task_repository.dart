import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/social_credit.dart';
import '../../domain/models/task_item.dart';

/// Repository untuk mengelola tugas bantuan mikro tetangga (tabel `tasks` & `social_credits`)
class TaskRepository {
  final SupabaseService _supabaseService;

  TaskRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  // Mock data tugas aktif di sekitar RT
  final List<TaskItem> _mockTasks = [
    TaskItem(
      id: 'task-001',
      createdBy: 'guardian-001',
      careReceiverId: 'care-receiver-001',
      careReceiverName: 'Ibu Aminah (71 thn)',
      category: TaskCategory.ambilResep,
      description: 'Tolong ambilkan resep obat hipertensi di Puskesmas Kelurahan.',
      destinationAddress: 'Puskesmas Kenanga, Jl. Melati No. 5',
      destinationLatitude: -6.2090,
      destinationLongitude: 106.8460,
      neededBefore: DateTime.now().add(const Duration(hours: 3)),
      status: TaskStatus.open,
      rtAreaId: 'rt-001',
      distanceMeters: 320,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    TaskItem(
      id: 'task-002',
      createdBy: 'care-receiver-002',
      careReceiverId: 'care-receiver-002',
      careReceiverName: 'Bapak Hartono (68 thn)',
      category: TaskCategory.belanjaLogistik,
      description: 'Titip beli beras 5kg dan minyak goreng di warung depan gang.',
      destinationAddress: 'Warung Bu Siti, RT 02 / RW 05',
      destinationLatitude: -6.2095,
      destinationLongitude: 106.8470,
      neededBefore: DateTime.now().add(const Duration(hours: 5)),
      status: TaskStatus.open,
      rtAreaId: 'rt-001',
      distanceMeters: 450,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    TaskItem(
      id: 'task-003',
      createdBy: 'guardian-003',
      careReceiverId: 'care-receiver-003',
      careReceiverName: 'Ibu Sutrisno (74 thn)',
      category: TaskCategory.pendampinganMobilitas,
      description: 'Pendampingan jalan kaki menuju pemeriksaan lansia Posyandu Melati.',
      destinationAddress: 'Balai RW 05',
      destinationLatitude: -6.2100,
      destinationLongitude: 106.8480,
      neededBefore: DateTime.now().add(const Duration(hours: 6)),
      status: TaskStatus.open,
      rtAreaId: 'rt-001',
      distanceMeters: 600,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  /// 1. Mengambil daftar tugas bantuan terbuka di sekitar (radius 800m)
  Future<List<TaskItem>> getNearbyTasks({
    required double latitude,
    required double longitude,
    double radiusMeters = 800.0,
    String? rtAreaId,
  }) async {
    if (_supabaseService.isInitialized) {
      try {
        final response = await _supabaseService.client
            .from('tasks')
            .select()
            .eq('status', 'open')
            .order('created_at', ascending: false);

        if (response.isNotEmpty) {
          return (response as List)
              .map((data) => TaskItem.fromJson(Map<String, dynamic>.from(data as Map)))
              .toList();
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [TaskRepository] Error fetch tasks Supabase, fallback ke mock: $e');
        }
      }
    }
    return List<TaskItem>.from(_mockTasks.where((t) => t.status == TaskStatus.open));
  }

  /// 2. Membuat tiket permohonan bantuan baru oleh Care-Receiver / Guardian
  Future<TaskItem> createTask({
    required String createdBy,
    required String careReceiverId,
    required String careReceiverName,
    required TaskCategory category,
    required String description,
    required String destinationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    DateTime? neededBefore,
    String? rtAreaId,
  }) async {
    final newTask = TaskItem(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      createdBy: createdBy,
      careReceiverId: careReceiverId,
      careReceiverName: careReceiverName,
      category: category,
      description: description,
      destinationAddress: destinationAddress,
      destinationLatitude: destinationLatitude ?? -6.2088,
      destinationLongitude: destinationLongitude ?? 106.8456,
      neededBefore: neededBefore ?? DateTime.now().add(const Duration(hours: 4)),
      status: TaskStatus.open,
      rtAreaId: rtAreaId ?? 'rt-001',
      distanceMeters: 250,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_supabaseService.isInitialized &&
        _supabaseService.currentUser != null &&
        AppConstants.isValidUuid(createdBy) &&
        AppConstants.isValidUuid(careReceiverId) &&
        createdBy != AppConstants.demoUserId) {
      try {
        final payload = newTask.toJson();
        payload.remove('distance_meters');
        final response = await _supabaseService.client
            .from('tasks')
            .insert(payload)
            .select()
            .single();

        return TaskItem.fromJson(Map<String, dynamic>.from(response));
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [TaskRepository] Error insert task Supabase, fallback ke lokal: $e');
        }
      }
    }

    _mockTasks.insert(0, newTask);
    return newTask;
  }

  /// 3. Mengambil / mengklaim tugas bantuan oleh Relawan (Optimistic Lock)
  Future<TaskItem> acceptTask({
    required String taskId,
    required String responderId,
    required String responderName,
  }) async {
    if (_supabaseService.isInitialized &&
        _supabaseService.currentUser != null &&
        AppConstants.isValidUuid(taskId) &&
        AppConstants.isValidUuid(responderId) &&
        responderId != AppConstants.demoUserId) {
      try {
        final response = await _supabaseService.client
            .from('tasks')
            .update({
              'status': 'accepted',
              'responder_id': responderId,
              'accepted_at': DateTime.now().toIso8601String(),
            })
            .eq('id', taskId)
            .eq('status', 'open') // Optimistic lock agar tidak direbut relawan lain
            .select()
            .single();

        return TaskItem.fromJson(Map<String, dynamic>.from(response));
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [TaskRepository] Error accept task Supabase: $e');
        }
      }
    }

    final index = _mockTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updated = _mockTasks[index].copyWith(
        status: TaskStatus.accepted,
        responderId: responderId,
        responderName: responderName,
        acceptedAt: DateTime.now(),
      );
      _mockTasks[index] = updated;
      return updated;
    }

    throw Exception('Tugas tidak ditemukan atau telah diambil oleh relawan lain.');
  }

  /// 4. Menandai tugas telah selesai oleh relawan (+10 Poin Sosial)
  Future<TaskItem> completeTask({
    required String taskId,
    required String responderId,
    String? completionNotes,
  }) async {
    if (_supabaseService.isInitialized &&
        _supabaseService.currentUser != null &&
        AppConstants.isValidUuid(taskId) &&
        AppConstants.isValidUuid(responderId) &&
        responderId != AppConstants.demoUserId) {
      try {
        final response = await _supabaseService.client
            .from('tasks')
            .update({
              'status': 'completed',
              'completed_at': DateTime.now().toIso8601String(),
              'completion_notes': completionNotes ?? 'Tugas selesai dengan baik.',
            })
            .eq('id', taskId)
            .eq('responder_id', responderId)
            .select()
            .single();

        return TaskItem.fromJson(Map<String, dynamic>.from(response));
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [TaskRepository] Error complete task Supabase: $e');
        }
      }
    }

    final index = _mockTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updated = _mockTasks[index].copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
        completionNotes: completionNotes ?? 'Tugas selesai dengan baik.',
      );
      _mockTasks[index] = updated;
      return updated;
    }

    throw Exception('Tugas tidak ditemukan.');
  }

  /// 5. Mengambil papan peringkat relawan RT (Social Credit Leaderboard)
  Future<List<LeaderboardEntry>> getRtLeaderboard(String rtAreaId) async {
    // Mock daftar peringkat warga relawan aktif
    return const [
      LeaderboardEntry(
        responderId: 'resp-001',
        responderName: 'Budi Santoso',
        totalPoints: 210,
        tasksCompleted: 11,
        emergencyResponses: 2,
        rank: 1,
      ),
      LeaderboardEntry(
        responderId: 'resp-002',
        responderName: 'Dewi Lestari',
        totalPoints: 170,
        tasksCompleted: 7,
        emergencyResponses: 2,
        rank: 2,
      ),
      LeaderboardEntry(
        responderId: 'resp-003',
        responderName: 'Ahmad Fauzi',
        totalPoints: 120,
        tasksCompleted: 7,
        emergencyResponses: 1,
        rank: 3,
      ),
      LeaderboardEntry(
        responderId: 'resp-004',
        responderName: 'Rudi Hermawan',
        totalPoints: 80,
        tasksCompleted: 3,
        emergencyResponses: 1,
        rank: 4,
      ),
    ];
  }
}
