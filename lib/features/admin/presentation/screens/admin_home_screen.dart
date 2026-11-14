import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/components.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// Halaman Dasbor Pengurus RT/RW (Civic Admin Dashboard)
/// Menampilkan manajemen kode undangan RT 30 hari, validasi identitas warga baru,
/// dan rekap status kesiapsiagaan lingkungan dengan tata letak standar mobile yang rapi.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthRepository _authRepository = AuthRepository();
  String _rtInviteCode = 'SIGAP-RT03-26';

  final List<Map<String, String>> _pendingResidents = [
    {
      'id': 'res-1',
      'name': 'Budi Santoso',
      'role': 'Relawan Warga',
      'phone': '+6281299887766',
      'address': 'Jl. Kenanga No. 8',
    },
    {
      'id': 'res-2',
      'name': 'Siti Rahmawati',
      'role': 'Penerima Bantuan',
      'phone': '+6281311223344',
      'address': 'Jl. Melati No. 12',
    },
  ];

  void _verifyResident(int index, bool isApproved) {
    unawaited(FeedbackService.instance.triggerSuccessFeedback());
    final item = _pendingResidents[index];
    final String residentId = item['id']!;
    final String name = item['name']!;

    final authProvider = context.read<AuthProvider>();
    final String adminId = authProvider.userId ?? AppConstants.demoAdminId;

    unawaited(_authRepository.verifyResident(
      residentId: residentId,
      adminId: adminId,
      isApproved: isApproved,
    ));

    setState(() {
      _pendingResidents.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isApproved ? AppColors.safeGreenDark : AppColors.emergencyRedDark,
        behavior: SnackBarBehavior.floating,
        content: Text(
          isApproved
              ? 'Akun $name berhasil diverifikasi sebagai warga sah RT 03.'
              : 'Pendaftaran $name telah ditolak.',
        ),
      ),
    );
  }

  void _refreshInviteCode() {
    unawaited(FeedbackService.instance.triggerSuccessFeedback());
    final String newCode = 'SIGAP-RT03-${DateTime.now().minute}${DateTime.now().second}';
    final authProvider = context.read<AuthProvider>();
    final String rtAreaId = authProvider.rtAreaId ?? AppConstants.demoRtAreaId;

    unawaited(_authRepository.refreshRtInviteCode(
      rtAreaId: rtAreaId,
      newInviteCode: newCode,
    ));

    setState(() {
      _rtInviteCode = newCode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.roleAdmin,
        behavior: SnackBarBehavior.floating,
        content: Text('Kode undangan RT diperbarui: $_rtInviteCode (Berlaku 30 hari)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('SIGAP — Pengurus RT 03'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil Saya',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Ganti Peran',
            onPressed: () => context.go('/auth/role'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceSM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Kode Undangan RT
              AppCard(
                border: Border.all(color: AppColors.roleAdmin.withValues(alpha: 0.3), width: 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'KODE UNDANGAN LINGKUNGAN',
                          style: GoogleFonts.poppins(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppColors.textDarkTertiary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.safeGreenLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                          ),
                          child: Text(
                            'Aktif 30 Hari',
                            style: GoogleFonts.poppins(
                              color: AppColors.safeGreenDark,
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _rtInviteCode,
                            style: GoogleFonts.poppins(
                              color: AppColors.roleAdmin,
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.roleAdmin),
                          tooltip: 'Perbarui Kode',
                          onPressed: _refreshInviteCode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Bagikan kode ini kepada warga RT 03 untuk pendaftaran dan verifikasi domisili.',
                      style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // Daftar Warga Menunggu Verifikasi
              AppSectionHeader(
                title: 'Menunggu Verifikasi (${_pendingResidents.length})',
                subtitle: 'Tinjau identitas warga yang ingin bergabung ke lingkungan RT',
              ),
              const SizedBox(height: AppDimensions.spaceSM),

              if (_pendingResidents.isEmpty)
                AppCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      child: Text(
                        'Semua warga telah terverifikasi.',
                        style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingResidents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceSM),
                  itemBuilder: (context, index) {
                    final item = _pendingResidents[index];
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['name']!,
                                style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary).copyWith(
                                  fontSize: 16.0,
                                ),
                              ),
                              AppBadge.brand(item['role']!, isSmall: true),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${item['phone']} • ${item['address']}',
                            style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                          ),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _verifyResident(index, false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.emergencyRed,
                                    side: const BorderSide(color: AppColors.emergencyRed),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                  child: const Text('Tolak'),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _verifyResident(index, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  ),
                                  child: const Text('Verifikasi'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
