import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'run_location.dart';

bool get available => true;

Stream<GeoFix> watch() {
  int? id;
  late final StreamController<GeoFix> c;
  c = StreamController<GeoFix>(
    onListen: () {
      id = web.window.navigator.geolocation.watchPosition(
        (web.GeolocationPosition pos) {
          final k = pos.coords;
          c.add(GeoFix(
            lat: k.latitude,
            lon: k.longitude,
            accuracyM: k.accuracy,
            speedMs: k.speed,
            at: DateTime.now(),
          ));
        }.toJS,
        (web.GeolocationPositionError e) {
          c.addError(e.message);
        }.toJS,
        web.PositionOptions(enableHighAccuracy: true, maximumAge: 1000, timeout: 20000),
      );
    },
    onCancel: () {
      if (id != null) web.window.navigator.geolocation.clearWatch(id!);
    },
  );
  return c.stream;
}
