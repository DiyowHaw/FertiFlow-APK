import 'package:flutter/material.dart';
import 'package:fertiflow/widgets/logo_pill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fertiflow/services/app_state.dart';
import 'package:fertiflow/screens/analysis_screen.dart';
import 'package:fertiflow/screens/zone_selection_screen.dart';
import 'package:fertiflow/services/zone_service.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final appState = AppState.instance;
        final theme = Theme.of(context);
        final history = appState.detectionHistory;

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
                  appState.tr('nav_ai'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'YOLOv8 Diagnostic HUD',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Camera Scan Frame (HUD Style)
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Centered Camera Indicator
                        Center(
                          child: Icon(
                            Icons.center_focus_strong_rounded,
                            size: 48,
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.3),
                          ),
                        ),

                        // Laser Scanner bar
                        AnimatedBuilder(
                          animation: _scannerController,
                          builder: (context, child) {
                            return Positioned(
                              top: 40 + (_scannerController.value * 200),
                              left: 30,
                              right: 30,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            );
                          },
                        ),

                        // Technical HUD Details
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MODEL: YOLOv8-Pest',
                                style: GoogleFonts.shareTechMono(
                                  color: const Color(0xFF10B981),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'FPS: 30.2 (RAW)',
                                style: GoogleFonts.shareTechMono(
                                  color: const Color(0xFF10B981),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          top: 16,
                          right: 16,
                          child: Text(
                            'ONLINE',
                            style: GoogleFonts.shareTechMono(
                              color: const Color(0xFF10B981),
                              fontSize: 11,
                            ),
                          ),
                        ),

                        // Scan HUD corner bounds
                        _buildHUDCorner(
                          top: 16,
                          left: 16,
                          isTop: true,
                          isLeft: true,
                        ),
                        _buildHUDCorner(
                          top: 16,
                          right: 16,
                          isTop: true,
                          isLeft: false,
                        ),
                        _buildHUDCorner(
                          bottom: 16,
                          left: 16,
                          isTop: false,
                          isLeft: true,
                        ),
                        _buildHUDCorner(
                          bottom: 16,
                          right: 16,
                          isTop: false,
                          isLeft: false,
                        ),

                        // Label
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appState.tr('camera_view').toUpperCase(),
                                style: GoogleFonts.shareTechMono(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Scan Button
                ElevatedButton.icon(
                  onPressed: () =>
                      _showImageSourceBottomSheet(context, appState, theme),
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    appState.tr('start_detection'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 32),

                // Latest Result
                if (history.isNotEmpty) ...[
                  Text(
                    appState.tr('latest_result'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildResultHUDCard(history.first, theme),
                  const SizedBox(height: 20),

                  // Symptoms details
                  _buildPestInfoCard(
                    history.first['label'] ?? 'Unknown',
                    appState,
                    theme,
                  ),
                  const SizedBox(height: 28),
                ],

                // History
                if (history.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appState.tr('detection_history'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${history.length - 1}',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: history.length - 1,
                      itemBuilder: (context, index) {
                        final item = history[index + 1];
                        return _buildHistoryItem(item, theme);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageSourceBottomSheet(
    BuildContext context,
    AppState appState,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                appState.locale.languageCode == 'id'
                    ? 'Pilih Gambar Tanaman'
                    : 'Select Plant Image',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appState.locale.languageCode == 'id'
                    ? 'Pilih sumber untuk mengambil atau memilih foto tanaman'
                    : 'Choose a source to take or pick a plant photo',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ZoneSelectionScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.document_scanner_rounded,
                              color: Color(0xFF10B981),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan Zona',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        ZoneService.instance.setActiveZone(null); // Clear zone for fast scan
                        _processImage(context, ImageSource.camera, appState);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFFF59E0B),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan Cepat',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showGalleryContextDialog(context, appState);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.photo_library_rounded,
                              color: Color(0xFF0EA5E9),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Galeri',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: const Color(0xFF0EA5E9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImage(
    BuildContext context,
    ImageSource source,
    AppState appState,
  ) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );

    if (photo != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(imagePath: photo.path),
        ),
      );
    }
  }
  void _showGalleryContextDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Pilih Konteks Gambar',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Scan Cepat (Umum)'),
                onTap: () {
                  Navigator.pop(ctx);
                  ZoneService.instance.setActiveZone(null);
                  _processImage(context, ImageSource.gallery, appState);
                },
              ),
              ...ZoneService.instance.zones.map((z) => ListTile(
                title: Text(z.name),
                onTap: () {
                  Navigator.pop(ctx);
                  ZoneService.instance.setActiveZone(z.id);
                  _processImage(context, ImageSource.gallery, appState);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

Widget _buildHUDCorner({
  double? top,
  double? bottom,
  double? left,
  double? right,
  required bool isTop,
  required bool isLeft,
}) {
  return Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF10B981), width: 2)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF10B981), width: 2)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF10B981), width: 2)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF10B981), width: 2)
              : BorderSide.none,
        ),
      ),
    ),
  );
}

