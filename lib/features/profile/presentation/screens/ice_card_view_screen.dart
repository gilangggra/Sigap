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
/// Dapat diakses dalam 2 mode:
/// 1. Self-View (Lansia/Keluarga): Menampilkan Medical Pass pribadi beserta QR Code offline untuk paramedis.
/// 2. Responder-View: Menggunakan Emergency Token (berlaku 2 jam) saat menangani insiden korban.
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
  bool _showQrCode = false;

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

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(widget.isSelfView ? 'Kartu Medis Digital (Medical ID)' : 'Data Medis Darurat Korban'),
        backgroundColor: widget.isSelfView ? AppColors.darkSurface : AppColors.emergencyRedDark,
      ),
      body: SafeArea(
        child: profileProvider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.emergencyRed),
                ),
              )
            : card == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spaceXL),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.gpp_bad_rounded, color: AppColors.emergencyRedLight, size: 64.0),
                          const SizedBox(height: AppDimensions.spaceMD),
                          Text(
                            widget.isSelfView
                                ? 'Data Medis Belum Diisi'
                                : 'Akses Ditolak / Token Kedaluwarsa',
                            style: AppTypography.seniorTitle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spaceSM),
                          Text(
                            widget.isSelfView
                                ? 'Silakan lengkapi profil medis darurat Anda terlebih dahulu.'
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
                              backgroundColor: AppColors.safeGreen,
                              icon: Icons.edit_note_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.spaceLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Watermark / Badge Otorisasi Resmi
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceMD),
                          decoration: BoxDecoration(
                            color: widget.isSelfView
                                ? AppColors.infoBlue.withValues(alpha: 0.15)
                                : AppColors.emergencyRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                            border: Border.all(
                              color: widget.isSelfView ? AppColors.infoBlueLight : AppColors.emergencyRed,
                              width: 2.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.isSelfView ? Icons.badge_rounded : Icons.verified_user_rounded,
                                color: widget.isSelfView ? AppColors.infoBlueLight : AppColors.emergencyRedLight,
                                size: 30.0,
                              ),
                              const SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.isSelfView
                                          ? 'Kartu Medis Resmi Warga'
                                          : 'Akses Darurat Aktif (2 Jam)',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
                                    ),
                                    Text(
                                      widget.isSelfView
                                          ? 'Tersimpan terenkripsi di perangkat untuk akses penyelamatan cepat.'
                                          : 'Akses Anda telah dicatat di Audit Log sistem bersama stempel waktu.',
                                      style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceLG),

                        // Tombol Toggle QR Code Medis (Tampak Jelas untuk Paramedis)
                        AccessibleButton(
                          label: _showQrCode ? 'SEMBUNYIKAN QR CODE MEDIS' : 'TAMPILKAN QR CODE DARURAT (ICE)',
                          onPressed: () {
                            FeedbackService.instance.triggerSuccessFeedback();
                            setState(() => _showQrCode = !_showQrCode);
                          },
                          backgroundColor: _showQrCode ? AppColors.darkCard : AppColors.emergencyRed,
                          borderColor: AppColors.darkBorderHighContrast,
                          icon: _showQrCode ? Icons.qr_code_rounded : Icons.qr_code_scanner_rounded,
                        ),

                        // Tampilan QR Code Medis Resolusi Tinggi
                        if (_showQrCode) ...[
                          const SizedBox(height: AppDimensions.spaceLG),
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.spaceXL),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 10.0,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: _generateQrPayload(card, authProvider),
                                  version: QrVersions.auto,
                                  size: 220.0,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Colors.black,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spaceMD),
                                const Text(
                                  'QR MEDIS DARURAT SIGAP',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spaceXS),
                                const Text(
                                  'Dapat dipindai langsung oleh Paramedis / Dokter IGD untuk melihat golongan darah, alergi, dan kontak darurat secara instan.',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13.0,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppDimensions.spaceLG),

                        // Kartu Golongan Darah Besar
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceLG),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                            border: Border.all(color: AppColors.darkBorderHighContrast),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 72.0,
                                height: 72.0,
                                decoration: const BoxDecoration(
                                  color: AppColors.emergencyRed,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  card.bloodType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spaceLG),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GOLONGAN DARAH',
                                      style: AppTypography.standardCaption(color: AppColors.textDarkTertiary),
                                    ),
                                    Text(
                                      card.bloodType,
                                      style: AppTypography.seniorHeadingMedium(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceLG),

                        // Alergi Obat & Makanan (Kritis untuk penolong)
                        _MedicalSectionCard(
                          title: 'ALERGI OBAT & MAKANAN',
                          icon: Icons.warning_amber_rounded,
                          accentColor: AppColors.warningAmber,
                          items: card.allergies.isEmpty ? const ['Tidak ada riwayat alergi'] : card.allergies,
                        ),
                        const SizedBox(height: AppDimensions.spaceLG),

                        // Penyakit Kronis
                        _MedicalSectionCard(
                          title: 'RIWAYAT PENYAKIT KRONIS',
                          icon: Icons.health_and_safety_outlined,
                          accentColor: AppColors.infoBlueLight,
                          items: card.chronicConditions.isEmpty
                              ? const ['Tidak ada riwayat penyakit kronis']
                              : card.chronicConditions,
                        ),
                        const SizedBox(height: AppDimensions.spaceLG),

                        // Kontak Dokter & Catatan Khusus
                        if (card.doctorName != null || card.doctorPhone != null || card.doctorNotes != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.spaceLG),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                              border: Border.all(color: AppColors.darkBorderHighContrast),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_hospital_rounded, color: AppColors.safeGreenLight),
                                    const SizedBox(width: AppDimensions.spaceSM),
                                    Text(
                                      'DOKTER / FASILITAS RUJUKAN',
                                      style: AppTypography.standardTitle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                if (card.doctorName != null) ...[
                                  const SizedBox(height: AppDimensions.spaceMD),
                                  Text(
                                    card.doctorName!,
                                    style: AppTypography.seniorTitle(color: Colors.white),
                                  ),
                                ],
                                if (card.doctorNotes != null) ...[
                                  const SizedBox(height: AppDimensions.spaceSM),
                                  Text(
                                    'Catatan: ${card.doctorNotes}',
                                    style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                                  ),
                                ],
                                if (card.doctorPhone != null) ...[
                                  const SizedBox(height: AppDimensions.spaceLG),
                                  AccessibleButton(
                                    label: 'Telepon Dokter (${card.doctorPhone})',
                                    onPressed: () => _callDoctor(card.doctorPhone!),
                                    backgroundColor: AppColors.safeGreen,
                                    icon: Icons.phone_in_talk_rounded,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space2XL),
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
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.darkBorderHighContrast),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24.0),
              const SizedBox(width: AppDimensions.spaceSM),
              Text(title, style: AppTypography.standardTitle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  border: Border.all(color: accentColor),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
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
