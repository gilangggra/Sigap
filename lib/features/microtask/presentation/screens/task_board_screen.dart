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
/// Menampilkan radar tugas dalam radius 800m dengan format standar mobile dan tipografi Poppins konsisten.
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
            behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
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
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Bantu Warga (Tugas Mikro)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20.0),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: 'Papan Peringkat RT',
            onPressed: () => context.push('/tasks/leaderboard'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => provider.loadNearbyTasks(),
          color: AppColors.primaryTeal,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMD,
              vertical: AppDimensions.spaceSM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Informasi Radius Hyperlocal 800m
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTealLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                    border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radar_rounded, color: AppColors.primaryTealDark, size: 26.0),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Text(
                          'Radar Tugas Terdekat (Radius 800m)\nSetiap tugas selesai memberi +10 Poin Sosial.',
                          style: AppTypography.standardCaption(color: AppColors.primaryTealDeep),
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
                        backgroundColor: AppColors.cardWhite,
                        selectedColor: AppColors.primaryTealLight,
                        checkmarkColor: AppColors.primaryTealDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          side: BorderSide(
                            color: provider.selectedCategory == null ? AppColors.primaryTeal : AppColors.lightBorder,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: provider.selectedCategory == null ? AppColors.primaryTealDark : AppColors.textDarkSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
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
                            backgroundColor: AppColors.cardWhite,
                            selectedColor: AppColors.primaryTealLight,
                            checkmarkColor: AppColors.primaryTealDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryTeal : AppColors.lightBorder,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primaryTealDark : AppColors.textDarkSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0,
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
                    style: AppTypography.categoryHeadline(color: AppColors.safeGreenDark),
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),
                  ...myClaimedTasks.map((task) {
                    final isDone = task.status == TaskStatus.completed;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(
                          color: isDone ? AppColors.safeGreen : AppColors.primaryTeal,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 8.0,
                            offset: Offset(0, 2),
                          ),
                        ],
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
                                  style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDone ? AppColors.safeGreen.withValues(alpha: 0.15) : AppColors.primaryTealLight,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                ),
                                child: Text(
                                  task.status.label,
                                  style: TextStyle(
                                    color: isDone ? AppColors.safeGreenDark : AppColors.primaryTealDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceSM),
                          Text(task.description, style: AppTypography.standardBody(color: AppColors.textDarkPrimary)),
                          const SizedBox(height: 2.0),
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
                      style: AppTypography.categoryHeadline(),
                    ),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.primaryTeal),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceSM),

                if (nearbyTasks.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceXL),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.safeGreen, size: 44.0),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Text(
                            'Semua warga di sekitar aman!',
                            style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                          ),
                          const SizedBox(height: 2.0),
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
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                        border: Border.all(color: AppColors.lightBorder, width: 1.0),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 6.0,
                            offset: Offset(0, 1),
                          ),
                        ],
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(task.category.label, style: AppTypography.standardTitle(color: AppColors.textDarkPrimary)),
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
                                  color: AppColors.primaryTealLight,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                ),
                                child: const Text(
                                  '+10 Poin',
                                  style: TextStyle(color: AppColors.primaryTealDark, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceSM),
                          Text(task.description, style: AppTypography.standardBody(color: AppColors.textDarkPrimary)),
                          const SizedBox(height: 2.0),
                          Text('Tujuan: ${task.destinationAddress}', style: AppTypography.standardCaption(color: AppColors.textDarkTertiary)),
                          const SizedBox(height: AppDimensions.spaceMD),
                          AccessibleButton(
                            label: 'AMBIL TUGAS INI (BANTU)',
                            onPressed: () => _claimTask(task),
                            backgroundColor: AppColors.primaryTeal,
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
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Buat Permohonan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
