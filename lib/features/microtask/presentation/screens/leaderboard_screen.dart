import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/components.dart';

/// Halaman Papan Solidaritas & Gotong Royong Lingkungan RT.
/// Menggantikan sistem papan peringkat kompetitif dengan apresiasi kolektif,
/// etika kepedulian sosial warga, pesan kehangatan, dan kesiapsiagaan relawan.
class CommunityImpactScreen extends StatelessWidget {
  const CommunityImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Solidaritas & Gotong Royong'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20.0),
          onPressed: () => context.pop(),
        ),
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
              // =============================================================
              // 1. Capaian Kebersamaan Lingkungan RT 03 / RW 05
              // =============================================================
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryTealLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, color: AppColors.primaryTealDark, size: 22.0),
                        ),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lingkungan Siaga RT 03 / RW 05',
                                style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
                              ),
                              Text(
                                'Kekuatan kepedulian dan kebersamaan antar sesama warga',
                                style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    const Divider(color: AppColors.lightBorder),
                    const SizedBox(height: AppDimensions.spaceSM),

                    // Baris Indikator Solidaritas Kolektif
                    const Row(
                      children: [
                        Expanded(
                          child: _ImpactStatItem(
                            value: '48x',
                            label: 'Bantuan Selesai',
                            color: AppColors.primaryTealDark,
                            icon: Icons.task_alt_rounded,
                          ),
                        ),
                        SizedBox(
                          height: 40.0,
                          child: VerticalDivider(color: AppColors.lightBorder, thickness: 1.0, width: 1.0),
                        ),
                        Expanded(
                          child: _ImpactStatItem(
                            value: '100%',
                            label: 'Tanggap Darurat',
                            color: AppColors.safeGreenDark,
                            icon: Icons.speed_rounded,
                          ),
                        ),
                        SizedBox(
                          height: 40.0,
                          child: VerticalDivider(color: AppColors.lightBorder, thickness: 1.0, width: 1.0),
                        ),
                        Expanded(
                          child: _ImpactStatItem(
                            value: '24',
                            label: 'Warga Siaga',
                            color: AppColors.roleGuardian,
                            icon: Icons.volunteer_activism_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // =============================================================
              // 2. Prinsip Luhur Gotong Royong SIGAP (Etika Komunitas)
              // =============================================================
              AppCard(
                backgroundColor: AppColors.mintSurface,
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: AppColors.primaryTealDark, size: 20.0),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Text(
                          'Prinsip Gotong Royong SIGAP',
                          style: AppTypography.standardTitle(color: AppColors.primaryTealDeep),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    const _EthicPrincipleRow(
                      emoji: '🕊️',
                      title: 'Ikhlas & Menjaga Martabat',
                      description: 'Menolong sesama didasari ketulusan murni, bukan mengejar skor atau peringkat.',
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    const _EthicPrincipleRow(
                      emoji: '🤝',
                      title: 'Solidaritas Bersama',
                      description: 'Meringankan beban tetangga yang sakit, lansia, atau membutuhkan pendampingan.',
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    const _EthicPrincipleRow(
                      emoji: '🔒',
                      title: 'Menjaga Privasi & Kehormatan',
                      description: 'Kebutuhan dan data medis tetangga dijaga secara aman dan penuh tanggung jawab.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // =============================================================
              // 3. Pesan Hangat & Doa Warga
              // =============================================================
              const AppSectionHeader(
                title: 'Pesan Hangat & Apresiasi Warga',
                subtitle: 'Ucapan tulus dari keluarga dan tetangga yang terbantu',
              ),
              const SizedBox(height: AppDimensions.spaceSM),

              const _GratitudeCard(
                authorName: 'Ibu Siti & Keluarga',
                authorRole: 'Warga Lansia (72 thn) • RT 03',
                message:
                    '“Terima kasih banyak Nak Budi sudah bantu tebus resep obat darah tinggi di apotek kemarin siang. Sangat membantu keluarga kami yang sedang bekerja di luar.”',
                category: 'Bantuan Resep Obat',
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              const _GratitudeCard(
                authorName: 'Keluarga Bpk. Slamet',
                authorRole: 'Keluarga Lansia (68 thn) • RT 02',
                message:
                    '“Alhamdulillah tetangga langsung sigap merespons saat alarm darurat kakek berbunyi. Terima kasih atas kepedulian relawan lingkungan.”',
                category: 'Respon Cepat Darurat',
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              const _GratitudeCard(
                authorName: 'Pak Hartono',
                authorRole: 'Warga Lansia (70 thn) • RT 03',
                message:
                    '“Terima kasih Mbak Siti yang selalu menyempatkan menyapa dan membawakan sayur segar. Lingkungan kita terasa sangat guyub dan rukun.”',
                category: 'Kebutuhan Harian',
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // =============================================================
              // 4. Daftar Tim Relawan Siaga Lingkungan (Bukan Peringkat)
              // =============================================================
              const AppSectionHeader(
                title: 'Warga Siaga Lingkungan',
                subtitle: 'Tetangga terverifikasi yang siap sedia saat dibutuhkan',
              ),
              const SizedBox(height: AppDimensions.spaceSM),

              const _VolunteerCard(
                name: 'Budi Santoso',
                area: 'RT 03 / RW 05',
                roleBadge: 'Terlatih Pertolongan Pertama (BHD)',
                isStandby: true,
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              const _VolunteerCard(
                name: 'Siti Rahma',
                area: 'RT 02 / RW 05',
                roleBadge: 'Pendamping Posyandu Lansia',
                isStandby: true,
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              const _VolunteerCard(
                name: 'Ahmad Fauzi',
                area: 'RT 03 / RW 05',
                roleBadge: 'Relawan Siaga Lingkungan',
                isStandby: true,
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              const _VolunteerCard(
                name: 'Hendra Wijaya',
                area: 'RT 01 / RW 05',
                roleBadge: 'Tim Bantuan Logistik Warga',
                isStandby: false,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef LeaderboardScreen = CommunityImpactScreen;

class _ImpactStatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _ImpactStatItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.0),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EthicPrincipleRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _EthicPrincipleRow({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16.0)),
        const SizedBox(width: AppDimensions.spaceSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.standardTitle(color: AppColors.textDarkPrimary).copyWith(fontSize: 13.0),
              ),
              Text(
                description,
                style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GratitudeCard extends StatelessWidget {
  final String authorName;
  final String authorRole;
  final String message;
  final String category;

  const _GratitudeCard({
    required this.authorName,
    required this.authorRole,
    required this.message,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: authorName, radius: 18.0),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: AppTypography.standardTitle(color: AppColors.textDarkPrimary).copyWith(fontSize: 14.0),
                    ),
                    Text(
                      authorRole,
                      style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                    ),
                  ],
                ),
              ),
              AppBadge.neutral(category, isSmall: true),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Text(
            message,
            style: AppTypography.standardBody(color: AppColors.textDarkSecondary).copyWith(
              fontStyle: FontStyle.italic,
              fontSize: 13.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final String name;
  final String area;
  final String roleBadge;
  final bool isStandby;

  const _VolunteerCard({
    required this.name,
    required this.area,
    required this.roleBadge,
    required this.isStandby,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      child: Row(
        children: [
          AppAvatar(
            name: name,
            radius: 20.0,
            isOnline: isStandby,
            showBadge: true,
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                ),
                Text(
                  area,
                  style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                ),
                const SizedBox(height: 4.0),
                Text(
                  roleBadge,
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTealDark,
                  ),
                ),
              ],
            ),
          ),
          if (isStandby)
            AppBadge.success('Siaga', isSmall: true)
          else
            AppBadge.neutral('Istirahat', isSmall: true),
        ],
      ),
    );
  }
}
