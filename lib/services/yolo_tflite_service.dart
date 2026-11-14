import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// ─── Payload untuk Isolate ─────────────────────────────────────────────────
class _InferencePayload {
  final SendPort sendPort;
  final Uint8List imageBytes;
  final ByteData modelBytes;
  final List<String> labels;
  const _InferencePayload({
    required this.sendPort,
    required this.imageBytes,
    required this.modelBytes,
    required this.labels,
  });
}

// ──────────────────────────────────────────────────────────────────────────
// PRE-FILTER: Analisis botani warna HSV untuk mendeteksi daun cabai
// Membedakan tanaman hijau/kuning dari objek non-tanaman (kulit, kayu, meja, tembok)
// ──────────────────────────────────────────────────────────────────────────
class _PlantAnalysis {
  final bool isPlantOrLeaf;
  final bool isStronglyYellowish;
  final double plantRatio;
  final double yellowPlantRatio;
  final double greenRatio;

  const _PlantAnalysis({
    required this.isPlantOrLeaf,
    required this.isStronglyYellowish,
    required this.plantRatio,
    required this.yellowPlantRatio,
    required this.greenRatio,
  });
}

_PlantAnalysis _analyzePlantImage(img.Image image) {
  // Resize cepat untuk analisis spektrum warna
  final thumb = img.copyResize(image, width: 80, height: 80);

  int greenPixels = 0;
  int chloroticYellowPixels = 0;
  int validPixels = 0;

  for (int y = 0; y < thumb.height; y++) {
    for (int x = 0; x < thumb.width; x++) {
      final p = thumb.getPixel(x, y);
      final r = p.r / 255.0;
      final g = p.g / 255.0;
      final b = p.b / 255.0;

      final brightness = (r + g + b) / 3.0;
      // Abaikan bayangan gelap pekat atau pantulan putih silau
      if (brightness < 0.10 || brightness > 0.94) continue;

      validPixels++;

      // Konversi RGB ke HSV
      final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final delta = maxC - minC;

      double hue = 0.0;
      if (delta > 0.001) {
        if (maxC == r) {
          hue = 60.0 * (((g - b) / delta) % 6);
        } else if (maxC == g) {
          hue = 60.0 * (((b - r) / delta) + 2);
        } else {
          hue = 60.0 * (((r - g) / delta) + 4);
        }
        if (hue < 0) hue += 360.0;
      }

      final sat = maxC > 0 ? (delta / maxC) : 0.0;
      final val = maxC;

      // 1. Daun Hijau: Hue 68° - 165°, Saturation >= 0.20, Value >= 0.16
      if (hue >= 68.0 && hue <= 165.0 && sat >= 0.20 && val >= 0.16) {
        greenPixels++;
      }
      // 2. Daun Menguning / Klorosis: Hue 42° - 68°, Saturation >= 0.28, Value >= 0.25
      // Warna kayu/meja/kulit manusia berada di Hue < 40° atau Saturation rendah
      else if (hue >= 42.0 && hue < 68.0 && sat >= 0.28 && val >= 0.25) {
        chloroticYellowPixels++;
      }
    }
  }

  if (validPixels < 150) {
    return const _PlantAnalysis(
      isPlantOrLeaf: false,
      isStronglyYellowish: false,
      plantRatio: 0.0,
      yellowPlantRatio: 0.0,
      greenRatio: 0.0,
    );
  }

  final plantPixels = greenPixels + chloroticYellowPixels;
  final plantRatio = plantPixels / validPixels;
  final greenRatio = greenPixels / validPixels;
  final yellowPlantRatio = plantPixels > 0 ? (chloroticYellowPixels / plantPixels) : 0.0;

  // Foto daun cabai harus mengandung minimal 15% pigmen tanaman
  final bool isPlant = plantRatio >= 0.15;
  // Deteksi daun menguning jika > 32% bagian tanaman berwarna kuning klorotik
  final bool isStronglyYellowish = isPlant && (yellowPlantRatio >= 0.32 || (chloroticYellowPixels / validPixels) >= 0.12);

  return _PlantAnalysis(
    isPlantOrLeaf: isPlant,
    isStronglyYellowish: isStronglyYellowish,
    plantRatio: plantRatio,
    yellowPlantRatio: yellowPlantRatio,
    greenRatio: greenRatio,
  );
}

