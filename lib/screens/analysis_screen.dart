import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/app_state.dart';
import 'package:fertiflow/services/roboflow_service.dart';
import 'package:fertiflow/services/yolo_tflite_service.dart';
import 'package:fertiflow/services/zone_service.dart';
import 'package:fertiflow/screens/smart_consultation_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnalyzing = true;
  String _currentStatusText = 'Menghubungkan ke Roboflow Cloud...';
  int _statusIndex = 0;
  late Timer _statusTimer;
  late Map<String, dynamic> _detectionResult;

  final List<String> _idStatuses = [
    'Mengunggah gambar ke cloud...',
    'Menganalisis menggunakan Roboflow API...',
    'Mengekstrak fitur helai daun...',
    'Mendeteksi pola hama/penyakit...',
    'Menghitung tingkat keparahan...',
    'Selesai!'
  ];

  final List<String> _enStatuses = [
    'Uploading image to cloud...',
    'Analyzing via Roboflow API...',
    'Extracting leaf features...',
    'Detecting pest/disease patterns...',
    'Calculating severity score...',
    'Completed!'
  ];

  @override
  void initState() {
    super.initState();
    final appState = AppState.instance;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    final isEn = appState.locale.languageCode == 'en';
    final statuses = isEn ? _enStatuses : _idStatuses;
    _currentStatusText = statuses[0];

    // Status changer timer
    _statusTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_statusIndex < statuses.length - 1) {
        setState(() {
          _statusIndex++;
          _currentStatusText = statuses[_statusIndex];
        });
      }
    });

    _performRealAnalysis(isEn);
  }

  Future<void> _performRealAnalysis(bool isEn) async {
    final appState = AppState.instance;
    try {
      // Jalankan inferensi secara paralel untuk TFLite (Lokal) dan Roboflow (Cloud)
      final results = await Future.wait([
        YoloTfliteService.instance.predict(widget.imagePath).catchError((e) {
          debugPrint('TFLite Error: $e');
          return {'label': 'Error', 'confidence': 0.0, 'severity': 'Unknown'};
        }),
        RoboflowService.analyzeImage(widget.imagePath).catchError((e) {
          debugPrint('Roboflow Error: $e');
          return {'label': 'Error', 'confidence': 0.0, 'severity': 'Unknown'};
        }),
      ]);

      final tfliteResult = results[0];
      final roboflowResult = results[1];

      double tfConf = (tfliteResult['confidence'] ?? 0.0) as double;
      double roboConf = (roboflowResult['confidence'] ?? 0.0) as double;
      bool isYellowish = tfliteResult['isYellowish'] == true;

      // Logika Ensemble Cerdas:
      // 0. Jika bukan daun/tanaman cabai (Tidak Diketahui dari analisis spektrum botani), langsung tolak!
      if (tfliteResult['label'] == 'Tidak Diketahui') {
        _detectionResult = {
          'label': 'Tidak Diketahui',
          'confidence': 0.0,
          'severity': 'Tidak Diketahui',
        };
      } else if (isYellowish || tfliteResult['label'] == 'Yellowish Leaf' || roboflowResult['label'] == 'Yellowish Leaf') {
        // Daun secara nyata menguning (klorosis/defisiensi hara/virus kuning)
        _detectionResult = {
          'label': 'Yellowish Leaf',
          'confidence': isYellowish ? 0.90 : (tfConf > roboConf ? tfConf : roboConf).clamp(0.70, 0.96),
          'severity': 'Sedang',
        };
      } else {
        bool isTFDisease = tfliteResult['label'] != 'Sehat' &&
            !tfliteResult['label'].toString().contains('Error') &&
            !tfliteResult['label'].toString().contains('Tidak');
        bool isRoboDisease = roboflowResult['label'] != 'Sehat' &&
            !roboflowResult['label'].toString().contains('Error') &&
            !roboflowResult['label'].toString().contains('Tidak Ditemukan');

        if (isRoboDisease && roboConf >= 0.50) {
          _detectionResult = roboflowResult;
        } else if (isTFDisease && tfConf >= 0.50) {
          _detectionResult = tfliteResult;
        } else if (tfliteResult['label'] == 'Sehat' || roboflowResult['label'] == 'Sehat') {
          _detectionResult = {
            'label': 'Sehat',
            'confidence': tfConf > 0.5 ? tfConf : 0.85,
            'severity': 'Sehat',
          };
        } else {
          // Tidak ada keyakinan yang cukup bahwa ini daun cabai valid
          _detectionResult = {
            'label': 'Tidak Diketahui',
            'confidence': 0.0,
            'severity': 'Tidak Diketahui',
          };
        }
      }
      
    } catch (e, stacktrace) {
      debugPrint('Ensemble Error: $e');
      debugPrint('Stacktrace: $stacktrace');
      _detectionResult = {'label': 'Error', 'confidence': 0.0, 'severity': 'Unknown'};
    }

    // Tambahkan delay buatan agar animasi scan terlihat (karena TFLite terlalu cepat)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      _statusTimer.cancel();
      setState(() {
        _isAnalyzing = false;
        _currentStatusText = isEn ? 'Completed!' : 'Selesai!';
      });
      _animationController.stop();

      // Only add to history if not error
      if (!_detectionResult['label'].contains('Error')) {
        appState.detectionHistory.insert(0, {
          'label': _detectionResult['label'],
          'confidence': _detectionResult['confidence'],
          'severity': _detectionResult['severity'],
          'plantId': ZoneService.instance.activeZone?.name ?? 'Tanaman #${(DateTime.now().second % 12) + 1}',
          'date': '${DateTime.now().day} Jul ${DateTime.now().year}',
          'imagePath': widget.imagePath,
        });

        // Add to treatments log ONLY if NOT healthy and NOT unknown
        final label = _detectionResult['label'].toString();
        if (label != 'Sehat' && label != 'Tidak Diketahui') {
          String recommendation = '';
          List<String> steps = [];

          if (label == 'Leaf Curl') {
            recommendation = isEn 
              ? 'Apply abamectin or imidacloprid insecticide to control aphids/thrips causing leaf curl.'
              : 'Semprotkan insektisida berbahan aktif abamektin atau imidakloprid untuk mengendalikan kutu/thrips penyebab keriting daun.';
            steps = isEn 
              ? ['Prepare insecticide solution according to dose', 'Spray evenly on all leaves', 'Recheck after 5 days']
              : ['Siapkan larutan insektisida sesuai dosis', 'Semprot merata ke seluruh daun', 'Periksa kembali setelah 5 hari'];
          } else if (label == 'Leaf Spot') {
            recommendation = isEn 
              ? 'Apply mancozeb or propineb fungicide. Reduce humidity around the plant.'
              : 'Gunakan fungisida berbahan aktif mankozeb atau propineb. Kurangi kelembapan di sekitar tanaman.';
            steps = isEn 
              ? ['Remove infected leaves', 'Apply fungicide to plants', 'Ensure good air circulation']
              : ['Buang daun yang terinfeksi parah', 'Aplikasikan fungisida', 'Pastikan sirkulasi udara baik'];
          } else if (label == 'Yellowish Leaf') {
            recommendation = isEn 
              ? 'Apply NPK/Micro fertilizer. Control whiteflies if present.'
              : 'Berikan pupuk NPK tambahan atau pupuk mikro. Basmi vektor kutu kebul jika ada.';
            steps = isEn 
              ? ['Apply NPK/Micro fertilizer', 'Check for whiteflies', 'Water sufficiently']
              : ['Berikan pupuk NPK/Mikro', 'Cek keberadaan kutu kebul', 'Siram dengan cukup'];
          } else if (label == 'Embun Tepung') {
            recommendation = isEn 
              ? 'Apply difenoconazole or sulfur fungicide.'
              : 'Semprotkan fungisida berbahan aktif difenokonazol atau sulfur.';
            steps = isEn 
              ? ['Prepare fungicide solution', 'Spray in the morning', 'Recheck after 5 days']
              : ['Siapkan larutan fungisida', 'Semprot pada pagi hari', 'Periksa kembali setelah 5 hari'];
          } else {
            // Serangan Hama
            recommendation = isEn 
              ? 'Use broad-spectrum pesticide or organic neem oil.'
              : 'Gunakan pestisida spektrum luas atau pestisida nabati (neem oil).';
            steps = isEn 
              ? ['Prepare neem oil solution', 'Spray evenly on the underside of leaves', 'Repeat after 3 days']
              : ['Siapkan larutan neem oil', 'Semprot merata pada bagian bawah daun', 'Ulangi setelah 3 hari'];
          }

          // Determine appropriate pesticide based on label
          String pesticide = '';
          if (label == 'Leaf Curl') {
            pesticide = isEn ? 'Abamectin or Imidacloprid' : 'Abamektin atau Imidakloprid';
          } else if (label == 'Leaf Spot') {
            pesticide = isEn ? 'Mancozeb or Propineb' : 'Mankozeb atau Propineb';
          } else if (label == 'Yellowish Leaf') {
            pesticide = isEn ? 'NPK fertilizer (not a pesticide)' : 'Pupuk NPK (bukan pestisida)';
          } else if (label == 'Embun Tepung') {
            pesticide = isEn ? 'Difenoconazole or Sulfur' : 'Difenokonazol atau Sulfur';
          } else {
            pesticide = isEn ? 'Neem oil (broad-spectrum organic)' : 'Neem oil (organik spektrum luas)';
          }

          appState.addTreatment({
            'id': 't_${DateTime.now().millisecondsSinceEpoch}',
            'plantId': ZoneService.instance.activeZone?.name ?? 'Tanaman #${(DateTime.now().second % 12) + 1}',
            'pestName': label,
            'severity': _detectionResult['severity'],
            'status': 'pending',
            'imagePath': widget.imagePath,
            'recommendation': recommendation,
            'steps': steps,
            'pesticide': pesticide,
            'date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
          });
          
          if (ZoneService.instance.activeZone != null) {
            ZoneService.instance.updateZoneDiagnosis(
              ZoneService.instance.activeZone!.id, 
              label, 
              _detectionResult['severity']
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statusTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.instance;
    final isEn = appState.locale.languageCode == 'en';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEn ? 'AI Diagnostician' : 'Diagnosis AI',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _isAnalyzing
              ? _buildScanningView(theme, isEn)
              : _buildResultView(theme, appState, isEn),
        ),
      ),
    );
  }

  Widget _buildScanningView(ThemeData theme, bool isEn) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Camera Scan Frame (HUD Style)
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),

                // Dark overlay to make scanning scan laser more visible
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                ),

                // Laser Scanner bar
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Positioned(
                      top: 40 + (_animationController.value * 240),
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.8),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    );
                  },
                ),

                // HUD corners overlay
                _buildHUDCorner(top: 16, left: 16, isTop: true, isLeft: true),
                _buildHUDCorner(top: 16, right: 16, isTop: true, isLeft: false),
                _buildHUDCorner(bottom: 16, left: 16, isTop: false, isLeft: true),
                _buildHUDCorner(bottom: 16, right: 16, isTop: false, isLeft: false),

                // Scanner label
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SCANNING...',
                      style: GoogleFonts.shareTechMono(
                        color: const Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Beautiful spinner and text status
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          strokeWidth: 3,
        ),
        const SizedBox(height: 24),
        Text(
          _currentStatusText,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEn ? 'FertiFlow is scanning chili plant health...' : 'FertiFlow sedang memindai kesehatan tanaman cabai...',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(ThemeData theme, AppState appState, bool isEn) {
    final severity = _detectionResult['severity'] ?? 'Sedang';
    final String rawLabel = _detectionResult['label'] ?? 'Unknown';

    final bool isUnknown = rawLabel == 'Tidak Diketahui' || rawLabel == 'Unknown';
    final bool isHealthy = rawLabel == 'Sehat';

    String displayLabel = isUnknown
        ? (isEn ? 'Not a Chili Leaf / Plant' : 'Bukan Daun / Tanaman Cabai')
        : rawLabel;
    if (isEn && !isUnknown) {
      if (rawLabel.contains('Kutu Daun')) displayLabel = 'Aphids';
      if (rawLabel.contains('Thrips')) displayLabel = 'Thrips';
      if (rawLabel.contains('Tungau')) displayLabel = 'Mites';
    }

    String displaySeverity = isUnknown
        ? (isEn ? 'Invalid' : 'Tidak Dikenali')
        : severity;
    if (isEn && !isUnknown) {
      if (severity == 'Ringan') displaySeverity = 'Mild';
      if (severity == 'Sedang') displaySeverity = 'Moderate';
      if (severity == 'Berat') displaySeverity = 'Severe';
    }

    Color severityColor = isUnknown
        ? const Color(0xFF64748B)
        : (severity == 'Berat'
            ? const Color(0xFFEF4444)
            : (severity == 'Ringan' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)));

    Color resultIconColor = isUnknown
        ? const Color(0xFF94A3B8)
        : isHealthy
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);
    IconData resultIcon = isUnknown
        ? Icons.help_outline_rounded
        : isHealthy
            ? Icons.check_circle_rounded
            : Icons.warning_rounded;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success / Warning / Unknown icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: resultIconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            resultIcon,
            color: resultIconColor,
            size: 64,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isUnknown
              ? (isEn ? 'Not a Chili Leaf!' : 'Bukan Daun Cabai!')
              : (isEn ? 'Diagnosis Complete!' : 'Analisis Selesai!'),
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (isUnknown) ...[
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'The scanned image is not identified as a chili plant leaf. Please point the camera closely at a chili leaf with adequate lighting.'
                : 'Foto yang dipindai tidak teridentifikasi sebagai daun atau tanaman cabai. Pastikan mengarahkan kamera ke daun cabai dari jarak dekat dengan pencahayaan yang jelas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Beautiful result preview card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          displayLabel,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUnknown
                              ? (isEn ? 'Cannot identify chili plant leaf' : 'Objek tidak teridentifikasi sebagai tanaman cabai')
                              : (isEn 
                                  ? 'Match Accuracy: ${((_detectionResult['confidence'] as double) * 100).toStringAsFixed(0)}%'
                                  : 'Kecocokan: ${((_detectionResult['confidence'] as double) * 100).toStringAsFixed(0)}%'),
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        ),
        const SizedBox(height: 40),

        // Navigation buttons
        if (isUnknown) ...[
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
            label: Text(
              isEn ? 'Scan Again' : 'Ambil Foto Ulang',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (displayLabel != 'Sehat' && !isUnknown) ...[
          ElevatedButton(
            onPressed: () {
              // Pop the Analysis screen
              Navigator.of(context).pop();
              // Set navIndex to 2 (Tangani screen)
              appState.setNavIndex(2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              isEn ? 'View Treatment Solutions' : 'Lihat Saran Penanganan',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: () {
            // Just go back to AI scan screen
            Navigator.of(context).pop();
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.dividerColor),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            isEn ? 'Back' : 'Kembali',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (!isUnknown) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SmartConsultationScreen(
                    scanDisease: displayLabel,
                    scanSeverity: displaySeverity,
                    scanImagePath: widget.imagePath,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.psychology_rounded, color: Colors.white),
            label: Text(
              isEn ? 'Ask AI Assistant' : 'Tanya Asisten AI',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ],
    );
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
            top: isTop ? const BorderSide(color: Color(0xFF10B981), width: 2) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFF10B981), width: 2) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFF10B981), width: 2) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFF10B981), width: 2) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
