import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adm_ai/services/call_screening_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallScreeningService screening;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    screening = CallScreeningService();
  });

  group('CallScreeningService blocked numbers', () {
    test('starts empty and accumulates unique numbers', () async {
      expect(await screening.getBlockedNumbers(), isEmpty);

      await screening.blockNumber('+998901234567');
      await screening.blockNumber('+998901234567'); // duplicate, ignored
      await screening.blockNumber('+998907654321');

      expect(await screening.getBlockedNumbers(), ['+998901234567', '+998907654321']);
    });

    test('unblockNumber removes only the matching entry', () async {
      await screening.setBlockedNumbers(['+998901234567', '+998907654321']);

      await screening.unblockNumber('+998901234567');

      expect(await screening.getBlockedNumbers(), ['+998907654321']);
    });
  });

  group('CallScreeningService settings', () {
    test('quiet mode and contacts-only flags default to false and persist when set', () async {
      expect(await screening.getQuietModeEnabled(), isFalse);
      expect(await screening.getAllowContactsOnly(), isFalse);

      await screening.setQuietModeEnabled(true);
      await screening.setAllowContactsOnly(true);

      expect(await screening.getQuietModeEnabled(), isTrue);
      expect(await screening.getAllowContactsOnly(), isTrue);
    });

    test('known contacts round-trip through JSON storage', () async {
      await screening.setKnownContacts(['+998901111111', '+998902222222']);

      expect(await screening.getKnownContacts(), ['+998901111111', '+998902222222']);
    });
  });

  group('CallScreeningService malformed storage', () {
    test('getBlockedNumbers recovers gracefully from corrupted JSON', () async {
      SharedPreferences.setMockInitialValues({'flutter.adm_blocked_numbers_json': 'not-json{'});
      screening = CallScreeningService();

      expect(await screening.getBlockedNumbers(), isEmpty);
    });

    test('getLog recovers gracefully from corrupted JSON and returns parsed entries otherwise', () async {
      SharedPreferences.setMockInitialValues({'flutter.adm_call_screening_log_json': 'not-json{'});
      screening = CallScreeningService();
      expect(await screening.getLog(), isEmpty);

      SharedPreferences.setMockInitialValues({
        'flutter.adm_call_screening_log_json':
            '[{"number":"+998901234567","decision":"blocked","timestamp":"2026-06-08T10:00:00Z"}]',
      });
      screening = CallScreeningService();
      final log = await screening.getLog();
      expect(log, hasLength(1));
      expect(log.single['number'], '+998901234567');
      expect(log.single['decision'], 'blocked');
    });
  });
}
