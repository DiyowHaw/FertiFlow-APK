import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class RoboflowService {
  // Model Configuration
  static const String _modelId = 'deteksi-hama-penyakit-cabai';
  static const String _version = '1';
  static const String _apiKey = 'bftyzkA5eEdz4DBawyQc';
  
  // Endpoint URL
  static const String _baseUrl = 'https://detect.roboflow.com';

  /// Menganalisis gambar menggunakan Roboflow Cloud Inference API
  static Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    try {
      const String url = '$_baseUrl/$_modelId/$_version?api_key=$_apiKey&confidence=50';

      // Read image as bytes
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Send POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: base64Image,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['predictions'] != null) {
          final predictions = data['predictions'] as List;
          
          if (predictions.isEmpty) {
            return {'label': 'Tidak Ditemukan Hama (Roboflow)', 'confidence': 0.0, 'severity': 'Unknown'};
          }
          
          // Find highest confidence prediction
          var bestPred = predictions[0];
          for (var pred in predictions) {
            if ((pred['confidence'] ?? 0.0) > (bestPred['confidence'] ?? 0.0)) {
              bestPred = pred;
            }
          }
          
          double confidence = (bestPred['confidence'] ?? 0.0).toDouble();
          String label = bestPred['class'] ?? 'Tidak Diketahui';

          // Abaikan deteksi di bawah batas keyakinan 50%
          if (confidence < 0.50) {
            return {'label': 'Tidak Ditemukan Hama (Roboflow)', 'confidence': confidence, 'severity': 'Unknown'};
          }
          
          String severity = 'Ringan';
          if (label == 'Sehat') {
            severity = 'Sehat';
          } else if (confidence > 0.8) {
            severity = 'Berat';
          } else if (confidence > 0.6) {
            severity = 'Sedang';
          }

          return {
            'label': label,
            'confidence': confidence,
            'severity': severity,
            'boxes': predictions,
          };
        }
      } else {
        debugPrint('Roboflow Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Roboflow Exception: $e');
    }
    return {'label': 'Error', 'confidence': 0.0, 'severity': 'Unknown'};
  }
}
