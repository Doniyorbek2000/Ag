import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/wake_word_service.dart';
import '../router/app_router.dart';

/// Bridges [WakeWordService] (continuous "Hey ADM AI" listening) with
/// navigation: when the phrase is detected, the app is routed to the
/// voice screen so the user can speak their command immediately.
class WakeWordState {
  final bool enabled;
  final bool isListening;
  final String lastHeard;

  const WakeWordState({
    this.enabled = false,
    this.isListening = false,
    this.lastHeard = '',
  });

  WakeWordState copyWith({bool? enabled, bool? isListening, String? lastHeard}) {
    return WakeWordState(
      enabled: enabled ?? this.enabled,
      isListening: isListening ?? this.isListening,
      lastHeard: lastHeard ?? this.lastHeard,
    );
  }
}

class WakeWordController extends StateNotifier<WakeWordState> {
  final Ref _ref;
  final WakeWordService _service = WakeWordService();
  static const _settingsKey = 'wake_word_enabled';

  WakeWordController(this._ref) : super(const WakeWordState()) {
    _restore();
    _service.addListener(_onServiceChanged);
  }

  void _restore() {
    final box = Hive.box('settings');
    final enabled = box.get(_settingsKey, defaultValue: false) as bool;
    if (enabled) enable();
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
