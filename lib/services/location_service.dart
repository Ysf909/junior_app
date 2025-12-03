import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsResult {
  final List<List<double>> polylinePoints;
  final String distanceText;
  final String durationText;

  DirectionsResult({
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
  });
}

class GoogleDirectionsService {
  final String apiKey;

  GoogleDirectionsService(this.apiKey);

  Future<DirectionsResult?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&mode=driving&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);

    if (data["status"] != "OK") return null;

    final route = data["routes"][0];
    final leg = route["legs"][0];

    final polyline = _decodePolyline(route["overview_polyline"]["points"]);

    // Convert LatLng to List<List<double>>
    final formattedPolyline =
        polyline.map((p) => [p.latitude, p.longitude]).toList();

    return DirectionsResult(
      polylinePoints: formattedPolyline,
      distanceText: leg["distance"]["text"],
      durationText: leg["duration"]["text"],
    );
  }

  // --- Decode polyline to LatLng list ---
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return poly;
  }
}
