import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Supported app/assistant languages. The UI chrome stays in Uzbek (the
/// app's primary market), but this controls the language the AI assistant
/// answers in and the locale used for speech recognition / text-to-speech.
class AppLanguage {
  final String code; // BCP-47 short code, e.g. 'uz'
  final String speechLocale; // locale id used by speech_to_text / tts
  final String label;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.speechLocale,
    required this.label,
    required this.flag,
  });

  static const uz = AppLanguage(
    code: 'uz',
    speechLocale: 'uz-UZ',
    label: 'O\'zbekcha',
    flag: '🇺🇿',
  );
  static const ru = AppLanguage(
    code: 'ru',
    speechLocale: 'ru-RU',
    label: 'Русский',
    flag: '🇷🇺',
  );
  static const en = AppLanguage(
    code: 'en',
    speechLocale: 'en-US',
    label: 'English',
    flag: '🇺🇸',
  );

  static const all = [uz, ru, en];

  static AppLanguage byCode(String code) {
    return all.firstWhere((l) => l.code == code, orElse: () => uz);
  }
}

/// Persists the assistant's response/speech language in the `settings` Hive
/// box. Defaults to Uzbek, the app's primary language.
class AppLanguageController extends StateNotifier<AppLanguage> {
  static const _key = 'app_language';

  AppLanguageController() : super(AppLanguage.uz) {
    _restore();
  }

  void _restore() {
    final box = Hive.box('settings');
    final code = box.get(_key) as String?;
    if (code != null) {
      state = AppLanguage.byCode(code);
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    await Hive.box('settings').put(_key, language.code);
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>((ref) {
  return AppLanguageController();
});
