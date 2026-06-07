import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Continuously listens in short bursts for the "Hey ADM AI" wake phrase
/// using on-device speech recognition (no extra native wake-word engine
/// is bundled — this trades a little battery/accuracy for zero extra
/// permissions or paid SDKs). When the phrase is detected, [onWakeWord]
/// fires so the app can open the voice screen and start a real command.
///
/// NOTE: true "always-on, screen-off" wake-word listening on Android
/// requires either a paid engine (e.g. Picovoice Porcupine) or a
/// persistent foreground service that keeps the mic open — this service
/// is designed to run inside [AdmBackgroundService]'s foreground service
/// so the OS doesn't kill it, but Android may still throttle the mic
/// when the screen is off depending on OEM battery policies.
class WakeWordService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();

  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  static const List<String> wakePhrases = [
    'hey adm ai',
    'hey adm a i',
    'ey adm ai',
    'salom adm ai',
    'adm ai',
    'эй адм аи',
    'салом адм аи',
  ];

  bool _isActive = false;
  bool _isInitialized = false;
  String _lastHeard = '';
  void Function()? _onWakeWord;
  String _locale = 'uz-UZ';

  bool get isActive => _isActive;
  String get lastHeard => _lastHeard;

  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (_) => _scheduleRestart(),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _scheduleRestart();
        }
      },
    );
    return _isInitialized;
  }

  /// Starts the listen → check → relisten loop. Call this from the
  /// background service or when the user enables "Hey ADM AI" in settings.
  Future<void> start({required void Function() onWakeWord, String? locale}) async {
    if (_isActive) return;
    if (!await _ensureInitialized()) return;

    _onWakeWord = onWakeWord;
    _locale = locale ?? _locale;
    _isActive = true;
    notifyListeners();
    _listenCycle();
  }

  Future<void> stop() async {
    _isActive = false;
    _onWakeWord = null;
    await _speech.stop();
    notifyListeners();
  }

  void _scheduleRestart() {
    if (!_isActive) return;
    Future.delayed(const Duration(milliseconds: 400), _listenCycle);
  }

  Future<void> _listenCycle() async {
    if (!_isActive || _speech.isListening) return;

    await _speech.listen(
      onResult: (result) {
        _lastHeard = result.recognizedWords.toLowerCase().trim();
        notifyListeners();
        if (result.finalResult && _matchesWakePhrase(_lastHeard)) {
          _trigger();
        }
      },
      localeId: _locale,
      listenFor: const Duration(seconds: 6),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
    );
  }

  bool _matchesWakePhrase(String heard) {
    if (heard.isEmpty) return false;
    return wakePhrases.any((phrase) => heard.contains(phrase));
  }

  void _trigger() {
    final callback = _onWakeWord;
    if (callback == null) return;
    // Pause the wake-word loop while the app handles the activated command —
    // the caller is expected to call `resume()` once it's done listening.
    _speech.stop();
    callback();
  }

  /// Resumes the background wake-word loop after a triggered command finished.
  void resume() {
    if (_isActive) _scheduleRestart();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
