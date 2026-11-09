import 'package:flutter/foundation.dart';
import '../../data/repositories/task_repository.dart';
import '../../domain/models/social_credit.dart';
import '../../domain/models/task_item.dart';

/// Provider pengelola status tugas bantuan mikro warga dan poin sosial relawan
class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;

  List<TaskItem> _nearbyTasks = <TaskItem>[];
  final List<TaskItem> _myClaimedTasks = <TaskItem>[];
  List<LeaderboardEntry> _leaderboard = <LeaderboardEntry>[];
  TaskCategory? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  TaskProvider({TaskRepository? repository})
      : _repository = repository ?? TaskRepository();

  List<TaskItem> get nearbyTasks {
    if (_selectedCategory == null) return _nearbyTasks;
    return _nearbyTasks.where((task) => task.category == _selectedCategory).toList();
  }

  List<TaskItem> get myClaimedTasks => _myClaimedTasks;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  TaskCategory? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 1. Memuat daftar tugas terbuka di sekitar radius 800m
  Future<void> loadNearbyTasks({
    double latitude = -6.2088,
    double longitude = 106.8456,
    String? rtAreaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tasks = await _repository.getNearbyTasks(
        latitude: latitude,
        longitude: longitude,
        rtAreaId: rtAreaId,
      );
      _nearbyTasks = tasks;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 2. Mengambil / mengklaim tugas oleh relawan
  Future<bool> acceptTask({
    required String taskId,
    required String responderId,
    required String responderName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.acceptTask(
        taskId: taskId,
        responderId: responderId,
        responderName: responderName,
      );

      _nearbyTasks.removeWhere((t) => t.id == taskId);
      _myClaimedTasks.insert(0, updated);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 3. Menyelesaikan tugas (+10 Poin Sosial)
  Future<bool> completeTask({
    required String taskId,
    required String responderId,
    String? completionNotes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final completed = await _repository.completeTask(
        taskId: taskId,
        responderId: responderId,
        completionNotes: completionNotes,
      );

      _myClaimedTasks.removeWhere((t) => t.id == taskId);
      _myClaimedTasks.insert(0, completed);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 4. Membuat permohonan tiket bantuan baru oleh Care-Receiver / Guardian
  Future<bool> createTask({
    required String createdBy,
    required String careReceiverId,
    required String careReceiverName,
    required TaskCategory category,
    required String description,
    required String destinationAddress,
    DateTime? neededBefore,
    String? rtAreaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.createTask(
        createdBy: createdBy,
        careReceiverId: careReceiverId,
        careReceiverName: careReceiverName,
        category: category,
        description: description,
        destinationAddress: destinationAddress,
        neededBefore: neededBefore,
        rtAreaId: rtAreaId,
      );

      _nearbyTasks.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 5. Memuat Papan Peringkat Relawan RT (Leaderboard)
  Future<void> loadLeaderboard(String rtAreaId) async {
    try {
      final entries = await _repository.getRtLeaderboard(rtAreaId);
      _leaderboard = entries;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 6. Mengubah filter kategori
  void setCategoryFilter(TaskCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
