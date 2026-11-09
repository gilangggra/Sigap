import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../../domain/models/task_item.dart';
import '../state/task_provider.dart';

/// Halaman Papan Tugas Bantuan Mikro Warga (Mutual-Aid Task Marketplace)
/// Menampilkan radar tugas dalam radius 800m dengan filter kategori dan klaim tugas.
class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadNearbyTasks();
    });
  }

  void _claimTask(TaskItem task) async {
    final auth = context.read<AuthProvider>();
    final responderId = auth.userId ?? 'resp-001';
    final responderName = auth.fullName ?? 'Relawan SIGAP';

    unawaited(FeedbackService.instance.triggerSuccessFeedback());

    final success = await context.read<TaskProvider>().acceptTask(
      taskId: task.id,
      responderId: responderId,
      responderName: responderName,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.safeGreenDark,
            content: Text(
              'Tugas "${task.category.label}" berhasil diambil! Warga telah dinotifikasi.',
              style: AppTypography.standardBody(color: Colors.white),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.emergencyRedDark,
            content: Text('Gagal mengambil tugas atau sudah diambil relawan lain.'),
          ),
        );
      }
    }
  }

  void _finishTask(TaskItem task) async {
    final auth = context.read<AuthProvider>();
    final responderId = auth.userId ?? 'resp-001';

    unawaited(FeedbackService.instance.triggerSuccessFeedback());

    final success = await context.read<TaskProvider>().completeTask(
      taskId: task.id,
      responderId: responderId,
      completionNotes: 'Tugas telah selesai diantar dengan selamat.',
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.safeGreenDark,
          content: Text('Selamat! Tugas selesai. +10 Poin Sosial ditambahkan ke profil Anda.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final nearbyTasks = provider.nearbyTasks;
    final myClaimedTasks = provider.myClaimedTasks;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Bantu Warga (Tugas Mikro)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: 'Papan Peringkat RT',
            onPressed: () => context.push('/tasks/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Buat Permohonan Bantuan',
            onPressed: () => context.push('/tasks/create'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => provider.loadNearbyTasks(),
          color: AppColors.infoBlue,
          backgroundColor: AppColors.darkCard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Informasi Radius Hyperlocal 800m
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.infoBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radar_rounded, color: AppColors.infoBlueLight, size: 28.0),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Text(
                          'Radar Tugas Terdekat (Radius 800m)\nSetiap tugas selesai memberi +10 Poin Sosial.',
                          style: AppTypography.standardCaption(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceMD),

                // Filter Kategori
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua'),
                        selected: provider.selectedCategory == null,
                        onSelected: (_) => provider.setCategoryFilter(null),
                        backgroundColor: AppColors.darkCard,
                        selectedColor: AppColors.infoBlue,
                        labelStyle: TextStyle(
                          color: provider.selectedCategory == null ? Colors.white : AppColors.textDarkSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSM),
                      ...TaskCategory.values.map((cat) {
                        final isSelected = provider.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppDimensions.spaceSM),
                          child: FilterChip(
                            avatar: Text(cat.emoji),
                            label: Text(cat.label),
                            selected: isSelected,
                            onSelected: (_) => provider.setCategoryFilter(isSelected ? null : cat),
                            backgroundColor: AppColors.darkCard,
                            selectedColor: AppColors.infoBlue,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceLG),

                // Tugas Aktif yang Sedang Diambil Pengguna
                if (myClaimedTasks.isNotEmpty) ...[
                  Text(
                    'Tugas yang Sedang Anda Kerjakan',
                    style: AppTypography.standardTitle(color: AppColors.safeGreenLight),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  ...myClaimedTasks.map((task) {
                    final isDone = task.status == TaskStatus.completed;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        border: Border.all(
                          color: isDone ? AppColors.safeGreenDark : AppColors.infoBlue,
                          width: 2.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(task.category.emoji, style: const TextStyle(fontSize: 24.0)),
                              const SizedBox(width: AppDimensions.spaceSM),
                              Expanded(
                                child: Text(
                                  task.category.label,
                                  style: AppTypography.standardTitle(color: Colors.white),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDone ? AppColors.safeGreenDark : AppColors.infoBlue,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                ),
                                child: Text(
                                  task.status.label,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceSM),
                          Text(task.description, style: AppTypography.standardBody(color: Colors.white)),
                          const SizedBox(height: 4.0),
                          Text('Tujuan: ${task.destinationAddress}', style: AppTypography.standardCaption(color: AppColors.textDarkSecondary)),
                          const SizedBox(height: AppDimensions.spaceMD),
                          if (!isDone)
                            AccessibleButton(
                              label: 'Tandai Selesai (+10 Poin)',
                              onPressed: () => _finishTask(task),
                              backgroundColor: AppColors.safeGreen,
                              icon: Icons.check_circle_rounded,
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppDimensions.spaceLG),
                ],

                // Daftar Tugas Terbuka di Sekitar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tugas Menunggu Relawan (${nearbyTasks.length})',
                      style: AppTypography.standardTitle(color: Colors.white),
                    ),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.infoBlueLight),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                if (nearbyTasks.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceXL),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.safeGreenLight, size: 48.0),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Text(
                            'Semua warga di sekitar aman!',
                            style: AppTypography.standardTitle(color: Colors.white),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Belum ada permohonan bantuan mikro baru dalam radius 800m.',
                            style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ...nearbyTasks.map((task) {
                    final dist = task.distanceMeters != null ? '${task.distanceMeters!.toInt()} m' : 'Dekat';
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      padding: const EdgeInsets.all(AppDimensions.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(task.category.emoji, style: const TextStyle(fontSize: 26.0)),
                              const SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task.category.label, style: AppTypography.standardTitle(color: Colors.white)),
                                    Text(
                                      'Untuk: ${task.careReceiverName} • Jarak: $dist',
                                      style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.roleGuardian.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                  border: Border.all(color: AppColors.roleGuardian),
                                ),
                                child: const Text(
                                  '+10 Poin',
                                  style: TextStyle(color: AppColors.roleGuardian, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceSM),
                          Text(task.description, style: AppTypography.standardBody(color: Colors.white)),
                          const SizedBox(height: 4.0),
                          Text('Tujuan: ${task.destinationAddress}', style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
                          const SizedBox(height: AppDimensions.spaceMD),
                          AccessibleButton(
                            label: 'AMBIL TUGAS INI (BANTU)',
                            onPressed: () => _claimTask(task),
                            backgroundColor: AppColors.infoBlue,
                            icon: Icons.pan_tool_rounded,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/create'),
        backgroundColor: AppColors.roleGuardian,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Buat Permohonan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
