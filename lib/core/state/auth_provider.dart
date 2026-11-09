import 'package:flutter/foundation.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/domain/models/rt_area.dart';
import '../../features/auth/domain/models/user_profile.dart';
import '../constants/app_constants.dart';

/// Provider pengelola status autentikasi dan peran aktif pengguna menggunakan Provider / ChangeNotifier
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isAuthenticated = false;
  bool _isVerified = false;
  bool _simplifiedMode = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _role = UserRole.careReceiver;
  UserProfile? _userProfile;
  RtArea? _rtArea;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  bool get isAuthenticated => _isAuthenticated;
  bool get isVerified => _isVerified;
  bool get simplifiedMode => _simplifiedMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserRole get role => _role;
  UserProfile? get userProfile => _userProfile;
  RtArea? get rtArea => _rtArea;

  String? get userId => _userProfile?.id;
  String? get phoneNumber => _userProfile?.phoneNumber;
  String? get fullName => _userProfile?.fullName;
  String? get rtAreaId => _userProfile?.rtAreaId ?? _rtArea?.id;

  /// 1. Mengirim kode OTP via SMS
  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signInWithOtp(phone);
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

  /// 2. Verifikasi kode OTP dan memuat profil
  Future<bool> verifyOtp({required String phone, required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserProfile profile = await _repository.verifyOtp(
        phoneNumber: phone,
        token: token,
      );

      _isAuthenticated = true;
      _isVerified = profile.isVerified;
      _role = profile.role;
      _simplifiedMode = profile.simplifiedMode || profile.role == UserRole.careReceiver;
      _userProfile = profile;
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

  /// 3. Pemilihan peran pengguna (Onboarding)
  Future<void> selectRole(UserRole selectedRole) async {
    _role = selectedRole;
    _simplifiedMode = selectedRole == UserRole.careReceiver;
    notifyListeners();

    if (_userProfile != null) {
      final updated = _userProfile!.copyWith(
        role: selectedRole,
        simplifiedMode: selectedRole == UserRole.careReceiver,
      );
      _userProfile = updated;
      notifyListeners();
      await _repository.upsertProfile(updated);
    }
  }

  /// 4. Validasi kode undangan RT dan bergabung
  Future<bool> joinWithInviteCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final RtArea? area = await _repository.validateRtInviteCode(code);
      if (area == null) {
        _isLoading = false;
        _errorMessage = 'Kode RT tidak valid atau telah kedaluwarsa.';
        notifyListeners();
        return false;
      }

      _rtArea = area;
      if (_userProfile != null) {
        await _repository.joinRtArea(
          userId: _userProfile!.id,
          rtAreaId: area.id,
        );
        _userProfile = _userProfile!.copyWith(
          rtAreaId: area.id,
          isVerified: false,
        );
      }
      _isVerified = false;
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

  /// Set status autentikasi manual (misal bypass demo / restore session)
  void setAuthenticated({
    required String userId,
    required String phone,
    required UserRole userRole,
    required bool isVerifiedStatus,
    String? name,
    String? areaId,
  }) {
    _userProfile = UserProfile(
      id: userId,
      fullName: name ?? 'Warga SIGAP',
      phoneNumber: phone,
      role: userRole,
      rtAreaId: areaId,
      isVerified: isVerifiedStatus,
      simplifiedMode: userRole == UserRole.careReceiver,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _isAuthenticated = true;
    _isVerified = isVerifiedStatus;
    _role = userRole;
    _simplifiedMode = userRole == UserRole.careReceiver;
    notifyListeners();
  }

  /// Toggle mode lansia / simplified mode
  void setSimplifiedMode(bool enabled) {
    _simplifiedMode = enabled;
    notifyListeners();
  }

  /// Logout dan reset sesi
  void reset() {
    _isAuthenticated = false;
    _isVerified = false;
    _simplifiedMode = true;
    _isLoading = false;
    _errorMessage = null;
    _role = UserRole.careReceiver;
    _userProfile = null;
    _rtArea = null;
    notifyListeners();
  }
}

