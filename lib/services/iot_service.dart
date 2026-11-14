import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

enum IotConnectionStatus {
  notConnected, // Belum terhubung (belum ada data masuk dari ESP32)
  connected,    // Terhubung (data valid masuk dalam 15 detik terakhir)
  disconnected, // Terputus / Data Tidak Terkini (pernah terhubung namun terhenti)
}

/// Data sensor real-time dari ESP32
class SensorData {
  final double suhu;
  final double humidity;
  final int soilValue;
  final int soilPersen;
  final int waterDistanceCm;
  final int lastUpdate; // unix timestamp ms

  const SensorData({
    this.suhu = 0,
    this.humidity = 0,
    this.soilValue = 0,
    this.soilPersen = 0,
    this.waterDistanceCm = 0,
    this.lastUpdate = 0,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> m) => SensorData(
    suhu: (m['suhu'] as num?)?.toDouble() ?? 0,
    humidity: (m['humidity'] as num?)?.toDouble() ?? 0,
    soilValue: (m['soilValue'] as num?)?.toInt() ?? 0,
    soilPersen: (m['soilPersen'] as num?)?.toInt() ?? 0,
    waterDistanceCm: (m['waterDistanceCm'] as num?)?.toInt() ?? 0,
    lastUpdate: (m['lastUpdate'] is num) ? (m['lastUpdate'] as num).toInt() : 0,
  );

  /// True jika data pernah diterima dari ESP32
  bool get hasValidData => lastUpdate > 0;

  /// True jika data diperbarui dalam 15 detik terakhir
  bool get isOnline =>
      lastUpdate > 0 &&
      (DateTime.now().millisecondsSinceEpoch - lastUpdate) < 15000;

  DateTime? get lastUpdateDateTime =>
      lastUpdate > 0 ? DateTime.fromMillisecondsSinceEpoch(lastUpdate) : null;

  IotConnectionStatus get connectionStatus {
    if (lastUpdate <= 0) return IotConnectionStatus.notConnected;
    if (isOnline) return IotConnectionStatus.connected;
    return IotConnectionStatus.disconnected;
  }

  /// Persentase level air berdasarkan jarak ultrasonik.
  /// Asumsi tandon penuh = jarak 5 cm, kosong = jarak 30 cm.
  int get waterLevelPersen {
    if (waterDistanceCm <= 0) return 0;
    const int fullDist = 5;
    const int emptyDist = 30;
    final pct = ((emptyDist - waterDistanceCm) / (emptyDist - fullDist) * 100)
        .round()
        .clamp(0, 100);
    return pct;
  }
}

/// Status relay ESP32
class RelayStatus {
  final bool pompaAir;
  final bool solenoidA;
  final bool solenoidB;
  final bool pompaPestisida;
  final bool autoMode;

  const RelayStatus({
    this.pompaAir = false,
    this.solenoidA = false,
    this.solenoidB = false,
    this.pompaPestisida = false,
    this.autoMode = false,
  });

  factory RelayStatus.fromMap(Map<dynamic, dynamic> m) => RelayStatus(
    pompaAir: m['pompaAir'] == true,
    solenoidA: m['solenoidA'] == true,
    solenoidB: m['solenoidB'] == true,
    pompaPestisida: m['pompaPestisida'] == true,
    autoMode: m['autoMode'] == true,
  );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class IotService {
  static final IotService instance = IotService._();
  IotService._();

  static const String _root = 'fertiflow';

  final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fertiflow-88493-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );

  // Stream controllers untuk UI
  final _sensorCtrl = StreamController<SensorData>.broadcast();
  final _relayCtrl = StreamController<RelayStatus>.broadcast();

  Stream<SensorData> get sensorStream => _sensorCtrl.stream;
  Stream<RelayStatus> get relayStream => _relayCtrl.stream;

  SensorData _lastSensor = const SensorData();
  RelayStatus _lastRelay = const RelayStatus();

  SensorData get lastSensor => _lastSensor;
  RelayStatus get lastRelay => _lastRelay;

  StreamSubscription? _sensorSub;
  StreamSubscription? _relaySub;

  /// Mulai mendengarkan Firebase â€” panggil sekali saat app start
  void startListening() {
    // â”€â”€ Sensor â”€â”€
    _sensorSub = _db.ref('$_root/sensors').onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        _lastSensor = SensorData.fromMap(raw);
        _sensorCtrl.add(_lastSensor);
      }
    }, onError: (e) => debugPrint('[IoT] sensor error: $e'));

    // â”€â”€ Relay status â”€â”€
    _relaySub = _db.ref('$_root/relay').onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        _lastRelay = RelayStatus.fromMap(raw);
        _relayCtrl.add(_lastRelay);
      }
    }, onError: (e) => debugPrint('[IoT] relay error: $e'));

    debugPrint('[IoT] Listening to Firebase...');
  }

  void stopListening() {
    _sensorSub?.cancel();
    _relaySub?.cancel();
  }

  // â”€â”€â”€ Kirim perintah ke ESP32 â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Nyalakan pompa air (irigasi) — matikan yang lain
  Future<void> setPompaAir(bool on) async {
    if (on) {
      await _db.ref('$_root/relay').update({
        'pompaAir': true,
        'solenoidA': false,
        'solenoidB': false,
        'pompaPestisida': false,
      });
    } else {
      await _db.ref('$_root/relay').update({'pompaAir': false});
    }
    unawaited(_sendCommand(on ? 'IRIGASI' : 'OFF'));
  }

  /// Nyalakan pestisida A (solenoid A + pompa pestisida)
  Future<void> setPestisidaA(bool on) async {
    if (on) {
      await _db.ref('$_root/relay').update({
        'pompaAir': false,
        'solenoidA': true,
        'solenoidB': false,
        'pompaPestisida': true,
      });
    } else {
      await _db.ref('$_root/relay').update({
        'solenoidA': false,
        'pompaPestisida': false,
      });
    }
    unawaited(_sendCommand(on ? 'PESTISIDA_A' : 'OFF'));
  }

  /// Nyalakan pestisida B (solenoid B + pompa pestisida)
  Future<void> setPestisidaB(bool on) async {
    if (on) {
      await _db.ref('$_root/relay').update({
        'pompaAir': false,
        'solenoidA': false,
        'solenoidB': true,
        'pompaPestisida': true,
      });
    } else {
      await _db.ref('$_root/relay').update({
        'solenoidB': false,
        'pompaPestisida': false,
      });
    }
    unawaited(_sendCommand(on ? 'PESTISIDA_B' : 'OFF'));
  }

  /// Set mode otomatis
  Future<void> setAutoMode(bool on) async {
    if (on) {
      await _db.ref('$_root/relay').update({
        'autoMode': true,
        'pompaAir': false,
        'solenoidA': false,
        'solenoidB': false,
        'pompaPestisida': false,
      });
    } else {
      await _db.ref('$_root/relay').update({'autoMode': false});
    }
  }

  Future<void> setSemuaOff() async {
    await _db.ref('$_root/relay').update({
      'pompaAir': false,
      'solenoidA': false,
      'solenoidB': false,
      'pompaPestisida': false,
    });
    unawaited(_sendCommand('OFF'));
  }

  Future<void> _sendCommand(String action) async {
    await _db.ref('$_root/command').set({
      'action': action,
      'timestamp': ServerValue.timestamp,
    });
    debugPrint('[IoT] Command sent: $action');
  }

  void dispose() {
    stopListening();
    _sensorCtrl.close();
    _relayCtrl.close();
  }
}



