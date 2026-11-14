import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fertiflow/widgets/logo_pill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/app_state.dart';

class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final appState = AppState.instance;
        final theme = Theme.of(context);
        final treatmentsList = appState.localizedTreatments;

        final pendingTreatments = treatmentsList
            .where((t) => t['status'] != 'done')
            .toList();
        final doneTreatments = treatmentsList
            .where((t) => t['status'] == 'done')
            .toList();

        // Jika panduan penanganan masih kosong (belum ada tanaman dipindai/rekomendasi disimpan)
        if (treatmentsList.isEmpty) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Pill
                  const LogoPill(),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    appState.tr('nav_treatment'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.locale.languageCode == 'id'
                        ? 'Panduan Penanganan'
                        : 'Treatment Guide',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.spa_outlined,
                              size: 34,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            appState.locale.languageCode == 'id'
                                ? 'Belum Ada Panduan Penanganan'
                                : 'No Treatment Guides Yet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            appState.locale.languageCode == 'id'
                                ? 'Panduan penanganan akan muncul secara otomatis setelah Anda melakukan deteksi penyakit tanaman cabai atau berkonsultasi dengan Asisten AI.'
                                : 'Treatment guides will appear here after you run a chili plant scan or consult the AI Assistant.',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              height: 1.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton.icon(
                            onPressed: () => appState.setNavIndex(2),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.document_scanner_outlined, size: 17),
                            label: Text(
                              appState.locale.languageCode == 'id'
                                  ? 'Mulai Deteksi Sekarang'
                                  : 'Start Detection Now',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Pill
                const LogoPill(),
                const SizedBox(height: 24),

                // Header
                Text(
                  appState.tr('nav_treatment'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appState.locale.languageCode == 'id'
                      ? 'Panduan Penanganan'
                      : 'Treatment Guide',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // AI Recommendation Card
                if (pendingTreatments.isNotEmpty) ...[
                  _buildAIRecommendationCard(
                    pendingTreatments.first,
                    appState,
                    theme,
                  ),
                  const SizedBox(height: 28),
                ],

                // Pending Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appState.tr('needs_attention'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${pendingTreatments.length}',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pendingTreatments.isEmpty)
                  _buildEmptyState(
                    appState.locale.languageCode == 'id'
                        ? 'Semua tanaman sehat!'
                        : 'All plants are healthy!',
                    theme,
                  )
                else
                  ...pendingTreatments.map(
                    (t) => _buildTreatmentCard(t, appState, theme, context),
                  ),

                const SizedBox(height: 28),

                // Done Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appState.tr('treatment_done'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${doneTreatments.length}',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (doneTreatments.isEmpty)
                  _buildEmptyState(
                    appState.locale.languageCode == 'id'
                        ? 'Belum ada tindakan selesai.'
                        : 'No completed treatments yet.',
                    theme,
                  )
                else
                  ...doneTreatments.map(
                    (t) => _buildCompletedCard(t, appState, theme, context),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildAIRecommendationCard(
  Map<String, dynamic> item,
  AppState appState,
  ThemeData theme,
) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              appState.tr('ai_recommendation'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          item['recommendation'] ?? '',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'FertiFlow Engine v1.0 - YOLOv8 Analyzer',
          style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 10),
        ),
      ],
    ),
  );
}

