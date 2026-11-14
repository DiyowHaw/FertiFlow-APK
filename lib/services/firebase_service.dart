import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mengirim data diagnosa ke Cloud
  Future<void> syncDiagnosisToCloud(Map<String, dynamic> diagnosis) async {
    try {
      await _db.collection('diagnosis_history').doc(diagnosis['id']).set(diagnosis);
    } catch (e) {
      debugPrint("Gagal sync ke Firebase: $e");
    }
  }
}