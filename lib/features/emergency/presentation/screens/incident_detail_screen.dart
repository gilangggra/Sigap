import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/components/accessible_button.dart';
import '../../domain/models/incident.dart';
import '../state/emergency_provider.dart';

/// Halaman Detail Penanganan Insiden Darurat untuk Responder, Guardian, dan Civic Admin
class IncidentDetailScreen extends StatefulWidget {
  final Incident incident;

  const IncidentDetailScreen({
    super.key,
    required this.incident,
  });

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLocking = false;
  bool _isResolving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleLockIncident() async {
    setState(() => _isLocking = true);
    unawaited(FeedbackService.instance.triggerSuccessFeedback());

    final authProvider = context.read<AuthProvider>();
    final emergencyProvider = context.read<EmergencyProvider>();
    final responderId = authProvider.userId ?? 'mock-responder-id';

    final success = await emergencyProvider.lockIncident(
      incidentId: widget.incident.id,
      responderId: responderId,
    );

    if (!mounted) return;
    setState(() => _isLocking = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.safeGreenDark,
          content: Text('Anda berhasil mengunci insiden! Peta navigasi diaktifkan.'),
        ),
      );
    }
  }

  Future<void> _openGoogleMapsRoute() async {
    final double lat = widget.incident.latitude;
    final double lng = widget.incident.longitude;
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callVictim() async {
    final phone = widget.incident.careReceiverPhone ?? '+628123456789';
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showResolveDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: const BorderSide(color: AppColors.darkBorderHighContrast),
          ),
          title: Text(
            'Tandai Insiden Selesai',
            style: AppTypography.seniorTitle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan catatan tindakan pertolongan pertama yang telah dilakukan:',
                style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Korban telah dibawa ke Puskesmas didampingi keluarga...',
                  hintStyle: TextStyle(color: AppColors.textDarkTertiary),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal', style: TextStyle(color: AppColors.textDarkTertiary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isResolving = true);

                final authProvider = context.read<AuthProvider>();
                final emergencyProvider = context.read<EmergencyProvider>();

                await emergencyProvider.resolveIncident(
                  incidentId: widget.incident.id,
                  resolvedBy: authProvider.userId ?? 'demo-user',
                  resolutionNotes: _notesController.text.trim().isEmpty
                      ? 'Insiden telah diselesaikan oleh relawan dan keluarga.'
                      : _notesController.text.trim(),
                );

                if (!mounted) return;
                setState(() => _isResolving = false);

                unawaited(FeedbackService.instance.triggerSuccessFeedback());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.safeGreenDark,
                    content: Text('Insiden berhasil ditutup. 50 poin sosial diberikan kepada relawan!'),
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.safeGreen),
              child: const Text('Selesaikan Insiden'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emergencyProvider = context.watch<EmergencyProvider>();
    final bool isLockedByMe = emergencyProvider.lockedIncidentId == widget.incident.id ||
        widget.incident.status == IncidentStatus.responding;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Detail Insiden Darurat'),
        backgroundColor: AppColors.emergencyRedDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Status Insiden
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  border: Border.all(color: AppColors.emergencyRed, width: 2.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRedDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.incident.status.label.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          widget.incident.gpsApproximate ? 'GPS Perkiraan' : 'GPS Akurat',
                          style: TextStyle(
                            color: widget.incident.gpsApproximate ? AppColors.warningAmberLight : AppColors.safeGreenLight,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    Text(
                      widget.incident.careReceiverName ?? 'Lansia SIGAP',
                      style: AppTypography.seniorHeadingMedium(color: Colors.white),
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.emergencyRedLight),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Expanded(
                          child: Text(
                            widget.incident.address ?? 'Koordinat (${widget.incident.latitude}, ${widget.incident.longitude})',
                            style: AppTypography.seniorBodySecondary(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceXL),

              // Tombol Rute & Kontak
              Row(
                children: [
                  Expanded(
                    child: AccessibleButton(
                      label: 'Buka Peta Navigasi',
                      onPressed: _openGoogleMapsRoute,
                      backgroundColor: AppColors.infoBlue,
                      icon: Icons.directions_run_rounded,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: AccessibleButton(
                      label: 'Telepon Korban',
                      onPressed: _callVictim,
                      backgroundColor: AppColors.safeGreen,
                      icon: Icons.phone_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceLG),

              // Tombol Tindakan Kunci Insiden / Data Medis
              if (!isLockedByMe) ...[
                AccessibleButton(
                  label: _isLocking ? 'Mengunci Insiden...' : 'SAYA MELUNCUR (RESPON DARURAT)',
                  onPressed: _isLocking ? null : _handleLockIncident,
                  backgroundColor: AppColors.emergencyRed,
                  textColor: Colors.white,
                  icon: Icons.flash_on_rounded,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.safeGreenDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: AppDimensions.spaceMD),
                      Text(
                        'Insiden Sedang Anda Tangani',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                AccessibleButton(
                  label: 'Lihat Data Medis (ICE Card 2 Jam)',
                  onPressed: () => context.push('/emergency/ice-card-view'),
                  backgroundColor: AppColors.infoBlueDark,
                  icon: Icons.medical_services_rounded,
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                AccessibleButton(
                  label: _isResolving ? 'Menyelesaikan...' : 'Tandai Selesai (Resolve)',
                  onPressed: _isResolving ? null : _showResolveDialog,
                  backgroundColor: AppColors.safeGreen,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
