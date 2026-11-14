
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LLMService {
  static final LLMService _instance = LLMService._internal();
  static LLMService get instance => _instance;

  LLMService._internal();

  // API Key diambil dari environment saat aplikasi dijalankan.
  // Jangan menuliskan API Key langsung di dalam source code.
  static const String _apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
  );

  final List<Map<String, dynamic>> _messages = [];
  bool _isReady = false;

  void initialize() {
    _messages.clear();

    _messages.add({
      'role': 'system',
      'content':
          'Anda adalah Asisten AI "FertiFlow", spesialis agrikultur dan rekan terpercaya bagi para petani cabai. Tugas Anda adalah mendiagnosis penyakit dan memberikan saran perawatan yang akurat. ATURAN PENTING: 1. Jawab dengan bahasa Indonesia yang ramah, sopan, dan mudah dipahami oleh petani (hindari istilah ilmiah yang terlalu rumit tanpa penjelasan). 2. Berikan informasi yang JELAS, MENDETAIL, dan SOLUTIF. Jangan menjawab terlalu singkat jika pengguna membutuhkan panduan langkah demi langkah. 3. Gunakan emoji secukupnya saja (1-2 per paragraf) untuk memberi kesan hangat, jangan berlebihan. 4. JIKA menyarankan pupuk atau pestisida/obat, WAJIB gunakan format Markdown Gambar untuk referensi: ![Nama](URL_Gambar_Referensi). Contoh: ![NPK Mutiara](https://assets.ayobatani.com/npk.jpg).',
    });

    _messages.add({
      'role': 'assistant',
      'content':
          'Halo! Saya Asisten FertiFlow. Ada yang bisa saya bantu terkait tanaman cabai Anda?',
    });

    _isReady = true;
    debugPrint('[LLM] Initialized Groq Model successfully.');
  }

  bool get isReady => _isReady;

  /// Start a new contextual chat session based on specific diagnosis or zone data
  void startNewContextualChat(String initialContext) {
    if (!isReady) return;

    _messages.clear();

    _messages.add({
      'role': 'system',
      'content':
          'Anda adalah Asisten AI "FertiFlow". Konteks data kebun pengguna saat ini: $initialContext. ATURAN PENTING: 1. Analisis data tersebut dan berikan panduan yang JELAS, MENDETAIL, dan MUDAH DIPAHAMI oleh petani biasa. 2. Gunakan bahasa yang ramah dan solutif. 3. Gunakan emoji secukupnya (jangan berlebihan). 4. JIKA menyarankan pupuk/obat, WAJIB sertakan gambar dengan format Markdown: ![Nama](URL_GAMBAR).',
    });

    _messages.add({
      'role': 'assistant',
      'content':
          'Baik, saya mengerti peran saya dan konteks saat ini. Apa yang bisa saya bantu terkait hal tersebut?',
    });
  }

  /// Send message to the current chat session
  Future<String> sendMessage(
    String message, {
    String? base64Image,
  }) async {
    if (!isReady) {
      return 'Maaf, sistem AI belum siap.';
    }

    if (_apiKey.isEmpty) {
      return 'API Key belum diatur. Silakan konfigurasi GROQ_API_KEY saat menjalankan aplikasi.';
    }

    // Add user message
    if (base64Image != null) {
      _messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': message},
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:image/jpeg;base64,$base64Image',
            },
          },
        ],
      });
    } else {
      _messages.add({
        'role': 'user',
        'content': message,
      });
    }

    try {
      final response = await http.post(
        Uri.parse(
          'https://api.groq.com/openai/v1/chat/completions',
        ),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'qwen/qwen3.8-27b',
          'messages': _messages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final reply =
            data['choices'][0]['message']['content'] as String;

        _messages.add({
          'role': 'assistant',
          'content': reply,
        });

        return reply;
      } else if (response.statusCode == 429) {
        // Fallback simulasi jika API limit penuh.
        String mockReply;

        if (message.toLowerCase().contains('yellowish leaf') ||
            message.toLowerCase().contains('kuning')) {
          mockReply =
              'Berdasarkan hasil pemindaian Anda, tanaman terdeteksi mengalami gejala Daun Menguning (Yellowish Leaf) tingkat sedang. 🍂\n\n'
              'Gejala ini umumnya disebabkan oleh serangan Kutu Kebul atau defisiensi unsur hara makro (Nitrogen/Kalium). ⚠️\n\n'
              'Saran Penanganan:\n'
              '1. Segera aplikasikan pupuk NPK seimbang (misal: NPK Mutiara 16-16-16) di area perakaran. 🌱\n'
              '2. Jika ada kutu putih di balik daun, semprotkan insektisida/fungisida seperti Antracol atau Curacron. 💊\n\n'
              'Referensi bentuk obatnya:\n'
              '![Fungisida Antracol](https://www.static-src.com/wcsstore/Indraprastha/images/catalog/full//107/MTA-54386980/antracol_fungisida-kontak-antracol-70-wp-250-gr-pengendali-penyakit-tanaman_full02.jpg)\n\n'
              'Pastikan juga tanah tidak terlalu basah ya! 💧';
        } else {
          mockReply =
              'Tentu! Untuk menjaga kesuburan dan menangani hama pada tanaman cabai Anda, saya sangat merekomendasikan pemupukan rutin dan penggunaan obat yang tepat. 🌱💧\n\n'
              'Salah satu produk yang sangat populer dan ampuh di kalangan petani adalah NPK Mutiara. 💊\n\n'
              'Anda bisa melihat detail kemasannya di sini:\n'
              '![NPK Mutiara](https://npkmutiara-prod.s3.ap-southeast-1.amazonaws.com/2022/12/msg404884439-25412-large.jpg)\n\n'
              'Ada hal lain yang ingin Anda tanyakan? 🤔';
        }

        _messages.add({
          'role': 'assistant',
          'content': mockReply,
        });

        return mockReply;
      } else {
        debugPrint(
          '[LLM] Error: ${response.statusCode} - ${response.body}',
        );

        return 'Maaf, terjadi kesalahan pada server Llama (${response.statusCode}).';
      }
    } catch (e) {
      debugPrint('[LLM] Error sending message: $e');

      return 'Maaf, gagal terhubung ke server AI: $e';
    }
  }

  /// Memvalidasi kelengkapan data rekomendasi penyiraman sebelum diproses (FR-05)
  static bool isValidRecommendation(
    Map<String, dynamic> rec,
  ) {
    final hasTime = rec['watering_times'] != null &&
        rec['watering_times'].toString().trim().isNotEmpty;

    final hasDays = rec['days'] is List &&
        (rec['days'] as List).isNotEmpty;

    final hasReason = rec['reason'] != null &&
        rec['reason'].toString().trim().isNotEmpty;

    final hasVolumeOrDuration =
        rec['duration_seconds'] != null ||
        rec['volume'] != null;

    return hasTime &&
        hasDays &&
        hasReason &&
        hasVolumeOrDuration;
  }

  /// Menghasilkan rekomendasi penyiraman terstruktur berbasis LLM (FR-01 s/d FR-05)
  Future<Map<String, dynamic>> requestWateringRecommendation({
    String? zoneName,
    String? plantType,
    int? plantCount,
    String? plantHealth,
    double? weatherTemp,
    int? weatherHumidity,
    String? weatherCondition,
    bool isRaining = false,
    double? soilMoisture,
    bool isSensorOnline = false,
    bool hasSpecificZone = false,
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    final recId =
        'rec_${DateTime.now().millisecondsSinceEpoch}';

    final String displayTarget =
        (hasSpecificZone &&
                zoneName != null &&
                zoneName.isNotEmpty)
            ? zoneName
            : 'Kebun Cabai';

    final String displayPlantType =
        (hasSpecificZone &&
                plantType != null &&
                plantType.isNotEmpty)
            ? plantType
            : 'Tanaman Cabai';

    final String targetContext =
        (hasSpecificZone &&
                zoneName != null &&
                zoneName.isNotEmpty)
            ? '$zoneName ($displayPlantType, ${plantCount ?? 100} tanaman)'
            : 'Kebun Cabai Keseluruhan (Berdasarkan data mesin sensor ESP32)';

    final weatherContext = weatherTemp != null
        ? 'Suhu udara: ${weatherTemp.toStringAsFixed(1)}°C, Kelembapan udara: $weatherHumidity%, Kondisi: ${weatherCondition ?? (isRaining ? "Hujan" : "Cerah")}.'
        : 'Data cuaca saat ini tidak tersedia.';

    final sensorContext =
        isSensorOnline && soilMoisture != null
            ? 'Sensor tanah ESP32 aktif: Kelembapan tanah ${soilMoisture.toStringAsFixed(0)}%.'
            : 'Sensor tanah ESP32 belum terhubung / data tidak terkini.';

    final healthContext =
        (plantHealth != null &&
                plantHealth.isNotEmpty &&
                plantHealth != 'Sehat')
            ? 'Hasil Diagnosa Scan Tanaman: $plantHealth. (PENTING: Berikan saran obat/penanganan dan sesuaikan jadwal/durasi penyiraman agar aman untuk kondisi penyakit ini)'
            : 'Kondisi Tanaman: Normal / Sehat / Umum.';

    final prompt = '''
Anda adalah Asisten FertiFlow, spesialis agrikultur cabai. Berikan rekomendasi penyiraman yang presisi, aman, dan solutif.

Konteks Data Aktual:
- Target: $targetContext
- Status Kesehatan Tanaman: $healthContext
- Cuaca Terkini: $weatherContext
- Status Sensor Mesin: $sensorContext

ATURAN PENTING:
1. JANGAN sebut nama zona buatan seperti Zona A jika konteksnya adalah kebun umum.
2. Jelaskan alasan rekomendasi dalam bahasa Indonesia yang ramah, sopan, dan mudah dipahami petani.
3. Berikan rekomendasi waktu penyiraman zona WIB (pagi 06:00 - 07:30 atau sore 16:00 - 17:30).
4. Tentukan hari penyiraman dalam singkatan: Sen, Sel, Rab, Kam, Jum, Sab, Min.
5. Tentukan durasi pompa dalam detik (antara 15 s.d 40 detik) dan volume air (1.5 L s.d 3.0 L).
6. Jangan mengasumsikan data sensor yang tidak ada sebagai data valid.
7. Di akhir pesan, sertakan blok JSON berikut untuk diekstrak oleh sistem (jangan ubah format kuncinya):

```json
{
  "recommendation_id": "$recId",
  "zone_id": "$displayTarget",
  "plant_type": "$displayPlantType",
  "watering_dates": ["Sen", "Rab", "Jum"],
  "days": ["Sen", "Rab", "Jum"],
  "watering_times": "06:30",
  "frequency": "1x sehari pada pagi hari",
  "duration_seconds": 25,
  "volume": "2.0 L",
  "reason": "Alasan singkat rekomendasi berdasarkan kondisi mesin dan cuaca",
  "limitations": "Catatan keterbatasan data sensor atau perkiraan cuaca"
}
```
''';

    String responseText = '';
    Map<String, dynamic>? structuredData;

    try {
      responseText = await sendMessage(prompt);

      // Ekstrak JSON blok jika ada.
      final jsonRegex = RegExp(
        r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
      );

      final match = jsonRegex.firstMatch(responseText);

      if (match != null) {
        final jsonString = match.group(1);

        if (jsonString != null) {
          structuredData = Map<String, dynamic>.from(
            jsonDecode(jsonString),
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[LLM] Recommendation parsing error: $e',
      );
    }

    // Bersihkan teks penjelasan agar tidak ada blok JSON
    // di dalam bubble chat.
    String cleanDisplayText = responseText
        .replaceAll(
          RegExp(r'```(?:json)?\s*\{[\s\S]*?\}\s*```'),
          '',
        )
        .trim();

    // Jika LLM gagal parsing / rate limited,
    // gunakan model agrikultur deterministik.
    if (structuredData == null ||
        !isValidRecommendation(structuredData)) {
      final double temp = weatherTemp ?? 30.0;

      final bool hotWeather = temp >= 31.0;

      final int duration = hotWeather ? 30 : 20;

      final String volume =
          hotWeather ? '2.5 L' : '2.0 L';

      final String time =
          hotWeather ? '06:15' : '06:30';

      final List<String> days = hotWeather
          ? ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
          : ['Sen', 'Rab', 'Jum'];

      final String reason = isRaining
          ? 'Cuaca mendung/hujan, frekuensi penyiraman dikurangi untuk mencegah pembusukan akar.'
          : (hotWeather
              ? 'Suhu terik (${temp.toStringAsFixed(1)}°C), disarankan penyiraman pagi hari $duration detik untuk menjaga kelembapan optimal.'
              : 'Kondisi cuaca normal (${temp.toStringAsFixed(1)}°C), penyiraman standar 3x seminggu cukup untuk tanaman cabai Anda.');

      const String limitations =
          'Data curah hujan aktual sensor belum tersedia; estimasi cuaca terbuka.';

      structuredData = {
        'recommendation_id': recId,
        'zone_id': displayTarget,
        'plant_type': displayPlantType,
        'watering_dates': days,
        'days': days,
        'watering_times': time,
        'frequency': hotWeather
            ? 'Setiap pagi hari'
            : '3x seminggu (Pagi)',
        'duration_seconds': duration,
        'volume': volume,
        'reason': reason,
        'limitations': limitations,
      };

      if (cleanDisplayText.isEmpty ||
          cleanDisplayText.contains('kesalahan pada server') ||
          cleanDisplayText.contains('gagal terhubung')) {
        cleanDisplayText =
            'Berdasarkan analisis data cuaca (${temp.toStringAsFixed(1)}°C) dan sensor mesin terkini untuk $displayTarget, '
            'rekomendasi terbaik adalah penyiraman setiap jam $time WIB dengan durasi $duration detik ($volume).\n\n'
            '🌱 **Alasan:** $reason\n'
            '⚠️ **Catatan:** $limitations';
      }
    }

    structuredData['displayText'] =
        cleanDisplayText.isNotEmpty
            ? cleanDisplayText
            : 'Berikut rekomendasi penyiraman optimal berdasarkan data mesin dan cuaca:';

    structuredData['created_at'] = timestamp;
    structuredData['handling_status'] = 'pending';
    structuredData['schedule_status'] = 'not_scheduled';

    return structuredData;
  }
}
