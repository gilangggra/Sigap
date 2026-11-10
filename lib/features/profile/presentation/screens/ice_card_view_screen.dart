import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../state/profile_provider.dart';

/// Halaman Tampilan Data Medis Darurat (Digital ICE Card & Medical ID Pass).
/// Didesain dengan tata letak standar mobile yang bersih dan tipografi Poppins konsisten.
class IceCardViewScreen extends StatefulWidget {
  final String? emergencyToken;
  final bool isSelfView;

  const IceCardViewScreen({
    super.key,
    this.emergencyToken,
    this.isSelfView = false,
  });

  @override
  State<IceCardViewScreen> createState() => _IceCardViewScreenState();
}

class _IceCardViewScreenState extends State<IceCardViewScreen> {
  int _selectedTabIndex = 0; // 0: Data Medis, 1: QR Code Darurat

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIceCardData();
    });
  }

  Future<void> _loadIceCardData() async {
    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();

    if (widget.isSelfView) {
      final careReceiverId = authProvider.userId ?? 'care-receiver-default';
      await profileProvider.loadIceCard(careReceiverId);
    } else {
      final token = widget.emergencyToken ?? 'DEMO-EMERGENCY-TOKEN';
      final responderId = authProvider.userId ?? 'responder-001';

      await profileProvider.accessEmergencyIceCard(
        token: token,
        responderId: responderId,
      );
    }
  }

  Future<void> _callDoctor(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _generateQrPayload(dynamic card, AuthProvider authProvider) {
    final payload = {
      'app': 'SIGAP_EMERGENCY_ID',
      'id': card.careReceiverId,
      'name': authProvider.fullName ?? 'Warga SIGAP',
      'blood': card.bloodType,
      'allergies': card.allergies,
      'conditions': card.chronicConditions,
      'doctor': card.doctorName,
      'doctor_phone': card.doctorPhone,
      'generated_at': DateTime.now().toIso8601String(),
    };
    return jsonEncode(payload);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final card = widget.isSelfView
        ? profileProvider.iceCard
        : profileProvider.emergencyIceCard;
    final patientName = authProvider.fullName ?? 'Ibu Aminah';

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.isSelfView ? 'Kartu Medis Digital' : 'Data Medis Korban'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20.0),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: profileProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                ),
              )
            : card == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceXL),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTealLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medical_information_outlined,
                              color: AppColors.primaryTealDark,
                              size: 48.0,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Text(
                            widget.isSelfView
                                ? 'Data Medis Belum Diisi'
                                : 'Akses Ditolak / Token Kedaluwarsa',
                            style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spaceXS),
                          Text(
                            widget.isSelfView
                                ? 'Lengkapi profil medis darurat Anda agar relawan dan paramedis dapat memberikan pertolongan yang tepat.'
                                : profileProvider.errorMessage ??
                                    'Token darurat hanya berlaku 2 jam selama insiden aktif.',
                            style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.isSelfView) ...[
                            const SizedBox(height: AppDimensions.spaceLG),
                            AccessibleButton(
                              label: 'Isi Data Medis Sekarang',
                              onPressed: () => context.push('/profile/ice-card'),
                              backgroundColor: AppColors.primaryTeal,
                              icon: Icons.edit_note_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceMD,
                      vertical: AppDimensions.spaceSM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Kartu Profil Pasien Standar Mobile
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceMD),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                            border: Border.all(color: AppColors.lightBorder, width: 1.0),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 8.0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 28.0,
                                backgroundColor: AppColors.primaryTealLight,
                                child: Icon(Icons.elderly_rounded, color: AppColors.primaryTealDark, size: 32.0),
                              ),
                              const SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patientName,
                                      style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      'Lansia Terdaftar • RT 04 / RW 02',
                                      style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppDimensions.spaceMD),

                        // Segmented Control Tabs (Informasi Medis vs QR Code ICE)
                        Container(
                          padding: const EdgeInsets.all(3.0),
                          decoration: BoxDecoration(
                            color: AppColors.mintSurface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                            border: Border.all(color: AppColors.lightBorder, width: 1.0),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    FeedbackService.instance.triggerSuccessFeedback();
                                    setState(() => _selectedTabIndex = 0);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: _selectedTabIndex == 0 ? AppColors.primaryTeal : Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Informasi Medis',
                                      style: TextStyle(
                                        color: _selectedTabIndex == 0 ? Colors.white : AppColors.textDarkSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    FeedbackService.instance.triggerSuccessFeedback();
                                    setState(() => _selectedTabIndex = 1);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: _selectedTabIndex == 1 ? AppColors.primaryTeal : Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'QR Code ICE',
                                      style: TextStyle(
                                        color: _selectedTabIndex == 1 ? Colors.white : AppColors.textDarkSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppDimensions.spaceMD),

                        // Tab 0: Informasi Medis Lengkap
                        if (_selectedTabIndex == 0) ...[
                          // Kartu Golongan Darah
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.spaceMD),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                              border: Border.all(color: AppColors.lightBorder, width: 1.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 8.0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 54.0,
                                  height: 54.0,
                                  decoration: const BoxDecoration(
                                    color: AppColors.emergencyRed,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    card.bloodType,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'GOLONGAN DARAH',
                                        style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                                      ),
                                      Text(
                                        'Tipe ${card.bloodType}',
                                        style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppDimensions.spaceMD),

                          // Alergi Obat & Makanan
                          _MedicalSectionCard(
                            title: 'Alergi Obat & Makanan',
                            icon: Icons.warning_amber_rounded,
                            accentColor: AppColors.warningAmber,
                            items: card.allergies.isEmpty ? const ['Tidak ada riwayat alergi'] : card.allergies,
                          ),

                          const SizedBox(height: AppDimensions.spaceMD),

                          // Penyakit Kronis
                          _MedicalSectionCard(
                            title: 'Riwayat Penyakit Kronis',
                            icon: Icons.health_and_safety_outlined,
                            accentColor: AppColors.primaryTealDark,
                            items: card.chronicConditions.isEmpty
                                ? const ['Tidak ada riwayat penyakit kronis']
                                : card.chronicConditions,
                          ),

                          const SizedBox(height: AppDimensions.spaceMD),

                          // Kontak Dokter & Catatan Khusus
                          if (card.doctorName != null || card.doctorPhone != null || card.doctorNotes != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.spaceMD),
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                                border: Border.all(color: AppColors.lightBorder, width: 1.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.cardShadow,
                                    blurRadius: 8.0,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6.0),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryTealLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.local_hospital_rounded, color: AppColors.primaryTealDark, size: 20),
                                      ),
                                      const SizedBox(width: AppDimensions.spaceSM),
                                      Text(
                                        'Dokter / Faskes Rujukan',
                                        style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                                      ),
                                    ],
                                  ),
                                  if (card.doctorName != null) ...[
                                    const SizedBox(height: AppDimensions.spaceSM),
                                    Text(
                                      card.doctorName!,
                                      style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
                                    ),
                                  ],
                                  if (card.doctorNotes != null) ...[
                                    const SizedBox(height: 2.0),
                                    Text(
                                      'Catatan: ${card.doctorNotes}',
                                      style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                                    ),
                                  ],
                                  if (card.doctorPhone != null) ...[
                                    const SizedBox(height: AppDimensions.spaceMD),
                                    AccessibleButton(
                                      label: 'Hubungi Dokter (${card.doctorPhone})',
                                      onPressed: () => _callDoctor(card.doctorPhone!),
                                      backgroundColor: AppColors.primaryTealLight,
                                      textColor: AppColors.primaryTealDeep,
                                      borderColor: AppColors.primaryTeal,
                                      icon: Icons.phone_in_talk_rounded,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          // Tab 1: QR Code Medis
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.spaceXL),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                              border: Border.all(color: AppColors.lightBorder, width: 1.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 10.0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: _generateQrPayload(card, authProvider),
                                  version: QrVersions.auto,
                                  size: 190.0,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: AppColors.primaryTealDeep,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: AppColors.textDarkPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spaceMD),
                                Text(
                                  'QR MEDIS DARURAT SIGAP',
                                  style: AppTypography.standardTitle(color: AppColors.primaryTealDark),
                                ),
                                const SizedBox(height: AppDimensions.spaceXS),
                                Text(
                                  'Dapat dipindai langsung oleh Paramedis / Relawan untuk melihat data medis tanpa koneksi internet.',
                                  style: AppTypography.standardCaption(color: AppColors.textDarkSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppDimensions.spaceMD),

                        if (widget.isSelfView) ...[
                          AccessibleButton(
                            label: 'Perbarui Data Medis Saya',
                            onPressed: () => context.push('/profile/ice-card'),
                            backgroundColor: AppColors.primaryTeal,
                            icon: Icons.edit_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _MedicalSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<String> items;

  const _MedicalSectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.lightBorder, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20.0),
              const SizedBox(width: AppDimensions.spaceSM),
              Text(
                title,
                style: AppTypography.standardTitle(color: AppColors.textDarkPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: AppColors.textDarkPrimary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
