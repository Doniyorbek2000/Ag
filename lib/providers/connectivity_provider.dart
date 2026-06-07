import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams whether the device currently has *some* network path (Wi-Fi,
/// mobile data, ethernet, VPN). It does not guarantee internet reachability
/// -- just enough signal for [ChatNotifier] to decide whether to attempt a
/// cloud AI request or fall back to [OfflineCommandService].
final isOnlineProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map(_isOnline);
});

/// One-shot connectivity check, used before the stream emits its first value.
final initialOnlineProvider = FutureProvider<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  return _isOnline(results);
});

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}
