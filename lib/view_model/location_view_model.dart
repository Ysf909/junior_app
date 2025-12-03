import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:junior_app/services/location_service.dart';
import '../model/location_model.dart';

class LocationViewModel extends ChangeNotifier {
  // saved locations
  List<LocationModel>? locations;

  // current device location
  double? currentLocationLat;
  double? currentLocationLon;

  // Selected route
  LocationModel? selectedPickup;
  LocationModel? selectedDestination;

  // Polyline for map route
  List<LatLng> routePolyline = [];

  // Distance & Duration
  String? routeDistance;
  String? routeDuration;

  final GoogleDirectionsService _directions = GoogleDirectionsService('');

  LocationViewModel({
    this.locations,
    this.currentLocationLat,
    this.currentLocationLon,
  });

  void setCurrentLocation(double lat, double lon) {
    currentLocationLat = lat;
    currentLocationLon = lon;
    notifyListeners();
  }

  // Accepts Google LatLng
  void setPickupAndDestination(
    LatLng pickup,
    LatLng destination, {
    String pickupName = 'Pickup',
    String destinationName = 'Destination',
  }) async {
    selectedPickup = LocationModel(
      id: 'pickup',
      name: pickupName,
      lat: pickup.latitude,
      lon: pickup.longitude,
    );

    selectedDestination = LocationModel(
      id: 'destination',
      name: destinationName,
      lat: destination.latitude,
      lon: destination.longitude,
    );

    await _loadRoute();
    notifyListeners();
  }

  // Using LocationModel
  void setPickupAndDestinationFromModels(
      LocationModel pickup, LocationModel destination) async {
    selectedPickup = pickup;
    selectedDestination = destination;

    await _loadRoute();
    notifyListeners();
  }

  // Clear route
  void clearRoute() {
    selectedPickup = null;
    selectedDestination = null;
    routePolyline.clear();
    routeDistance = null;
    routeDuration = null;
    notifyListeners();
  }

// Get route from Google Directions API
Future<void> _loadRoute() async {
  if (selectedPickup == null || selectedDestination == null) return;

  final result = await _directions.getRoute(
    originLat: selectedPickup!.lat,
    originLng: selectedPickup!.lon,
    destLat: selectedDestination!.lat,
    destLng: selectedDestination!.lon,
  );

    if (result != null) {
      routePolyline = result.polylinePoints
          .map((p) => LatLng(p[0], p[1]))
          .toList();

      routeDistance = result.distanceText;
      routeDuration = result.durationText;
    }
  }
}
