import 'dart:math';

import 'package:geolocator/geolocator.dart';

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.reason);
  final String reason; // off | denied | timeout
}

/// Current position for the time-and-location stamp (PRD A3). GPS works
/// without a data connection, so this also runs offline.
Future<Position> currentPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) throw const LocationUnavailable('off');
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw const LocationUnavailable('denied');
  }
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
    );
  } catch (_) {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return last;
    throw const LocationUnavailable('timeout');
  }
}

/// Same great-circle formula as app.distance_m() on the server.
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = pow(sin(dLat / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
  return 2 * r * asin(sqrt(a));
}
