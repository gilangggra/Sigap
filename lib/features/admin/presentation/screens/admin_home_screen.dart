import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_state.dart';
import '../../../../core/theme/app_typography.dart';

/// Halaman Dasbor Pengurus RT/RW (Civic Admin Dashboard)
/// Menampilkan manajemen kode undangan RT 30 hari, validasi identitas warga baru,
/// dan rekap status kesiapsiagaan lingkungan.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
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

    final repository = ref.read(authRepositoryProvider);
    final authState = ref.read(authStateProvider);
    final String adminId = authState.userId ?? 'demo-admin-id';

    unawaited(repository.verifyResident(
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
    final repository = ref.read(authRepositoryProvider);
    final authState = ref.read(authStateProvider);
    final String rtAreaId = authState.rtAreaId ?? '00000000-0000-0000-0000-000000000001';

    unawaited(repository.refreshRtInviteCode(
      rtAreaId: rtAreaId,
      newInviteCode: newCode,
    ));

    setState(() {
      _rtInviteCode = newCode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.roleAdmin,
        content: Text('Kode undangan RT diperbarui: $_rtInviteCode (Berlaku 30 hari)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('SIGAP — Pengurus RT 03'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Ganti Peran',
            onPressed: () => context.go('/auth/role'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Kode Undangan RT
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  border: Border.all(color: AppColors.roleAdmin, width: 2.0),
                ),
                padding: const EdgeInsets.all(AppDimensions.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'KODE UNDANGAN LINGKUNGAN',
                          style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.safeGreenDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Aktif 30 Hari', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _rtInviteCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          tooltip: 'Perbarui Kode',
                          onPressed: _refreshInviteCode,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      'Bagikan kode ini kepada warga RT 03 untuk pendaftaran dan verifikasi domisili.',
                      style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Daftar Warga Menunggu Verifikasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menunggu Verifikasi (${_pendingResidents.length})',
                    style: AppTypography.standardTitle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              if (_pendingResidents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: const Center(
                    child: Text(
                      'Semua warga telah terverifikasi.',
                      style: TextStyle(color: AppColors.textDarkSecondary),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingResidents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceMD),
                  itemBuilder: (context, index) {
                    final item = _pendingResidents[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['name']!, style: AppTypography.standardTitle(color: Colors.white)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.infoBlue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(item['role']!, style: const TextStyle(color: AppColors.infoBlueLight, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${item['phone']} • ${item['address']}', style: AppTypography.standardCaption(color: AppColors.textDarkSecondary)),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _verifyResident(index, false),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.emergencyRedLight),
                                  child: const Text('Tolak'),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _verifyResident(index, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.safeGreen),
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

