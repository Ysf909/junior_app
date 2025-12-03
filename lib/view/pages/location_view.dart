// File: lib/views/location_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:junior_app/model/location_model.dart';
import 'package:junior_app/view_model/location_view_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  final Completer<GoogleMapController> _mapController = Completer();

  // Markers and polylines
  final Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};

  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;

  String _pickMode = 'pickup';

  bool get _isLargeScreen => MediaQuery.of(context).size.width > 800;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = Provider.of<LocationViewModel>(context, listen: false);
      try {
        if (vm.currentLocationLat != null && vm.currentLocationLon != null) {
          _currentLocation =
              LatLng(vm.currentLocationLat!, vm.currentLocationLon!);
          _addOrUpdateMarker('current', _currentLocation!, title: 'You');
          setState(() {});
        }

        if (vm.selectedPickup != null) {
          _pickupLocation =
              LatLng(vm.selectedPickup!.lat, vm.selectedPickup!.lon);
          _addOrUpdateMarker('pickup', _pickupLocation!,
              title: vm.selectedPickup!.name);
        }
        if (vm.selectedDestination != null) {
          _destinationLocation =
              LatLng(vm.selectedDestination!.lat, vm.selectedDestination!.lon);
          _addOrUpdateMarker('destination', _destinationLocation!,
              title: vm.selectedDestination!.name);
        }
        _updatePolyline();
      } catch (_) {}
    });
  }

  // -----------------------------------------------------------
  // MARKERS & POLYLINES
  // -----------------------------------------------------------

  void _addOrUpdateMarker(String id, LatLng pos,
      {String? title, BitmapDescriptor? icon}) {
    final markerId = MarkerId(id);
    final marker = Marker(
      markerId: markerId,
      position: pos,
      infoWindow: InfoWindow(title: title ?? id),
      icon: icon ?? BitmapDescriptor.defaultMarker,
    );
    _markers[markerId] = marker;
  }

  void _updatePolyline() {
    final List<LatLng> points = [];
    if (_currentLocation != null) points.add(_currentLocation!);
    if (_pickupLocation != null) points.add(_pickupLocation!);
    if (_destinationLocation != null) points.add(_destinationLocation!);

    final polylineId = PolylineId('route');
    final polyline = Polyline(
      polylineId: polylineId,
      points: points,
      width: 5,
      color: Colors.blue,
    );
    _polylines[polylineId] = polyline;
    setState(() {});
  }

  // -----------------------------------------------------------
  // GOOGLE MAPS NAVIGATION LAUNCHER
  // -----------------------------------------------------------

  Future<void> _launchGoogleMapsRoute() async {
    if (_pickupLocation == null || _destinationLocation == null) return;

    final origin = "${_pickupLocation!.latitude},${_pickupLocation!.longitude}";
    final dest =
        "${_destinationLocation!.latitude},${_destinationLocation!.longitude}";

    final url = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving&dir_action=navigate");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }

  // -----------------------------------------------------------
  // UI HANDLERS
  // -----------------------------------------------------------

  void _onMapTap(LatLng pos) {
    if (_pickMode == 'pickup') {
      _pickupLocation = pos;
      _addOrUpdateMarker('pickup', pos, title: 'Pickup');
    } else {
      _destinationLocation = pos;
      _addOrUpdateMarker('destination', pos, title: 'Destination');
    }
    _updatePolyline();
  }

  void _setPickupFromModel(LocationModel loc) {
    _pickupLocation = LatLng(loc.lat, loc.lon);
    _addOrUpdateMarker('pickup', _pickupLocation!, title: loc.name);
    _moveCameraTo(_pickupLocation!);
    _updatePolyline();
  }

  void _setDestinationFromModel(LocationModel loc) {
    _destinationLocation = LatLng(loc.lat, loc.lon);
    _addOrUpdateMarker('destination', _destinationLocation!, title: loc.name);
    _moveCameraTo(_destinationLocation!);
    _updatePolyline();
  }

  Future<void> _moveCameraTo(LatLng pos) async {
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
  }

  // -----------------------------------------------------------
  // SIDE LIST
  // -----------------------------------------------------------

  Widget _buildSideList(LocationViewModel vm) {
    final items = <Widget>[];

    items.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text('Saved locations',
                  style: Theme.of(context).textTheme.titleMedium)),
          IconButton(
            onPressed: () =>
                setState(() => _pickMode =
                    _pickMode == 'pickup' ? 'destination' : 'pickup'),
            icon: const Icon(Icons.swap_horiz),
          )
        ],
      ),
    ));

    if (vm.locations == null || vm.locations!.isEmpty) {
      items.add(const Padding(
          padding: EdgeInsets.all(12), child: Text('No saved locations')));
    } else {
      for (final loc in vm.locations!) {
        items.add(ListTile(
          leading: const Icon(Icons.place),
          title: Text(loc.name),
          onTap: () {
            if (_pickMode == 'pickup') {
              _setPickupFromModel(loc);
            } else {
              _setDestinationFromModel(loc);
            }
          },
        ));
      }
    }

    items.add(const Divider());
    items.add(
      ListTile(
        leading: const Icon(Icons.flag),
        title: const Text('Clear route'),
        onTap: () {
          _pickupLocation = null;
          _destinationLocation = null;
          _markers.remove(MarkerId('pickup'));
          _markers.remove(MarkerId('destination'));
          _polylines.clear();
          Provider.of<LocationViewModel>(context, listen: false).clearRoute();
          setState(() {});
        },
      ),
    );

    return Material(
      elevation: 2,
      child: SizedBox(
        width: 320,
        child: ListView(children: items),
      ),
    );
  }

  // -----------------------------------------------------------
  // MAIN UI
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LocationViewModel>(context);

    final initialCamera = CameraPosition(
      target: _currentLocation ?? const LatLng(33.8938, 35.5018),
      zoom: 12,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Location View')),
      drawer: !_isLargeScreen
          ? Drawer(child: SafeArea(child: _buildSideList(vm)))
          : null,
      body: Row(
        children: [
          if (_isLargeScreen) _buildSideList(vm),
          Expanded(
            child: Column(
              children: [
                // -----------------------------------------------------------
                // TOP BAR — CONFIRM BUTTON FIXED HERE
                // -----------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ToggleButtons(
                        isSelected: [
                          _pickMode == 'pickup',
                          _pickMode == 'destination'
                        ],
                        onPressed: (i) => setState(() =>
                            _pickMode = i == 0 ? 'pickup' : 'destination'),
                        children: const [
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Pickup')),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Destination')),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
  onPressed: (_pickupLocation != null && _destinationLocation != null)
      ? () async {
          vm.setPickupAndDestination(_pickupLocation!, _destinationLocation!);

          final origin = "${_pickupLocation!.latitude},${_pickupLocation!.longitude}";
          final destination = "${_destinationLocation!.latitude},${_destinationLocation!.longitude}";

          final googleMapsUrl = Uri.parse(
            "google.navigation:q=$destination&mode=d",
          );

          final webFallbackUrl = Uri.parse(
            "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving",
          );

          try {
            // Try launching the Google Maps app
            if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
              // Fallback to browser if Google Maps is not installed
              await launchUrl(webFallbackUrl, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            await launchUrl(webFallbackUrl, mode: LaunchMode.externalApplication);
          }
        }
      : null,
  child: const Text('Confirm route'),
)

                    ],
                  ),
                ),

                // -----------------------------------------------------------
                // MAP
                // -----------------------------------------------------------
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: initialCamera,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                    },
                    markers: Set<Marker>.from(_markers.values),
                    polylines: Set<Polyline>.from(_polylines.values),
                    onTap: _onMapTap,
                  ),
                ),

                // -----------------------------------------------------------
                // FOOTER
                // -----------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                          'Pickup: ${_pickupLocation?.latitude ?? '-'}, ${_pickupLocation?.longitude ?? '-'}'),
                      Text(
                          'Destination: ${_destinationLocation?.latitude ?? '-'}, ${_destinationLocation?.longitude ?? '-'}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
