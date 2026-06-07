import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/services/local_payment_service.dart';

void main() {
  group('LocalPaymentProvider', () {
    test('exposes the backend route id and a display label for each provider', () {
      expect(LocalPaymentProvider.click.id, 'click');
      expect(LocalPaymentProvider.click.label, 'Click');

      expect(LocalPaymentProvider.payme.id, 'payme');
      expect(LocalPaymentProvider.payme.label, 'Payme');
    });
  });

  group('LocalPaymentService.openCheckout', () {
    test('returns false for an unparsable URL without touching the platform channel', () async {
      final service = LocalPaymentService();

      expect(await service.openCheckout('http://[malformed-host'), isFalse);
    });
  });
}
