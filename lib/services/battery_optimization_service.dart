import 'package:flutter/services.dart';

/// Bridges to MainActivity's "com.admai.app/native" battery-optimization
/// methods. Android's Doze / App Standby suspends background mic access
/// (killing the "Hey ADM AI" wake-word loop) unless the app is exempted --
/// the same official whitelist mechanism WhatsApp/Telegram rely on to stay
/// reachable in the background. Only the user can grant this, via the
/// system dialog [requestExemption] launches.
class BatteryOptimizationService {
  static const _channel = MethodChannel('com.admai.app/native');

  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  Future<bool> isExempted() async {
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Launches the system "ignore battery optimizations" dialog for this app.
  Future<void> requestExemption() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  /// Opens the OS-wide battery optimization list (fallback if the direct
  /// request dialog is unavailable on this OEM's Android build).
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {}
  }
}
