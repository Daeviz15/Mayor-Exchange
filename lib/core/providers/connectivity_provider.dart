import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, NetworkStatus>(
        ConnectivityNotifier.new);

class ConnectivityNotifier extends Notifier<NetworkStatus> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();

  @override
  NetworkStatus build() {
    // Initial check
    _checkInitialConnection();

    // Listen to network changes (Wi-Fi/Mobile)
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      _checkInternetAccess();
    });

    ref.onDispose(() {
      _connectivitySubscription.cancel();
    });

    return NetworkStatus.online;
  }

  Future<void> _checkInitialConnection() async {
    await _checkInternetAccess();
  }

  Future<void> _checkInternetAccess() async {
    // Rely primarily on the OS reporting a connection
    // This avoids false positives where the OS says "Connected" but a specific ping fails
    final connectivityResult = await _connectivity.checkConnectivity();

    // Check if there is NO connection type available
    if (connectivityResult.contains(ConnectivityResult.none) ||
        connectivityResult.isEmpty) {
      state = NetworkStatus.offline;
    } else {
      // If we have Wifi, Mobile, Ethernet, etc., we assume online for the UI.
      // Actual API failures will be handled by the respective repositories.
      state = NetworkStatus.online;
    }
  }
}
