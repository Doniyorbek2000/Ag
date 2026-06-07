import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/wake_word_service.dart';
import '../services/background_service.dart';
import '../services/battery_optimization_service.dart';
import '../router/app_router.dart';

/// Bridges [WakeWordService] (continuous "Hey ADM AI" listening) with
/// navigation: when the phrase is detected, the app is routed to the
/// voice screen so the user can speak their command immediately.
///
/// While enabled, this also keeps [AdmBackgroundService]'s persistent
/// foreground notification (microphone-type) running. The actual listen
/// loop still runs on the main isolate (it needs the app's GoRouter), but
/// the foreground service raises the process's OS priority and signals to
/// the system that the mic is in active use -- the standard mitigation
/// always-listening assistants use to survive the screen turning off.
/// Some OEM battery managers may still suspend the mic regardless; there
/// is no app-level way to fully override that.
class WakeWordState {
  final bool enabled;
  final bool isListening;
  final String lastHeard;
  final bool batteryExempted;

  const WakeWordState({
    this.enabled = false,
    this.isListening = false,
    this.lastHeard = '',
    this.batteryExempted = false,
  });

  WakeWordState copyWith({
    bool? enabled,
    bool? isListening,
    String? lastHeard,
    bool? batteryExempted,
  }) {
    return WakeWordState(
      enabled: enabled ?? this.enabled,
      isListening: isListening ?? this.isListening,
      lastHeard: lastHeard ?? this.lastHeard,
      batteryExempted: batteryExempted ?? this.batteryExempted,
    );
  }
}

class WakeWordController extends StateNotifier<WakeWordState> {
  final Ref _ref;
  final WakeWordService _service = WakeWordService();
  final BatteryOptimizationService _battery = BatteryOptimizationService();
  static const _settingsKey = 'wake_word_enabled';

  WakeWordController(this._ref) : super(const WakeWordState()) {
    _restore();
    _service.addListener(_onServiceChanged);
    _refreshBatteryStatus();
  }

  void _restore() {
    final box = Hive.box('settings');
    final enabled = box.get(_settingsKey, defaultValue: false) as bool;
    if (enabled) enable();
  }

  Future<void> _refreshBatteryStatus() async {
    final exempted = await _battery.isExempted();
    state = state.copyWith(batteryExempted: exempted);
  }

  /// Launches the system dialog asking the user to exempt ADM AI from
  /// battery optimization, so "Hey ADM AI" keeps listening reliably in the
  /// background. Required once per device -- the OS remembers the choice.
  Future<void> requestBatteryExemption() async {
    await _battery.requestExemption();
    await _refreshBatteryStatus();
  }

  void _onServiceChanged() {
    state = state.copyWith(
      isListening: _service.isActive,
      lastHeard: _service.lastHeard,
    );
  }

  Future<void> enable({String? locale}) async {
    final box = Hive.box('settings');
    await box.put(_settingsKey, true);

    await AdmBackgroundService.startVoiceService();

    // Prompt for the battery-optimization exemption the first time the
    // feature is turned on -- without it, Doze kills the listening loop
    // shortly after the screen turns off.
    if (!await _battery.isExempted()) {
      await requestBatteryExemption();
    }

    await _service.start(
      locale: locale,
      onWakeWord: () {
        final router = _ref.read(appRouterProvider);
        router.go('/voice', extra: {'autoListen': true});
        // Give the voice screen time to take over the mic before resuming
        // the background wake-word loop.
        Future.delayed(const Duration(seconds: 8), _service.resume);
      },
    );
    state = state.copyWith(enabled: true, isListening: true);
  }

  Future<void> disable() async {
    final box = Hive.box('settings');
    await box.put(_settingsKey, false);
    await _service.stop();
    await AdmBackgroundService.stopVoiceService();
    state = state.copyWith(enabled: false, isListening: false);
  }

  Future<void> toggle() => state.enabled ? disable() : enable();

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }
}

final wakeWordProvider =
    StateNotifierProvider<WakeWordController, WakeWordState>((ref) {
  return WakeWordController(ref);
});
