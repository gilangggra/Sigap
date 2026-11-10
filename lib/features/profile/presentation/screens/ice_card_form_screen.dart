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
import '../../domain/models/ice_card.dart';
import '../state/profile_provider.dart';

/// Halaman form pengisian / penyuntingan data medis darurat (ICE Card)
/// Data disimpan terenkripsi dan hanya dapat diakses oleh korban, keluarga,
/// atau relawan pengunci insiden aktif dengan token resmi 2 jam.
class IceCardFormScreen extends StatefulWidget {
  const IceCardFormScreen({super.key});

  @override
  State<IceCardFormScreen> createState() => _IceCardFormScreenState();
}

class _IceCardFormScreenState extends State<IceCardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedBloodType = 'O+';
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _doctorPhoneController = TextEditingController();
  final TextEditingController _doctorNotesController = TextEditingController();

  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Tidak Diketahui'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingIceCard();
    });
  }

  Future<void> _loadExistingIceCard() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final careReceiverId = authProvider.userId ?? 'care-receiver-default';

    await profileProvider.loadIceCard(careReceiverId);
    final card = profileProvider.iceCard;

    if (card != null && mounted) {
      setState(() {
        if (_bloodTypes.contains(card.bloodType)) {
          _selectedBloodType = card.bloodType;
        }
        _allergiesController.text = card.allergies.join(', ');
        _conditionsController.text = card.chronicConditions.join(', ');
        _doctorNameController.text = card.doctorName ?? '';
        _doctorPhoneController.text = card.doctorPhone ?? '';
        _doctorNotesController.text = card.doctorNotes ?? '';
      });
    }
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _conditionsController.dispose();
    _doctorNameController.dispose();
    _doctorPhoneController.dispose();
    _doctorNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveIceCard() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final careReceiverId = authProvider.userId ?? 'care-receiver-default';

    final allergiesList = _allergiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final conditionsList = _conditionsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final card = IceCard(
      id: profileProvider.iceCard?.id ?? 'ice-${DateTime.now().millisecondsSinceEpoch}',
      careReceiverId: careReceiverId,
      bloodType: _selectedBloodType,
      allergies: allergiesList,
      chronicConditions: conditionsList,
      doctorName: _doctorNameController.text.trim().isEmpty ? null : _doctorNameController.text.trim(),
      doctorPhone: _doctorPhoneController.text.trim().isEmpty ? null : _doctorPhoneController.text.trim(),
      doctorNotes: _doctorNotesController.text.trim().isEmpty ? null : _doctorNotesController.text.trim(),
      createdAt: profileProvider.iceCard?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await profileProvider.saveIceCard(card);

    if (!mounted) return;

    if (success) {
      unawaited(FeedbackService.instance.triggerSuccessFeedback());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.safeGreenDark,
          content: Text('Kartu Informasi Medis Darurat (ICE Card) berhasil disimpan.'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      unawaited(FeedbackService.instance.triggerWarningFeedback());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emergencyRedDark,
          content: Text(profileProvider.errorMessage ?? 'Gagal menyimpan ICE Card.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Data Medis Darurat (ICE Card)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner Enkripsi & Keamanan
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(color: AppColors.infoBlueLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: AppColors.infoBlueLight, size: 28.0),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Text(
                          'Data medis ini dienkripsi at-rest menggunakan pgcrypto. Hanya dapat diakses saat tombol SOS aktif oleh relawan terverifikasi.',
                          style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXL),

                // 1. Golongan Darah
                Text(
                  'Golongan Darah',
                  style: AppTypography.seniorTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(color: AppColors.darkBorderHighContrast),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBloodType,
                      dropdownColor: AppColors.darkCard,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      isExpanded: true,
                      style: AppTypography.seniorBodyPrimary(color: Colors.white),
                      items: _bloodTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedBloodType = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // 2. Alergi Obat & Makanan
                Text(
                  'Alergi Obat / Makanan',
                  style: AppTypography.seniorTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  'Pisahkan dengan tanda koma (contoh: Penicillin, Aspirin, Kacang)',
                  style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                _AccessibleInputField(
                  controller: _allergiesController,
                  hintText: 'Penicillin, Sulfonamida, dll',
                  maxLines: 2,
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // 3. Penyakit Kronis / Riwayat Penyakit
                Text(
                  'Penyakit Kronis / Kondisi Khusus',
                  style: AppTypography.seniorTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                Text(
                  'Contoh: Hipertensi, Diabetes, Asma, Ring Jantung',
                  style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                _AccessibleInputField(
                  controller: _conditionsController,
                  hintText: 'Hipertensi, Diabetes Melitus, dll',
                  maxLines: 2,
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // 4. Dokter Rujukan / Puskesmas
                Text(
                  'Nama Dokter / Fasilitas Kesehatan',
                  style: AppTypography.seniorTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                _AccessibleInputField(
                  controller: _doctorNameController,
                  hintText: 'dr. Hendra Kusuma (Puskesmas Menteng)',
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // 5. Nomor Telepon Dokter
                Text(
                  'Nomor Telepon Dokter / RS',
                  style: AppTypography.seniorTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                _AccessibleInputField(
                  controller: _doctorPhoneController,
                  hintText: '+6281234567890',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppDimensions.spaceLG),

                // 6. Catatan Khusus Tindakan Medis
                Text(
                  'Catatan Khusus Tindakan Pertama',
                  style: AppTypography.seniorTitle(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                _AccessibleInputField(
                  controller: _doctorNotesController,
                  hintText: 'Catatan penting bagi relawan saat pertolongan pertama...',
                  maxLines: 3,
                ),
                const SizedBox(height: AppDimensions.space2XL),

                // Tombol Simpan
                AccessibleButton(
                  label: profileProvider.isLoading ? 'Menyimpan Data...' : 'Simpan ICE Card Medis',
                  onPressed: profileProvider.isLoading ? null : _saveIceCard,
                  isSimplified: true,
                  backgroundColor: AppColors.safeGreen,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // Tombol Lihat Kartu Medis & QR Code
                AccessibleButton(
                  label: 'Lihat Kartu Medis & QR Code',
                  onPressed: () => context.push('/profile/ice-card-view'),
                  isSimplified: true,
                  isSecondary: true,
                  icon: Icons.qr_code_2_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessibleInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType keyboardType;

  const _AccessibleInputField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.darkBorderHighContrast),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMD,
        vertical: AppDimensions.spaceSM,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: AppTypography.seniorBodyPrimary(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textDarkTertiary, fontSize: 16.0),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
