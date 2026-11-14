import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../../domain/models/task_item.dart';
import '../state/task_provider.dart';

/// Halaman Buat Permohonan Tugas Bantuan Mikro Warga (PRD F3.1)
/// Digunakan oleh Care-Receiver (Lansia) atau Primary Guardian untuk meminta bantuan tetangga
class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  TaskCategory _selectedCategory = TaskCategory.ambilResep;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final DateTime _neededBefore = DateTime.now().add(const Duration(hours: 3));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    unawaited(FeedbackService.instance.triggerSuccessFeedback());

    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? AppConstants.demoUserId;
    final userName = auth.fullName ?? 'Ibu Aminah (71 thn)';
    final rtAreaId = auth.rtArea?.id ?? AppConstants.demoRtAreaId;

    final success = await context.read<TaskProvider>().createTask(
      createdBy: userId,
      careReceiverId: userId,
      careReceiverName: userName,
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      destinationAddress: _addressController.text.trim(),
      neededBefore: _neededBefore,
      rtAreaId: rtAreaId,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.safeGreenDark,
            content: Text('Permohonan bantuan berhasil disiarkan ke relawan tetangga!'),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.emergencyRedDark,
            content: Text('Gagal mengirim permohonan. Silakan coba lagi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Buat Permohonan Bantuan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pilih Kategori Bantuan',
                  style: AppTypography.standardTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // Pilihan Kategori
                ...TaskCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.spaceSM),
                    child: Material(
                      color: isSelected ? AppColors.infoBlue.withValues(alpha: 0.2) : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceMD,
                            vertical: AppDimensions.spaceMD,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                            border: Border.all(
                              color: isSelected ? AppColors.infoBlueLight : AppColors.darkBorder,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(cat.emoji, style: const TextStyle(fontSize: 24.0)),
                              const SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: Text(
                                  cat.label,
                                  style: AppTypography.standardBody(
                                    color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? AppColors.infoBlueLight : AppColors.textDarkTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: AppDimensions.spaceLG),

                // Deskripsi Kebutuhan (Maks 200 karakter sesuai PRD F3.1)
                Text(
                  'Rincian Kebutuhan Bantuan',
                  style: AppTypography.standardTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 200,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Titip beli obat darah tinggi di apotek atau beli beras 5kg di warung...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Rincian bantuan wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.spaceMD),

                // Lokasi / Alamat Tujuan
                Text(
                  'Lokasi / Alamat Tempat Bantuan',
                  style: AppTypography.standardTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Apotek Kimia Farma Jl. Kenanga No. 10',
                    prefixIcon: Icon(Icons.place_rounded, color: AppColors.infoBlueLight),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Alamat tujuan wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.spaceXL),

                AccessibleButton(
                  label: _isSubmitting ? 'Mengirim...' : 'SIARKAN KE RELAWAN TETANGGA',
                  onPressed: _isSubmitting ? null : _submitTask,
                  backgroundColor: AppColors.infoBlue,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
