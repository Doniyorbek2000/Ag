import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/services/weather_service.dart';

void main() {
  group('WeatherInfo.toSpokenSummary', () {
    test('renders a natural-language Uzbek summary with rounded values', () {
      const info = WeatherInfo(
        city: 'Toshkent',
        description: 'ochiq osmon',
        tempC: 23.6,
        feelsLikeC: 21.4,
        humidity: 40,
        windSpeed: 3.2,
      );

      expect(
        info.toSpokenSummary(),
        'Toshkent shahrida hozir ochiq osmon, harorat 24 daraja, '
        'his qilinishi 21 daraja, namlik 40 foiz, '
        'shamol tezligi soniyasiga 3.2 metr.',
      );
    });

    test('rounds negative temperatures correctly', () {
      const info = WeatherInfo(
        city: 'Samarqand',
        description: 'qor yog\'moqda',
        tempC: -2.7,
        feelsLikeC: -6.2,
        humidity: 80,
        windSpeed: 1.0,
      );

      expect(info.toSpokenSummary(), contains('harorat -3 daraja'));
      expect(info.toSpokenSummary(), contains('his qilinishi -6 daraja'));
    });
  });

  group('WeatherException', () {
    test('toString returns the message', () {
      expect(WeatherException('API kaliti sozlanmagan').toString(), 'API kaliti sozlanmagan');
    });
  });
}
