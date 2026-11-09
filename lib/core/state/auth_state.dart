import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

/// Model immutable status autentikasi dan peran aktif pengguna
class AuthState {
  final bool isAuthenticated;
  final bool isVerified;
  final bool simplifiedMode;
  final UserRole role;
  final String? userId;
  final String? phoneNumber;
  final String? fullName;
  final String? rtAreaId;

  const AuthState({
    this.isAuthenticated = false,
    this.isVerified = false,
    this.simplifiedMode = true,
    this.role = UserRole.careReceiver,
    this.userId,
    this.phoneNumber,
    this.fullName,
    this.rtAreaId,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isVerified,
    bool? simplifiedMode,
    UserRole? role,
    String? userId,
    String? phoneNumber,
    String? fullName,
    String? rtAreaId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isVerified: isVerified ?? this.isVerified,
      simplifiedMode: simplifiedMode ?? this.simplifiedMode,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      rtAreaId: rtAreaId ?? this.rtAreaId,
    );
  }
}

/// StateNotifier pengelola autentikasi dan role-based routing
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Set status autentikasi setelah login/OTP sukses
  void setAuthenticated({
    required String userId,
    required String phoneNumber,
    required UserRole role,
    required bool isVerified,
    String? fullName,
    String? rtAreaId,
  }) {
    state = state.copyWith(
      isAuthenticated: true,
      isVerified: isVerified,
      simplifiedMode: role == UserRole.careReceiver,
      role: role,
      userId: userId,
      phoneNumber: phoneNumber,
      fullName: fullName,
      rtAreaId: rtAreaId,
    );
  }

  /// Mengubah peran aktif (misal saat alur onboarding memilih peran)
  void setRole(UserRole role) {
    state = state.copyWith(
      role: role,
      simplifiedMode: role == UserRole.careReceiver,
    );
  }

  /// Mengubah toggle mode lansia / simplified mode
  void setSimplifiedMode(bool enabled) {
    state = state.copyWith(simplifiedMode: enabled);
  }

  /// Logout / reset sesi
  void reset() {
    state = const AuthState();
  }
}

/// Provider global untuk state autentikasi
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

