import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:junior_app/model/network_status.dart';


class NetworkViewModel with ChangeNotifier {
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  bool _isMonitoring = false;
  String _serviceStatus = 'Stopped';

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Getters
  NetworkStatus get currentStatus => _currentStatus;
  bool get isMonitoring => _isMonitoring;
  String get serviceStatus => _serviceStatus;

  NetworkViewModel() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'network_status_channel',
      'Network Status',
      channelDescription: 'Notifications for network changes',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
        final uniqueId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(uniqueId, 'Network Status', message, platformDetails);
  }

  /// Start monitoring connectivity
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _serviceStatus = 'Running';
    notifyListeners();
    _showNotification(_currentStatus.displayName);

    // Listen to connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateNetworkStatus as void Function(List<ConnectivityResult> event)?) as StreamSubscription<ConnectivityResult>?;

    // Get initial connectivity status
    final initialResult = await Connectivity().checkConnectivity();
    _updateNetworkStatus(initialResult as ConnectivityResult);
  }

  /// Stop monitoring connectivity
  void stopMonitoring() {
    _isMonitoring = false;
    _serviceStatus = 'Stopped';

    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    notifyListeners();
  }

  /// Update the current network status
  void _updateNetworkStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        _currentStatus = NetworkStatus.wifi;
        _showNotification("Connected to Wi-Fi");
        break;
      case ConnectivityResult.mobile:
        _currentStatus = NetworkStatus.mobileData;
        _showNotification("Switched to Mobile Data");
        break;
      case ConnectivityResult.none:
        _currentStatus = NetworkStatus.offline;
        _showNotification("No Internet Connection");
        break;
      default:
        _currentStatus = NetworkStatus.unknown;
        _showNotification("Network status unknown");
    }
    notifyListeners();
  }

  /// Clear data and stop monitoring
  Future<void> clearData() async {
    stopMonitoring();
    _currentStatus = NetworkStatus.unknown;
    notifyListeners();
  }
}
