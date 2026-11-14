import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'firebase_service.dart';

class DataRepository {
  final DatabaseService _localDb = DatabaseService.instance;
  final FirebaseService _cloudDb = FirebaseService();

  // Fungsi untuk menyimpan diagnosa ke Lokal sekaligus ke Cloud
  Future<void> saveDiagnosis(Map<String, dynamic> diagnosis) async {
    try {
      // 1. Simpan ke Lokal (sqflite) agar aplikasi cepat
      await _localDb.insertDiagnosis(diagnosis);
      
      // 2. Kirim ke Cloud (Firebase) agar bisa diakses perangkat lain
      await _cloudDb.syncDiagnosisToCloud(diagnosis);
      
      debugPrint("Data berhasil disimpan lokal dan disinkronkan ke cloud!");
    } catch (e) {
      debugPrint("Terjadi kesalahan saat menyimpan data: $e");
    }
  }

  // Fungsi untuk mengambil data (bisa dari lokal dulu, lalu sync)
  Future<List<Map<String, dynamic>>> getDiagnoses() async {
    return await _localDb.getAllDiagnoses();
  }
}