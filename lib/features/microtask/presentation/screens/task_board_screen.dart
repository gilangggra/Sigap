import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/components.dart';
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
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  backgroundColor: AppColors.primaryTealWash,
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.radar_rounded, color: AppColors.primaryTealDark, size: 22.0),
                      ),
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

                // Bilah Pencarian Cepat Khas Mobile
                const AppSearchField(
                  hintText: 'Cari tugas bantuan atau kebutuhan warga...',
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
                  const AppSectionHeader(
                    title: 'Tugas yang Sedang Anda Kerjakan',
                    subtitle: 'Selesaikan dan konfirmasi untuk memperoleh poin sosial',
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),
                  ...myClaimedTasks.map((task) {
                    final isDone = task.status == TaskStatus.completed;
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
                      border: isDone
                          ? Border.all(color: AppColors.safeGreen, width: 1.5)
                          : AppBorders.tealActive,
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
                              if (isDone)
                                AppBadge.success(task.status.label, isSmall: true)
                              else
                                AppBadge.brand(task.status.label, isSmall: true),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceSM),
                          Text(task.description, style: AppTypography.standardBody(color: AppColors.textDarkPrimary)),
                          const SizedBox(height: 2.0),
                          Text('Tujuan: ${task.destinationAddress}', style: AppTypography.standardCaption(color: AppColors.textDarkSecondary)),
                          if (!isDone) ...[
                            const SizedBox(height: AppDimensions.spaceMD),
                            AccessibleButton(
                              label: 'Tandai Selesai (+10 Poin)',
                              onPressed: () => _finishTask(task),
                              backgroundColor: AppColors.safeGreen,
                              icon: Icons.check_circle_rounded,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppDimensions.spaceLG),
                ],

                // Daftar Tugas Terbuka di Sekitar
                AppSectionHeader(
                  title: 'Tugas Menunggu Relawan (${nearbyTasks.length})',
                  subtitle: 'Pilih tugas terdekat yang bisa Anda bantu',
                  trailing: provider.isLoading
                      ? const SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.primaryTeal),
                        )
                      : null,
                ),
                const SizedBox(height: AppDimensions.spaceSM),

                if (nearbyTasks.isEmpty) ...[
                  AppEmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Semua Warga Sekitar Aman!',
                    description: 'Belum ada permohonan bantuan mikro baru dalam radius 800m.',
                    actionLabel: 'Buat Permohonan Baru',
                    onActionPressed: () => context.push('/tasks/create'),
                  ),
                ] else ...[
                  ...nearbyTasks.map((task) {
                    final dist = task.distanceMeters != null ? '${task.distanceMeters!.toInt()} m' : 'Dekat';
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
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
                              AppBadge.brand('+10 Poin', isSmall: true),
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
