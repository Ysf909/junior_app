// lib/domain/models/network_status.dart
enum NetworkStatus {
  wifi,
  mobileData,
  offline,
  unknown,
}

extension NetworkStatusExtension on NetworkStatus {
  String get displayName {
    switch (this) {
      case NetworkStatus.wifi:
        return 'Wi-Fi';
      case NetworkStatus.mobileData:
        return 'Mobile Data';
      case NetworkStatus.offline:
        return 'Offline';
      case NetworkStatus.unknown:
        return 'Unknown';
    }
  }
}