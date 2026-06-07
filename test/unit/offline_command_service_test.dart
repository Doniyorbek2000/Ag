import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/services/offline_command_service.dart';

void main() {
  group('OfflineCommandService.parse', () {
    test('recognizes a call request with a phone number', () {
      final cmd = OfflineCommandService.parse('+998 90 123 45 67 ga qo\'ng\'iroq qil');

      expect(cmd, isNotNull);
      expect(cmd!.type, 'MAKE_CALL');
      expect(cmd.params['phone'], '+998901234567');
    });

    test('recognizes an SMS request with a phone number', () {
      final cmd = OfflineCommandService.parse('911011223344 ga sms yubor');

      expect(cmd, isNotNull);
      expect(cmd!.type, 'SEND_SMS');
      expect(cmd.params['phone'], '911011223344');
    });

    test('recognizes an open-app request for a known app', () {
      final cmd = OfflineCommandService.parse('telegram ochib ber');

      expect(cmd, isNotNull);
      expect(cmd!.type, 'OPEN_APP');
      expect(cmd.params['app'], 'telegram');
    });

    test('recognizes camera, gallery, maps, and settings shortcuts', () {
      expect(OfflineCommandService.parse('kamerani och')!.type, 'OPEN_CAMERA');
      expect(OfflineCommandService.parse('galereyani ochib ber')!.type, 'OPEN_GALLERY');
      expect(OfflineCommandService.parse('xaritani ko\'rsat')!.type, 'OPEN_MAPS');
      expect(OfflineCommandService.parse('sozlamalarni och')!.type, 'OPEN_SETTINGS');
    });

    test('returns null for open-ended requests that need the cloud AI', () {
      expect(OfflineCommandService.parse('bugun ob-havo qanday'), isNull);
      expect(OfflineCommandService.parse('eng yaxshi pitsa retsepti aytib ber'), isNull);
      expect(OfflineCommandService.parse(''), isNull);
    });
  });
}
