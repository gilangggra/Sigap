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
import '../../../../shared/components/components.dart';
import '../../domain/models/incident.dart';
import '../state/emergency_provider.dart';

/// Halaman Detail Penanganan Insiden Darurat untuk Responder, Guardian, dan Civic Admin.
/// Menggunakan standar tema kesehatan modern, tata letak mobile rapi, dan tipografi Poppins konsisten.
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
    final responderId = authProvider.userId ?? AppConstants.demoUserId;

    final success = await emergencyProvider.lockIncident(
      incidentId: widget.incident.id,
      responderId: responderId,
    );

    if (!mounted) return;
    setState(() => _isLocking = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.safeGreenDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
          content: const Text('Anda berhasil mengunci insiden! Peta navigasi diaktifkan.'),
        ),
      );
    }
  }

  Future<void> _openGoogleMapsRoute() async {
    final double lat = widget.incident.latitude;
    final double lng = widget.incident.longitude;
    final Uri googleMapsAppUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final Uri googleMapsWebUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsAppUri)) {
        await launchUrl(googleMapsAppUri);
      } else if (await canLaunchUrl(googleMapsWebUri)) {
        await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (await canLaunchUrl(googleMapsWebUri)) {
        await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
      }
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
          backgroundColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: const BorderSide(color: AppColors.lightBorder),
          ),
          title: Text(
            'Tandai Insiden Selesai',
            style: AppTypography.standardHeadline(color: AppColors.textDarkPrimary),
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
                style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 14.0),
                decoration: InputDecoration(
                  hintText: 'Contoh: Korban telah dibawa ke Puskesmas didampingi keluarga...',
                  hintStyle: const TextStyle(color: AppColors.textDarkTertiary, fontSize: 13.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: const BorderSide(color: AppColors.lightBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal', style: TextStyle(color: AppColors.textDarkSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isResolving = true);

                final authProvider = context.read<AuthProvider>();
                final emergencyProvider = context.read<EmergencyProvider>();

                await emergencyProvider.resolveIncident(
                  incidentId: widget.incident.id,
                  resolvedBy: authProvider.userId ?? AppConstants.demoUserId,
                  resolutionNotes: _notesController.text.trim().isEmpty
                      ? 'Insiden telah diselesaikan oleh relawan dan keluarga.'
                      : _notesController.text.trim(),
                );

                if (!mounted) return;
                setState(() => _isResolving = false);

                unawaited(FeedbackService.instance.triggerSuccessFeedback());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.safeGreenDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
                    content: const Text('Insiden berhasil diselesaikan. Terima kasih atas kepedulian dan kesigapan Anda!'),
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
              ),
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
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Detail Insiden Darurat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20.0),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMD,
            vertical: AppDimensions.spaceMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Status Insiden
              AppCard.emergency(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppBadge.danger(widget.incident.status.label.toUpperCase(), icon: Icons.emergency_rounded),
                        const Spacer(),
                        AppBadge.neutral(
                          widget.incident.gpsApproximate ? 'GPS Perkiraan' : 'GPS Akurat',
                          icon: widget.incident.gpsApproximate ? Icons.near_me_outlined : Icons.gps_fixed_rounded,
                          isSmall: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    Text(
                      widget.incident.careReceiverName ?? 'Lansia SIGAP',
                      style: AppTypography.seniorTitle(color: AppColors.textDarkPrimary),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.emergencyRed, size: 18.0),
                        const SizedBox(width: AppDimensions.spaceSM),
                        Expanded(
                          child: Text(
                            widget.incident.address ?? 'Koordinat (${widget.incident.latitude}, ${widget.incident.longitude})',
                            style: AppTypography.standardBody(color: AppColors.textDarkSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Rute & Kontak Korban
              Row(
                children: [
                  Expanded(
                    child: AccessibleButton(
                      label: 'Peta Rute',
                      onPressed: _openGoogleMapsRoute,
                      backgroundColor: AppColors.primaryTeal,
                      textColor: Colors.white,
                      icon: Icons.directions_run_rounded,
                      isSimplified: false,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: AccessibleButton(
                      label: 'Telepon',
                      onPressed: _callVictim,
                      backgroundColor: AppColors.safeGreenDark,
                      textColor: Colors.white,
                      icon: Icons.phone_rounded,
                      isSimplified: false,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spaceMD),

              // Tombol Tindakan Kunci Insiden / Data Medis
              if (!isLockedByMe) ...[
                AccessibleButton(
                  label: _isLocking ? 'Mengunci Insiden...' : 'SAYA MELUNCUR (RESPON DARURAT)',
                  onPressed: _isLocking ? null : _handleLockIncident,
                  backgroundColor: AppColors.emergencyRed,
                  textColor: Colors.white,
                  icon: Icons.flash_on_rounded,
                  isSimplified: false,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: AppColors.safeGreenDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18.0),
                      SizedBox(width: AppDimensions.spaceSM),
                      Text(
                        'Insiden Sedang Anda Tangani',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                AccessibleButton(
                  label: 'Lihat Data Medis (ICE Card 2 Jam)',
                  onPressed: () => context.push(
                    '/emergency/ice-card-view',
                    extra: 'EMERGENCY-TOKEN-${widget.incident.id}',
                  ),
                  backgroundColor: AppColors.mintSurface,
                  borderColor: AppColors.lightBorder,
                  textColor: AppColors.primaryTealDark,
                  icon: Icons.medical_services_outlined,
                  isSimplified: false,
                ),
                const SizedBox(height: AppDimensions.spaceSM),
                AccessibleButton(
                  label: _isResolving ? 'Menyelesaikan...' : 'Tandai Selesai (Resolve)',
                  onPressed: _isResolving ? null : _showResolveDialog,
                  backgroundColor: AppColors.safeGreen,
                  textColor: Colors.white,
                  icon: Icons.check_circle_outline,
                  isSimplified: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
