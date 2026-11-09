import 'package:flutter/foundation.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/ice_card.dart';

/// Provider pengelola profil medis darurat (ICE Card) dan data lansia binaan
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  IceCard? _iceCard;
  IceCard? _emergencyIceCard;
  bool _isLoading = false;
  String? _errorMessage;
  List<UserProfile> _monitoredLansia = <UserProfile>[];

  ProfileProvider({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  IceCard? get iceCard => _iceCard;
  IceCard? get emergencyIceCard => _emergencyIceCard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserProfile> get monitoredLansia => _monitoredLansia;

  /// 1. Memuat data ICE Card milik Care-Receiver
  Future<void> loadIceCard(String careReceiverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final card = await _repository.getIceCard(careReceiverId);
      _iceCard = card;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 2. Menyimpan atau memperbarui data ICE Card
  Future<bool> saveIceCard(IceCard card) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveIceCard(card);
      _iceCard = card;
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

  /// 3. Mengakses data medis korban saat situasi darurat via token (Responder)
  Future<bool> accessEmergencyIceCard({
    required String token,
    required String responderId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final card = await _repository.getIceCardWithEmergencyToken(
        token: token,
        responderId: responderId,
      );

      if (card != null) {
        _emergencyIceCard = card;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Token darurat tidak valid atau sudah kedaluwarsa.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 4. Memuat daftar lansia yang dipantau oleh akun Guardian
  Future<void> loadMonitoredLansia(String guardianId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _repository.getMonitoredLansia(guardianId);
      _monitoredLansia = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
