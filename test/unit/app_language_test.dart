import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/providers/locale_provider.dart';

void main() {
  group('AppLanguage', () {
    test('all contains exactly uz, ru, en with matching speech locales', () {
      expect(AppLanguage.all.map((l) => l.code).toList(), ['uz', 'ru', 'en']);
      expect(AppLanguage.all.map((l) => l.speechLocale).toList(),
          ['uz-UZ', 'ru-RU', 'en-US']);
    });

    test('byCode resolves a known code to the matching language', () {
      expect(AppLanguage.byCode('ru'), AppLanguage.ru);
      expect(AppLanguage.byCode('en'), AppLanguage.en);
    });

    test('byCode falls back to Uzbek for an unknown code', () {
      expect(AppLanguage.byCode('fr'), AppLanguage.uz);
      expect(AppLanguage.byCode(''), AppLanguage.uz);
    });
  });
}
