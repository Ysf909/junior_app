import 'package:flutter/material.dart';
import 'package:junior_app/services/localization_extension.dart';
import 'package:junior_app/model/network_status.dart';
import 'package:junior_app/view_model/localization_view_model.dart';
import 'package:provider/provider.dart';
import '/view_model/network_view_model.dart';

class CloudPage extends StatefulWidget {
  const CloudPage({super.key});

  @override
  _CloudPageState createState() => _CloudPageState();
}


class _CloudPageState extends State<CloudPage> {
  @override
  void initState() {
    super.initState();
    // Auto-start monitoring when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkVM = Provider.of<NetworkViewModel>(context, listen: false);
      if (!networkVM.isMonitoring) networkVM.startMonitoring();
    });
  }

  Color _statusColor(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return Colors.green;
      case NetworkStatus.mobileData:
        return Colors.orange;
      case NetworkStatus.offline:
        return Colors.red;
      case NetworkStatus.unknown:
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('cloud'))),
      body: Center(
        child: Consumer<NetworkViewModel>(
          builder: (context, networkVM, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    networkVM.currentStatus == NetworkStatus.wifi
                        ? Icons.wifi
                        : networkVM.currentStatus == NetworkStatus.mobileData
                            ? Icons.signal_cellular_alt
                            : Icons.signal_wifi_off,
                    color: _statusColor(networkVM.currentStatus),
                    size: 50,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Service Status: ${networkVM.serviceStatus}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Current Network: ${networkVM.currentStatus.displayName}',
                    style: TextStyle(
                      fontSize: 18,
                      color: _statusColor(networkVM.currentStatus),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: networkVM.isMonitoring
                        ? networkVM.stopMonitoring
                        : networkVM.startMonitoring,
                    child: Text(
                      networkVM.isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

