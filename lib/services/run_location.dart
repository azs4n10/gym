import 'dart:async';
import 'dart:math' as math;

import 'run_location_stub.dart' if (dart.library.js_interop) 'run_location_web.dart' as bridge;

/// One position report from the device.
class GeoFix {
  const GeoFix({required this.lat, required this.lon, required this.accuracyM, this.speedMs, required this.at});
  final double lat;
  final double lon;
  final double accuracyM;
  final double? speedMs;
  final DateTime at;
}

/// Outdoor distance from the browser's location, when the platform offers it.
class RunLocation {
  static bool get available => bridge.available;

  static Stream<GeoFix> watch() => bridge.watch();

  /// Great-circle distance in km.
  static double distanceKm(GeoFix a, GeoFix b) {
    const r = 6371.0;
    final dLat = _rad(b.lat - a.lat);
    final dLon = _rad(b.lon - a.lon);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