Widget _buildTreatmentCard(
  Map<String, dynamic> item,
  AppState appState,
  ThemeData theme,
  BuildContext context,
) {
  final String status = item['status'] ?? 'pending';
  final String severity = item['severity'] ?? 'Sedang';
  final bool isIrrigationRec = item['type'] == 'irrigation_recommendation' || item['watering_times'] != null;
  final bool isAlreadyScheduled = item['added_to_schedule'] == true ||
      appState.schedules.any((s) => s['recommendation_id'] != null && s['recommendation_id'] == (item['recommendation_id'] ?? item['id']));

  Color severityColor = const Color(0xFFF59E0B);
  if (severity == 'Berat' || severity == 'Severe') {
    severityColor = const Color(0xFFEF4444);
  }
  if (severity == 'Ringan' || severity == 'Mild') {
    severityColor = const Color(0xFF10B981);
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isIrrigationRec
            ? const Color(0xFF10B981).withValues(alpha: 0.35)
            : theme.dividerColor.withValues(alpha: 0.5),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item['imagePath'] != null &&
            item['imagePath'].toString().isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(item['imagePath']),
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 40,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  item['plantId'] ?? '',
                  style: GoogleFonts.shareTechMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isIrrigationRec ? const Color(0xFF10B981) : severityColor).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isIrrigationRec
                        ? (appState.locale.languageCode == 'id' ? 'Rekomendasi AI' : 'AI Plan')
                        : severity,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isIrrigationRec ? const Color(0xFF10B981) : severityColor,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18,
              tooltip: appState.locale.languageCode == 'id' ? 'Hapus Penanganan' : 'Delete Treatment',
              onPressed: () {
                _confirmDeleteTreatment(context, appState, item['id']?.toString() ?? '');
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              isIrrigationRec ? Icons.water_drop_rounded : Icons.bug_report_rounded,
              color: isIrrigationRec ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isIrrigationRec
                    ? 'Rekomendasi Penyiraman Presisi (${item['plantName'] ?? 'Cabai'})'
                    : (item['pestName'] ?? ''),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Treatment Steps list
        ...((item['steps'] as List<dynamic>?) ?? []).map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.lens, size: 5, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Alasan / Keterangan Rekomendasi
        if (item['recommendation'] != null &&
            (item['recommendation'] as String).isNotEmpty &&
            isIrrigationRec) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['recommendation'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Saran Pestisida (jika penyakit)
        if (item['pesticide'] != null &&
            (item['pesticide'] as String).isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.science_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.locale.languageCode == 'id'
                            ? 'Saran Obat/Pestisida'
                            : 'Recommended Pesticide',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['pesticide'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Status indicator and action button (FR-07)
        if (isIrrigationRec) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isAlreadyScheduled ? const Color(0xFF10B981) : const Color(0xFF0EA5E9)).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isAlreadyScheduled ? const Color(0xFF10B981) : const Color(0xFF0EA5E9)).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAlreadyScheduled ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                      size: 14,
                      color: isAlreadyScheduled ? const Color(0xFF10B981) : const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAlreadyScheduled
                          ? (appState.locale.languageCode == 'id' ? 'Jadwal Aktif' : 'Scheduled')
                          : (appState.locale.languageCode == 'id' ? 'Menunggu Penjadwalan' : 'Pending Schedule'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAlreadyScheduled ? const Color(0xFF10B981) : const Color(0xFF0EA5E9),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: isAlreadyScheduled
                        ? null
                        : () {
                            final days = (item['days'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Sen', 'Rab', 'Jum'];
                            final success = appState.addSchedule(
                              item['watering_times']?.toString() ?? '06:30',
                              'Air',
                              item['volume']?.toString() ?? '2.0 L',
                              days,
                              zone: item['plantId']?.toString() ?? 'Zona A',
                              durationSeconds: (item['duration_seconds'] as num?)?.toInt() ?? 20,
                              recommendationId: item['recommendation_id']?.toString() ?? item['id']?.toString(),
                              status: 'Aktif',
                              source: 'AI Recommendation',
                            );
                            if (success) {
                              item['added_to_schedule'] = true;
                              appState.refresh();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF1E293B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                                  duration: const Duration(seconds: 3),
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Jadwal penyiraman otomatis berhasil dibuat dan diaktifkan!',
                                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF1E293B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                                  duration: const Duration(seconds: 3),
                                  content: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Jadwal serupa sudah terdaftar di menu Jadwal.',
                                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAlreadyScheduled
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFF0EA5E9),
                      foregroundColor: isAlreadyScheduled ? const Color(0xFF10B981) : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      isAlreadyScheduled ? Icons.done_all_rounded : Icons.alarm_add_rounded,
                      size: 16,
                      color: isAlreadyScheduled ? const Color(0xFF10B981) : Colors.white,
                    ),
                    label: Text(
                      isAlreadyScheduled ? 'Terdaftar di Jadwal' : 'Tambahkan ke Jadwal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAlreadyScheduled ? const Color(0xFF10B981) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      appState.updateTreatmentStatus(item['id'].toString(), 'done');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(
                      appState.locale.languageCode == 'id' ? 'Selesai' : 'Done',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: status == 'spraying'
                      ? const Color(0xFFF97316).withValues(alpha: 0.08)
                      : const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: status == 'spraying'
                        ? const Color(0xFFF97316).withValues(alpha: 0.2)
                        : const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'spraying'
                          ? Icons.hourglass_top_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: status == 'spraying'
                          ? const Color(0xFFF97316)
                          : const Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status == 'spraying'
                          ? (appState.locale.languageCode == 'id'
                                ? 'Sedang Ditangani'
                                : 'In Treatment')
                          : (appState.locale.languageCode == 'id'
                                ? 'Menunggu Penanganan'
                                : 'Awaiting Treatment'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: status == 'spraying'
                            ? const Color(0xFFF97316)
                            : const Color(0xFF0EA5E9),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  appState.updateTreatmentStatus(item['id'].toString(), 'done');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(
                  appState.locale.languageCode == 'id' ? 'Selesai' : 'Done',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildCompletedCard(
  Map<String, dynamic> item,
  AppState appState,
  ThemeData theme,
  BuildContext context,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: theme.cardColor.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        if (item['imagePath'] != null &&
            item['imagePath'].toString().isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(item['imagePath']),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 18,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['plantId'] ?? '',
                style: GoogleFonts.shareTechMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item['pestName'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Text(
          item['date'] ?? '',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 18,
          tooltip: appState.locale.languageCode == 'id' ? 'Hapus' : 'Delete',
          onPressed: () {
            _confirmDeleteTreatment(context, appState, item['id']?.toString() ?? '');
          },
        ),
      ],
    ),
  );
}

void _confirmDeleteTreatment(BuildContext context, AppState appState, String id) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        appState.locale.languageCode == 'id'
            ? 'Hapus Panduan Penanganan?'
            : 'Delete Treatment Guide?',
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Text(
        appState.locale.languageCode == 'id'
            ? 'Panduan penanganan ini akan dihapus secara permanen.'
            : 'This treatment guide will be permanently removed.',
        style: GoogleFonts.inter(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            appState.locale.languageCode == 'id' ? 'Batal' : 'Cancel',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            appState.deleteTreatment(id);
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                duration: const Duration(seconds: 2),
                content: Text(
                  appState.locale.languageCode == 'id'
                      ? 'Panduan penanganan berhasil dihapus.'
                      : 'Treatment guide removed.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            appState.locale.languageCode == 'id' ? 'Hapus' : 'Delete',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget _buildEmptyState(String text, ThemeData theme) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: BoxDecoration(
      color: theme.cardColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
    ),
    child: Center(
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    ),
  );
}
