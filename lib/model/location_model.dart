// File: lib/model/location_model.dart

class LocationModel {
  final String id;
  final String name;
  final double lat;
  final double lon;

  // <-- make the constructor const so callers can create const instances
  const LocationModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
      };

  @override
  String toString() => 'LocationModel(id: $id, name: $name, lat: $lat, lon: $lon)';
}