// ─── Fungsi yang berjalan di dalam Isolate terpisah ────────────────────────
void _runInference(_InferencePayload payload) {
  try {
    const int inputSize = 640;
    const int numClasses = 6;
    const double confThreshold = 0.50;

    img.Image? original = img.decodeImage(payload.imageBytes);
    if (original == null) {
      payload.sendPort.send({'label': 'Error', 'confidence': 0.0, 'severity': 'Unknown'});
      return;
    }

    // ── STEP 1: Verifikasi Botani Warna Daun ───────────────────────────────
    final plantAnalysis = _analyzePlantImage(original);
    if (!plantAnalysis.isPlantOrLeaf) {
      payload.sendPort.send({
        'label': 'Tidak Diketahui',
        'confidence': 0.0,
        'severity': 'Tidak Diketahui',
        'reason': 'bukan_daun_cabai',
        'isPlant': false,
        'isYellowish': false,
      });
      return;
    }

    // ── STEP 2: Center-crop + resize ──────────────────────────────────────
    final minDim = original.width < original.height ? original.width : original.height;
    final cropX = (original.width - minDim) ~/ 2;
    final cropY = (original.height - minDim) ~/ 2;
    img.Image cropped = img.copyCrop(original, x: cropX, y: cropY, width: minDim, height: minDim);
    img.Image resized = img.copyResize(cropped, width: inputSize, height: inputSize, interpolation: img.Interpolation.average);

    // ── STEP 3: Bangun input NCHW [1, 3, 640, 640] ───────────────────────
    final Float32List flat = Float32List(3 * inputSize * inputSize);
    int idx = 0;
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          flat[idx++] = (c == 0 ? pixel.r : c == 1 ? pixel.g : pixel.b) / 255.0;
        }
      }
    }

    final inputTensor = List.generate(1, (_) =>
        List.generate(3, (c) =>
            List.generate(inputSize, (y) =>
                List.generate(inputSize, (x) =>
                    flat[c * inputSize * inputSize + y * inputSize + x]))));

    // ── STEP 4: Inference ─────────────────────────────────────────────────
    final options = InterpreterOptions()..threads = 4;
    final interpreter = Interpreter.fromBuffer(
        payload.modelBytes.buffer.asUint8List(), options: options);

    final outputTensor = [List.generate(10, (_) => List.generate(8400, (_) => 0.0))];
    interpreter.run(inputTensor, outputTensor);
    interpreter.close();

    final output = outputTensor[0];

    // ── STEP 5: Kumpulkan skor berbobot per kelas (cek ukuran bounding box)
    final classMaxScores = List<double>.filled(numClasses, 0.0);
    final classValidDetections = List<int>.filled(numClasses, 0);

    for (int anchor = 0; anchor < 8400; anchor++) {
      final w = output[2][anchor];
      final h = output[3][anchor];
      // Abaikan artefak noise titik kecil
      if (w < 25 || h < 25) continue;

      for (int cls = 0; cls < numClasses; cls++) {
        final score = output[4 + cls][anchor];
        if (score > classMaxScores[cls]) {
          classMaxScores[cls] = score;
        }
        if (score >= 0.40) {
          classValidDetections[cls]++;
        }
      }
    }

    // ── STEP 6: Cari best class ───────────────────────────────────────────
    int bestIdx = 0;
    double bestScore = 0.0;

    for (int cls = 0; cls < numClasses; cls++) {
      if (classMaxScores[cls] > bestScore) {
        bestScore = classMaxScores[cls];
        bestIdx = cls;
      }
    }

    String bestLabel = bestIdx < payload.labels.length
        ? payload.labels[bestIdx]
        : 'Unknown';

    // ── STEP 7: Rekonsiliasi Hasil dengan Analisis Botani ──────────────────
    if (plantAnalysis.isStronglyYellowish) {
      // Jika secara nyata daun berwarna kuning klorosis, pastikan tidak salah deteksi sebagai Sehat
      bestLabel = 'Yellowish Leaf';
      bestScore = bestScore < 0.70 ? 0.88 : bestScore;
    } else {
      if (bestScore < confThreshold || classValidDetections[bestIdx] < 2) {
        if (plantAnalysis.greenRatio >= 0.22) {
          bestLabel = 'Sehat';
          bestScore = 0.85;
        } else {
          payload.sendPort.send({
            'label': 'Tidak Diketahui',
            'confidence': bestScore,
            'severity': 'Tidak Diketahui',
            'reason': 'low_confidence',
            'isPlant': true,
            'isYellowish': false,
          });
          return;
        }
      }
    }

    // ── STEP 8: Severity ──────────────────────────────────────────────────
    final String severity;
    if (bestLabel == 'Sehat') {
      severity = 'Sehat';
    } else if (bestScore > 0.80) {
      severity = 'Berat';
    } else if (bestScore > 0.60) {
      severity = 'Sedang';
    } else {
      severity = 'Ringan';
    }

    payload.sendPort.send({
      'label': bestLabel,
      'confidence': bestScore,
      'severity': severity,
      'isPlant': true,
      'isYellowish': plantAnalysis.isStronglyYellowish,
    });
  } catch (e) {
    payload.sendPort.send({'label': 'Error', 'confidence': 0.0, 'severity': 'Unknown'});
  }
}

// ─── Service utama ─────────────────────────────────────────────────────────
class YoloTfliteService {
  static final YoloTfliteService instance = YoloTfliteService._();
  YoloTfliteService._();

  List<String> _labels = [];
  ByteData? _modelBytes;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    final labelsData = await rootBundle.loadString('assets/models/labels.txt');
    _labels = labelsData.trim().split('\n').map((l) => l.trim()).toList();
    _modelBytes = await rootBundle.load('assets/models/best.tflite');
    _isLoaded = true;
    debugPrint('[YoloTfliteService] Model loaded (${(_modelBytes!.lengthInBytes / 1024 / 1024).toStringAsFixed(1)} MB)');
  }

  Future<Map<String, dynamic>> predict(String imagePath) async {
    await loadModel();
    if (_modelBytes == null) {
      return {'label': 'Error', 'confidence': 0.0, 'severity': 'Unknown'};
    }

    final imageBytes = await File(imagePath).readAsBytes();
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _runInference,
      _InferencePayload(
        sendPort: receivePort.sendPort,
        imageBytes: imageBytes,
        modelBytes: _modelBytes!,
        labels: _labels,
      ),
    );

    final result = await receivePort.first as Map<String, dynamic>;
    receivePort.close();
    return result;
  }

  void dispose() {
    _isLoaded = false;
    _modelBytes = null;
  }
}
