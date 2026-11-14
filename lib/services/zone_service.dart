import 'package:flutter/foundation.dart';

class PlantZone {
  final String id;
  final String name;
  final String plantType;
  final int plantCount;
  String? lastDiagnosis;
  String? lastDiagnosisSeverity;
  DateTime? lastDiagnosisDate;

  PlantZone({
    required this.id,
    required this.name,
    required this.plantType,
    required this.plantCount,
    this.lastDiagnosis,
    this.lastDiagnosisSeverity,
    this.lastDiagnosisDate,
  });
}

class ZoneService extends ChangeNotifier {
  static final ZoneService _instance = ZoneService._internal();
  static ZoneService get instance => _instance;

  ZoneService._internal() {
    _initializeZones();
  }

  final List<PlantZone> _zones = [];
  PlantZone? _activeZone;

  List<PlantZone> get zones => _zones;
  PlantZone? get activeZone => _activeZone;

  void _initializeZones() {
    _zones.addAll([
      PlantZone(
        id: 'zone_a',
        name: 'Zona A',
        plantType: 'Cabai Rawit',
        plantCount: 120,
      ),
      PlantZone(
        id: 'zone_b',
        name: 'Zona B',
        plantType: 'Cabai Merah',
        plantCount: 95,
      ),
    ]);
  }

  void setActiveZone(String? zoneId) {
    if (zoneId == null) {
      _activeZone = null;
    } else {
      _activeZone = _zones.firstWhere((z) => z.id == zoneId, orElse: () => _zones.first);
    }
    notifyListeners();
  }

  void updateZoneDiagnosis(String zoneId, String diagnosis, String severity) {
    final idx = _zones.indexWhere((z) => z.id == zoneId);
    if (idx != -1) {
      _zones[idx].lastDiagnosis = diagnosis;
      _zones[idx].lastDiagnosisSeverity = severity;
      _zones[idx].lastDiagnosisDate = DateTime.now();
      notifyListeners();
    }
  }

  String getContextForActiveZone() {
    if (_activeZone == null) return "Tanaman Umum (Tidak ada zona spesifik)";
    return "Zona: ${_activeZone!.name}, Jenis Cabai: ${_activeZone!.plantType}, Jumlah Tanaman: ${_activeZone!.plantCount} buah.";
  }
}
