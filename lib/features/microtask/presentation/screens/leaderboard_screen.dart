import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../state/task_provider.dart';

/// Halaman Papan Peringkat Relawan RT & Poin Sosial (PRD F3.3)
/// Memberikan apresiasi non-finansial kepada relawan aktif di lingkungan warga
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadLeaderboard('rt-001');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final entries = provider.leaderboard;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Papan Peringkat Relawan RT'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => provider.loadLeaderboard('rt-001'),
          color: AppColors.roleGuardian,
          backgroundColor: AppColors.darkCard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kartu Informasi Sistem Poin Sosial
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    border: Border.all(color: AppColors.roleGuardian.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.warningAmberLight, size: 30.0),
                          const SizedBox(width: AppDimensions.spaceMD),
                          Text(
                            'Sistem Poin Sosial Warga',
                            style: AppTypography.standardHeadline(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceSM),
                      Text(
                        'Apresiasi bagi relawan yang siaga menjaga keselamatan dan kenyamanan lingkungan:',
                        style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      const Divider(color: AppColors.darkBorder),
                      const SizedBox(height: AppDimensions.spaceSM),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _PointBadge(
                            points: '+50 Poin',
                            label: 'Respons Darurat SOS',
                            color: AppColors.emergencyRed,
                            icon: Icons.emergency_rounded,
                          ),
                          _PointBadge(
                            points: '+10 Poin',
                            label: 'Tugas Mikro Selesai',
                            color: AppColors.infoBlueLight,
                            icon: Icons.task_alt_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceXL),

                Text(
                  'Relawan Terbaik RT 03 / RW 05',
                  style: AppTypography.standardTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                if (entries.isEmpty) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppColors.roleGuardian),
                    ),
                  ),
                ] else ...[
                  ...entries.map((entry) {
                    final isTop3 = entry.rank <= 3;
                    final medalEmoji = entry.rank == 1
                        ? '🥇'
                        : entry.rank == 2
                            ? '🥈'
                            : entry.rank == 3
                                ? '🥉'
                                : '#${entry.rank}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      decoration: BoxDecoration(
                        color: isTop3
                            ? AppColors.darkCard
                            : AppColors.darkSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        border: Border.all(
                          color: entry.rank == 1
                              ? AppColors.warningAmber
                              : AppColors.darkBorder,
                          width: entry.rank == 1 ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44.0,
                            alignment: Alignment.center,
                            child: Text(
                              medalEmoji,
                              style: TextStyle(
                                fontSize: isTop3 ? 28.0 : 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceMD),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.responderName,
                                  style: AppTypography.standardTitle(color: Colors.white),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '${entry.tasksCompleted} tugas selesai • ${entry.emergencyResponses} respons SOS',
                                  style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.roleGuardian.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                              border: Border.all(color: AppColors.roleGuardian),
                            ),
                            child: Text(
                              '${entry.totalPoints} Pts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PointBadge extends StatelessWidget {
  final String points;
  final String label;
  final Color color;
  final IconData icon;

  const _PointBadge({
    required this.points,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28.0),
        const SizedBox(height: 4.0),
        Text(
          points,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        Text(
          label,
          style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
        ),
      ],
    );
  }
}
