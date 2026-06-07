import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  double _confidence = 0.0;
  double _soundLevel = 0.0;
  String _selectedLocale = 'uz-UZ';

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  double get confidence => _confidence;
  double get soundLevel => _soundLevel;

  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = await _speech.initialize(
      onError: (error) {
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );

    await _configureTts();
    notifyListeners();
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('uz-UZ');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  Future<bool> startListening({
    required Function(String text) onResult,
    String? locale,
  }) async {
    if (!_isInitialized) await initialize();
    if (_isListening) return false;

    final locales = await _speech.locales();
    final targetLocale = locale ?? _selectedLocale;

    _recognizedText = '';
    _isListening = true;
    notifyListeners();

    final success = await _speech.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        _confidence = result.confidence;
        notifyListeners();
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
          notifyListeners();
        }
      },
      onSoundLevelChange: (level) {
        _soundLevel = level;
        notifyListeners();
      },
      localeId: targetLocale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );

    if (!success) {
      _isListening = false;
      notifyListeners();
    }

    return success;
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
    }
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  void setLanguage(String locale) {
    _selectedLocale = locale;
    _tts.setLanguage(locale);
    notifyListeners();
  }

  Future<List<String>> getAvailableLocales() async {
    final locales = await _speech.locales();
    return locales.map((l) => l.localeId).toList();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
