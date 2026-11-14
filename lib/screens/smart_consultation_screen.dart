import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/llm_service.dart';
import 'package:fertiflow/services/app_state.dart';
import 'package:fertiflow/services/zone_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:image_picker/image_picker.dart';

class SmartConsultationScreen extends StatefulWidget {
  final String? initialContext;
  final String? scanDisease;
  final String? scanSeverity;
  final String? scanImagePath;

  const SmartConsultationScreen({
    super.key,
    this.initialContext,
    this.scanDisease,
    this.scanSeverity,
    this.scanImagePath,
  });

  @override
  State<SmartConsultationScreen> createState() => _SmartConsultationScreenState();
}

class _SmartConsultationScreenState extends State<SmartConsultationScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final LLMService _llmService = LLMService.instance;
  
  File? _selectedImage;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    _llmService.initialize();
    final appState = AppState.instance;

    if (widget.scanDisease != null) {
      // Kasus 1: Dibuka setelah memindai tanaman cabai (ada data penyakit)
      final disease = widget.scanDisease!;
      final severity = widget.scanSeverity ?? 'Sedang';

      _messages.add({
        'isUser': false,
        'text': 'Halo Petani! Hasil diagnosis tanaman cabai Anda telah kami terima. '
            'Berikut solusi penanganan dan rekomendasi penyiraman yang disesuaikan dengan kondisi mesin dan cuaca:',
      });

      final autoUserMessage = 'Halo AI FertiFlow, saya baru saja memindai tanaman cabai dengan hasil diagnosa:\n'
          '🔬 Penyakit Terdeteksi: $disease ($severity)\n'
          '💧 Kelembapan Tanah Sensor: ${appState.soilMoistureDisplay}\n'
          '🌡️ Suhu Mesin/Lingkungan: ${appState.airTemperatureDisplay}\n'
          '📊 Status ESP32: ${appState.deviceStatusDisplay}\n\n'
          'Mohon analisis penyakit ini, berikan saran penanganan/obat yang tepat, serta rekomendasi penyesuaian penyiraman otomatis.';

      _messages.add({
        'isUser': true,
        'text': autoUserMessage,
      });

      _isLoading = true;
      _requestAiWateringRecommendation(
        diseaseContext: '$disease ($severity)',
        customUserMessage: null,
      );
    } else if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
      _messages.add({
        'isUser': false,
        'text': 'Halo! Saya Asisten FertiFlow. Ada yang bisa saya bantu terkait kebun cabai Anda?',
      });

      final autoMessage = widget.initialContext!;
      _messages.add({
        'isUser': true,
        'text': autoMessage,
      });
      _isLoading = true;

      _llmService.sendMessage(autoMessage).then((response) {
        if (mounted) {
          final cleanResponse = response.replaceAll(RegExp(r'```(?:json)?\s*\{[\s\S]*?\}\s*```'), '').trim();
          setState(() {
            _messages.add({'isUser': false, 'text': cleanResponse});
            _isLoading = false;
          });
        }
      });
    } else {
      // Kasus 2: Dibuka langsung tanpa scan (menggunakan data mesin aktual)
      _messages.add({
        'isUser': false,
        'text': 'Halo Petani! Saya Asisten FertiFlow. '
            'Sistem saat ini terhubung dengan sensor mesin (${appState.deviceStatusDisplay}). '
            'Ada yang ingin dikonsultasikan terkait kondisi kebun cabai atau rekomendasi penyiraman hari ini?',
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 70);
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      
      setState(() {
        _selectedImage = file;
        _base64Image = base64Str;
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Sumber Gambar',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(Icons.camera_alt_rounded, 'Kamera', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _buildSourceButton(Icons.photo_library_rounded, 'Galeri', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 32),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty && _selectedImage == null) return;
    
    final currentText = text.trim();
    final currentImage = _selectedImage;
    final currentBase64 = _base64Image;
    
    setState(() {
      _messages.add({
        'isUser': true, 
        'text': currentText,
        'imageFile': currentImage,
      });
      _isLoading = true;
      _selectedImage = null;
      _base64Image = null;
    });
    
    _textController.clear();
    
    // Call LLM
    final response = await _llmService.sendMessage(currentText, base64Image: currentBase64);
    
    if (mounted) {
      setState(() {
        _messages.add({'isUser': false, 'text': response});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanya Asisten AI',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Asisten FertiFlow - Online',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildChatBubble(message, theme);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            ),
          _buildQuickSuggestions(theme),
          if (_selectedImage != null) _buildImagePreview(theme),
          _buildMessageInput(theme),
        ],
      ),
    );
  }
  
  Widget _buildImagePreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.cardColor,
      alignment: Alignment.centerLeft,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selectedImage!, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => setState(() {
                _selectedImage = null;
                _base64Image = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message, ThemeData theme) {
    final bool isUser = message['isUser'];
    final File? imageFile = message['imageFile'];
    final String text = message['text'] ?? '';
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF10B981) : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isUser ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(imageFile),
              ),
              if (text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (text.isNotEmpty) _buildMessageContent(text, isUser, theme),
            if (message['recommendation'] != null) ...[
              const SizedBox(height: 8),
              _buildRecommendationCard(Map<String, dynamic>.from(message['recommendation']), theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(String text, bool isUser, ThemeData theme) {
    // Bersihkan blok kode JSON agar bubble chat di UI rapi dan tidak menampilkan raw code
    text = text.replaceAll(RegExp(r'```(?:json)?\s*\{[\s\S]*?\}\s*```'), '').trim();

    // Parser untuk mendeteksi Markdown Image ![alt](url)
    final imageRegExp = RegExp(r'!\[(.*?)\]\((.*?)\)');
    final matches = imageRegExp.allMatches(text);
    
    if (matches.isNotEmpty) {
      List<Widget> spans = [];
      int lastMatchEnd = 0;
      
      for (final match in matches) {
        if (match.start > lastMatchEnd) {
          spans.add(_buildTextLinkify(text.substring(lastMatchEnd, match.start), isUser, theme));
        }
        final altText = match.group(1)!;
        final imageUrl = match.group(2)!;
        spans.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                errorBuilder: (context, error, stackTrace) => InkWell(
                  onTap: () async {
                    final uri = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(altText)}&tbm=isch');
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint('Could not launch $uri');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image_search_rounded, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Cari Gambar: $altText',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        );
        lastMatchEnd = match.end;
      }
      
      if (lastMatchEnd < text.length) {
        spans.add(_buildTextLinkify(text.substring(lastMatchEnd), isUser, theme));
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: spans,
      );
    }

    return _buildTextLinkify(text, isUser, theme);
  }
  
  Widget _buildTextLinkify(String text, bool isUser, ThemeData theme) {
    final cleanText = text.replaceAll('*', '').replaceAll('#', '');
    return SelectableLinkify(
      onOpen: (link) async {
        final uri = Uri.parse(link.url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Could not launch ${link.url}');
        }
      },
      text: cleanText.trim(),
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isUser ? Colors.white : theme.colorScheme.onSurface,
        height: 1.5,
      ),
      linkStyle: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    );
  }

  Future<void> _requestAiWateringRecommendation({
    String? diseaseContext,
    String? customUserMessage,
  }) async {
    final appState = AppState.instance;
    final activeZone = ZoneService.instance.activeZone;
    final bool hasZone = activeZone != null;

    final String targetName = hasZone ? activeZone.name : 'Kebun Cabai';
    final String plantType = hasZone ? activeZone.plantType : 'Tanaman Cabai';
    final int plantCount = hasZone ? activeZone.plantCount : 100;

    await appState.fetchWeatherIfNeeded();
    final weather = appState.weatherCache;

    if (customUserMessage != null) {
      setState(() {
        _messages.add({
          'isUser': true,
          'text': customUserMessage,
        });
        _isLoading = true;
      });
    } else if (diseaseContext == null) {
      setState(() {
        _messages.add({
          'isUser': true,
          'text': hasZone
              ? 'Minta Rekomendasi Penyiraman AI untuk ${activeZone.name} (${activeZone.plantType}) berdasarkan cuaca dan data sensor mesin.'
              : 'Minta Rekomendasi Penyiraman AI untuk Kebun Cabai berdasarkan data sensor mesin dan cuaca terkini.',
        });
        _isLoading = true;
      });
    }

    final recData = await _llmService.requestWateringRecommendation(
      zoneName: targetName,
      plantType: plantType,
      plantCount: plantCount,
      plantHealth: diseaseContext ?? activeZone?.lastDiagnosis,
      hasSpecificZone: hasZone,
      weatherTemp: weather?.temperature,
      weatherHumidity: weather?.humidity,
      weatherCondition: weather?.isRaining == true ? 'Hujan' : (weather?.isCloudy == true ? 'Berawan' : 'Cerah'),
      isRaining: weather?.isRaining ?? false,
      soilMoisture: appState.hasValidSensorData ? appState.soilMoisture : null,
      isSensorOnline: appState.isDeviceOnline,
    );

    if (mounted) {
      setState(() {
        _messages.add({
          'isUser': false,
          'text': recData['displayText'] ?? 'Berikut rekomendasi penyiraman otomatis untuk tanaman cabai Anda:',
          'recommendation': recData,
        });
        _isLoading = false;
      });
    }
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec, ThemeData theme) {
    final appState = AppState.instance;
    final recId = rec['recommendation_id']?.toString() ?? '';
    final bool isAlreadyAdded = appState.treatments.any((t) => (t['recommendation_id'] ?? t['id'])?.toString() == recId);

    final List<dynamic> daysList = rec['days'] is List ? (rec['days'] as List) : ['Sen', 'Rab', 'Jum'];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rencana Rekomendasi AI',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRecRow(Icons.grid_view_rounded, 'Target', '${rec['zone_id']} (${rec['plant_type']})', theme),
          _buildRecRow(Icons.access_time_rounded, 'Waktu', '${rec['watering_times']} WIB', theme),
          _buildRecRow(Icons.calendar_today_rounded, 'Hari', daysList.join(', '), theme),
          _buildRecRow(Icons.timer_outlined, 'Durasi & Volume', '${rec['duration_seconds']}s • ${rec['volume']}', theme),
          if (rec['limitations'] != null && rec['limitations'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan: ${rec['limitations']}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: isAlreadyAdded
                  ? null
                  : () {
                      final success = appState.addTreatment({
                        'id': rec['recommendation_id'],
                        'recommendation_id': rec['recommendation_id'],
                        'type': 'irrigation_recommendation',
                        'plantId': rec['zone_id'],
                        'plantName': rec['plant_type'],
                        'pestName': 'Rekomendasi Penyiraman Presisi',
                        'severity': 'Ringan',
                        'status': 'pending',
                        'watering_times': rec['watering_times'],
                        'days': rec['days'],
                        'duration_seconds': rec['duration_seconds'],
                        'volume': rec['volume'],
                        'frequency': rec['frequency'],
                        'recommendation': rec['reason'],
                        'steps': [
                          'Waktu penyiraman: ${rec['watering_times']} WIB',
                          'Jadwal hari: ${daysList.join(', ')}',
                          'Durasi pompa: ${rec['duration_seconds']} detik (${rec['volume']})',
                          'Pastikan ketersediaan air tandon sebelum eksekusi',
                        ],
                        'limitations': rec['limitations'],
                        'added_to_schedule': false,
                        'createdAt': DateTime.now().toIso8601String(),
                      });

                      if (success) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 85, left: 16, right: 16),
                            duration: const Duration(seconds: 3),
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Rekomendasi berhasil ditambahkan ke Panduan Penanganan!',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
              icon: Icon(
                isAlreadyAdded ? Icons.check_circle_rounded : Icons.assignment_turned_in_rounded,
                size: 16,
                color: isAlreadyAdded ? const Color(0xFF10B981) : Colors.white,
              ),
              label: Text(
                isAlreadyAdded
                    ? '✓ Tersimpan di Panduan Penanganan'
                    : 'Tambahkan ke Panduan Penanganan',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isAlreadyAdded ? const Color(0xFF10B981) : Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAlreadyAdded
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFF10B981),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(ThemeData theme) {
    if (_messages.length > 2) return const SizedBox(); 

    final suggestions = [
      'Rekomendasi Penyiraman AI',
      'Analisis Data Kebun Cabai Saat Ini',
      'Bagaimana cara membasmi hama Kutu Daun?',
      'Kapan waktu terbaik menyiram cabai?',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                suggestions[index],
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF10B981)),
              ),
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
              side: const BorderSide(color: Color(0xFF10B981)),
              onPressed: () {
                if (suggestions[index] == 'Rekomendasi Penyiraman AI') {
                  _requestAiWateringRecommendation();
                } else if (suggestions[index] == 'Analisis Data Kebun Cabai Saat Ini') {
                  final appState = AppState.instance;
                  final contextData = 'Halo AI, tolong analisis data real-time kebun saya saat ini:\n'
                      'Kelembapan Tanah ${appState.soilMoistureDisplay},\n'
                      'Suhu Udara ${appState.airTemperatureDisplay},\n'
                      'Kelembapan Udara ${appState.airHumidityDisplay},\n'
                      'Level Air Tandon ${appState.waterTankLevelDisplay}.\n'
                      'Berdasarkan data ini, apakah kebun saya aman atau perlu penanganan?';
                  _sendMessage(contextData);
                } else {
                  _sendMessage(suggestions[index]);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            onPressed: _showImageSourceOptions,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Tanya masalah tanaman...',
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
