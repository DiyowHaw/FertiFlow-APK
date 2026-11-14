import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final double temperature;
  final int humidity;
  final int weatherCode;
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.cityName,
  });

  bool get isRaining => weatherCode >= 51 && weatherCode <= 67 || weatherCode >= 80 && weatherCode <= 82;
  bool get isCloudy => weatherCode >= 1 && weatherCode <= 3;
  bool get isClear => weatherCode == 0;
  bool get isThunderstorm => weatherCode >= 95;
}

class WeatherService {
  static final WeatherService instance = WeatherService._();
  WeatherService._();

  Future<WeatherData?> getCurrentWeather() async {
    try {
      // 1. Dapatkan lokasi saat ini
      Position? position = await _determinePosition();
      if (position == null) return null;

      // 2. Dapatkan nama kota via OpenStreetMap Nominatim (Tanpa Library geocoding)
      String cityName = "Lokasi Anda";
      try {
        final geoUrl = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=10&addressdetails=1');
        
        final geoResponse = await http.get(geoUrl, headers: {
          'User-Agent': 'IriGrowApp/1.0', // Nominatim requires User-Agent
        }).timeout(const Duration(seconds: 5));

        if (geoResponse.statusCode == 200) {
          final geoData = json.decode(geoResponse.body);
          if (geoData != null && geoData['address'] != null) {
            final address = geoData['address'];
            cityName = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? "Lokasi Anda";
          }
        }
      } catch (e) {
        // Abaikan jika geocoding gagal, gunakan default "Lokasi Anda"
      }

      // 3. Panggil Open-Meteo API
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];

        return WeatherData(
          temperature: (current['temperature_2m'] as num).toDouble(),
          humidity: (current['relative_humidity_2m'] as num).toInt(),
          weatherCode: (current['weather_code'] as num).toInt(),
          cityName: cityName,
        );
      }
    } catch (e) {
      // Error fetching weather
    }
    return null;
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
