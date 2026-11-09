import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/domain/models/rt_area.dart';
import '../../features/auth/domain/models/user_profile.dart';
import '../constants/app_constants.dart';

/// Provider repository autentikasi
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Model immutable status autentikasi dan peran aktif pengguna
class AuthState {
  final bool isAuthenticated;
  final bool isVerified;
  final bool simplifiedMode;
  final bool isLoading;
  final String? errorMessage;
  final UserRole role;
  final UserProfile? userProfile;
  final RtArea? rtArea;

  const AuthState({
    this.isAuthenticated = false,
    this.isVerified = false,
    this.simplifiedMode = true,
    this.isLoading = false,
    this.errorMessage,
    this.role = UserRole.careReceiver,
    this.userProfile,
    this.rtArea,
  });

  String? get userId => userProfile?.id;
  String? get phoneNumber => userProfile?.phoneNumber;
  String? get fullName => userProfile?.fullName;
  String? get rtAreaId => userProfile?.rtAreaId ?? rtArea?.id;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isVerified,
    bool? simplifiedMode,
    bool? isLoading,
    String? errorMessage,
    UserRole? role,
    UserProfile? userProfile,
    RtArea? rtArea,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isVerified: isVerified ?? this.isVerified,
      simplifiedMode: simplifiedMode ?? this.simplifiedMode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      role: role ?? this.role,
      userProfile: userProfile ?? this.userProfile,
      rtArea: rtArea ?? this.rtArea,
    );
  }
}

/// StateNotifier pengelola autentikasi dan role-based state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// 1. Mengirim kode OTP via SMS
  Future<bool> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithOtp(phoneNumber);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// 2. Verifikasi kode OTP dan memuat profil
  Future<bool> verifyOtp({required String phoneNumber, required String token}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final UserProfile profile = await _repository.verifyOtp(
        phoneNumber: phoneNumber,
        token: token,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isVerified: profile.isVerified,
        role: profile.role,
        simplifiedMode: profile.simplifiedMode || profile.role == UserRole.careReceiver,
        userProfile: profile,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// 3. Pemilihan peran (Onboarding)
  Future<void> selectRole(UserRole role) async {
    state = state.copyWith(
      role: role,
      simplifiedMode: role == UserRole.careReceiver,
    );

    if (state.userProfile != null) {
      final updated = state.userProfile!.copyWith(
        role: role,
        simplifiedMode: role == UserRole.careReceiver,
      );
      state = state.copyWith(userProfile: updated);
      await _repository.upsertProfile(updated);
    }
  }

  /// 4. Validasi kode undangan RT dan bergabung
  Future<bool> joinWithInviteCode(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final RtArea? area = await _repository.validateRtInviteCode(code);
      if (area == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Kode RT tidak valid atau telah kedaluwarsa.',
        );
        return false;
      }

      if (state.userProfile != null) {
        await _repository.joinRtArea(
          userId: state.userProfile!.id,
          rtAreaId: area.id,
        );
        final updatedProfile = state.userProfile!.copyWith(
          rtAreaId: area.id,
          isVerified: false,
        );
        state = state.copyWith(
          isLoading: false,
          rtArea: area,
          userProfile: updatedProfile,
          isVerified: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          rtArea: area,
          isVerified: false,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Set status autentikasi manual (misal bypass / demo / restore session)
  void setAuthenticated({
    required String userId,
    required String phoneNumber,
    required UserRole role,
    required bool isVerified,
    String? fullName,
    String? rtAreaId,
  }) {
    final profile = UserProfile(
      id: userId,
      fullName: fullName ?? 'Warga SIGAP',
      phoneNumber: phoneNumber,
      role: role,
      rtAreaId: rtAreaId,
      isVerified: isVerified,
      simplifiedMode: role == UserRole.careReceiver,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      isAuthenticated: true,
      isVerified: isVerified,
      simplifiedMode: role == UserRole.careReceiver,
      role: role,
      userProfile: profile,
    );
  }

  /// Mengubah toggle mode lansia / simplified mode
  void setSimplifiedMode(bool enabled) {
    state = state.copyWith(simplifiedMode: enabled);
  }

  /// Logout dan reset sesi
  void reset() {
    state = const AuthState();
  }
}

/// Provider global untuk state autentikasi
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