Widget _buildResultHUDCard(Map<String, dynamic> item, ThemeData theme) {
  final severity = item['severity'] ?? 'Sedang';
  final String rawLabel = item['label'] ?? 'Unknown';
  final isEn = AppState.instance.locale.languageCode == 'en';

  String displayLabel = rawLabel;
  if (isEn) {
    if (rawLabel.contains('Kutu Daun')) displayLabel = 'Aphids';
    if (rawLabel.contains('Thrips')) displayLabel = 'Thrips';
    if (rawLabel.contains('Tungau')) displayLabel = 'Mites';
  }

  String displaySeverity = severity;
  if (isEn) {
    if (severity == 'Ringan') displaySeverity = 'Mild';
    if (severity == 'Sedang') displaySeverity = 'Moderate';
    if (severity == 'Berat') displaySeverity = 'Severe';
  }

  Color severityColor = const Color(0xFFF59E0B);
  if (severity == 'Berat') severityColor = const Color(0xFFEF4444);
  if (severity == 'Ringan') severityColor = const Color(0xFF10B981);

  return Container(
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
    ),
    child: Column(
      children: [
        // Crop Analysis Image Simulator
        Container(
          height: 160,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.center_focus_weak_rounded,
                  color: Colors.white.withValues(alpha: 0.05),
                  size: 64,
                ),
              ),
              // Precision Box
              Positioned(
                left: 60,
                right: 60,
                top: 30,
                bottom: 30,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: severityColor, width: 1.5),
                    color: severityColor.withValues(alpha: 0.1),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: severityColor,
                      child: Text(
                        '$displayLabel ${(item['confidence'] * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plant: ${item['plantId']}',
                    style: GoogleFonts.shareTechMono(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displaySeverity,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildPestInfoCard(String label, AppState appState, ThemeData theme) {
  String description = '';
  List<String> symptoms = [];

  if (label.contains('Thrips')) {
    description = appState.locale.languageCode == 'id'
        ? 'Serangga kecil yang mengikis sel daun, memicu bercak keperakan.'
        : 'Tiny pests feeding on leaf cells, causing silver scars.';
    symptoms = appState.locale.languageCode == 'id'
        ? ['Permukaan daun keperakan', 'Daun melengkung ke atas']
        : ['Silver-hued leaf scars', 'Leaves curl upwards'];
  } else {
    description = appState.locale.languageCode == 'id'
        ? 'Kutu daun kecil pengisap cairan nutrisi tanaman.'
        : 'Small insects sucking nutrient fluids from plants.';
    symptoms = appState.locale.languageCode == 'id'
        ? ['Daun melengkung mengkerut', 'Koloni kutu terlihat di bawah daun']
        : ['Curled and deformed leaves', 'Visible aphids under the leaves'];
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              appState.tr('pest_info'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          appState.tr('symptoms'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        ...symptoms.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                const Icon(Icons.lens, size: 5, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildHistoryItem(Map<String, dynamic> item, ThemeData theme) {
  return Container(
    width: 140,
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.bug_report_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
            Text(
              '${((item['confidence'] ?? 0) * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.shareTechMono(
                fontSize: 12,
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final String rawLabel = item['label'] ?? 'Unknown';
            final isEn = AppState.instance.locale.languageCode == 'en';
            String displayLabel = rawLabel;
            if (isEn) {
              if (rawLabel.contains('Kutu Daun')) displayLabel = 'Aphids';
              if (rawLabel.contains('Thrips')) displayLabel = 'Thrips';
              if (rawLabel.contains('Tungau')) displayLabel = 'Mites';
            }
            return Text(
              displayLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        Text(
          item['plantId'] ?? '',
          style: GoogleFonts.shareTechMono(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        Text(
          item['date'] ?? '',
          style: GoogleFonts.inter(
            fontSize: 9,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    ),
  );
}
