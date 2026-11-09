import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../state/profile_provider.dart';

/// Halaman Tampilan Data Medis Korban (ICE Card Viewer)
/// Hanya dapat diakses oleh Responder yang telah mengunci insiden darurat aktif
/// melalui Emergency Token yang divalidasi server (berlaku 2 jam).
class IceCardViewScreen extends StatefulWidget {
  final String? emergencyToken;

  const IceCardViewScreen({
    super.key,
    this.emergencyToken,
  });

  @override
  State<IceCardViewScreen> createState() => _IceCardViewScreenState();
}

class _IceCardViewScreenState extends State<IceCardViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVictimIceCard();
    });
  }

  Future<void> _loadVictimIceCard() async {
    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();

    final token = widget.emergencyToken ?? 'DEMO-EMERGENCY-TOKEN';
    final responderId = authProvider.userId ?? 'responder-001';

    await profileProvider.accessEmergencyIceCard(
      token: token,
      responderId: responderId,
    );
  }

  Future<void> _callDoctor(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final card = profileProvider.emergencyIceCard;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Data Medis Darurat Korban'),
        backgroundColor: AppColors.emergencyRedDark,
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
                            'Akses Ditolak / Token Kedaluwarsa',
                            style: AppTypography.seniorTitle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spaceSM),
                          Text(
                            profileProvider.errorMessage ??
                                'Token darurat hanya berlaku 2 jam selama insiden aktif.',
                            style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                            textAlign: TextAlign.center,
                          ),
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
                            color: AppColors.emergencyRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                            border: Border.all(color: AppColors.emergencyRed, width: 2.0),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: AppColors.emergencyRedLight, size: 30.0),
                              SizedBox(width: AppDimensions.spaceMD),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Akses Darurat Aktif (2 Jam)',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
                                    ),
                                    Text(
                                      'Akses Anda telah dicatat di Audit Log sistem bersama stempel waktu.',
                                      style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXL),

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
