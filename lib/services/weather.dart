import 'dart:convert';

import 'package:http/http.dart' as http;

import '../widgets/run_scene.dart';

/// Current weather for the scene, from Open-Meteo (free, no key), fetched
/// once the phone's location is known outdoors. Indoors the sky stays clear.
class Weather {
  static Future<SceneWeather?> at(double lat, double lon) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(3),
      'longitude': lon.toStringAsFixed(3),
      'current': 'weather_code',
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final code = (json['current'] as Map<String, dynamic>?)?['weather_code'] as num?;
      if (code == null) return null;
      return fromCode(code.toInt());
    } catch (_) {
      return null;
    }
  }

  /// WMO weather codes: 0-1 clear, 2-3 cloud, 51-67 and 80-82 rain, 71-77 and
  /// 85-86 snow, 95+ thunder.
  static SceneWeather fromCode(int code) {
    if (code <= 1) return SceneWeather.clear;
    if (code <= 3 || code == 45 || code == 48) return SceneWeather.cloudy;
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return SceneWeather.snow;
    return SceneWeather.rain;
  }
}
