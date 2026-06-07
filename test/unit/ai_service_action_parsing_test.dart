import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/services/ai_service.dart';

void main() {
  group('parseActionFromContent', () {
    test('returns plain text untouched when no action block is present', () {
      final result = parseActionFromContent('Salom! Sizga qanday yordam bera olaman?');

      expect(result.cleanText, 'Salom! Sizga qanday yordam bera olaman?');
      expect(result.action, isNull);
    });

    test('extracts an action command and strips it from the text', () {
      const content = 'Albatta, hozir qo\'ng\'iroq qilaman.'
          ' {"action": "MAKE_CALL", "params": {"phone": "+998901234567"}}';

      final result = parseActionFromContent(content);

      expect(result.action, isNotNull);
      expect(result.action!.type, 'MAKE_CALL');
      expect(result.action!.params['phone'], '+998901234567');
      expect(result.cleanText, 'Albatta, hozir qo\'ng\'iroq qilaman.');
    });

    test('defaults params to an empty map when absent', () {
      const content = '{"action": "OPEN_CAMERA"}';

      final result = parseActionFromContent(content);

      expect(result.action, isNotNull);
      expect(result.action!.type, 'OPEN_CAMERA');
      expect(result.action!.params, isEmpty);
    });

    test('drops the action when its JSON is malformed, leaving no action command', () {
      const content = 'Bajarayapman... {"action": "BROKEN", "params": {unquoted: true}';

      final result = parseActionFromContent(content);

      expect(result.action, isNull);
      expect(result.cleanText, 'Bajarayapman...');
    });
  });
}
