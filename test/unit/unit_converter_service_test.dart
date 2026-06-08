import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/services/unit_converter_service.dart';

void main() {
  group('UnitConverter.convert -- length', () {
    test('converts kilometers to miles', () {
      expect(UnitConverter.convert(value: 10, from: 'km', to: 'mile'), closeTo(6.2137, 0.001));
    });

    test('converts meters to feet using English and Uzbek aliases interchangeably', () {
      final viaEnglish = UnitConverter.convert(value: 1, from: 'm', to: 'foot');
      final viaUzbek = UnitConverter.convert(value: 1, from: 'metr', to: 'fut');
      expect(viaEnglish, closeTo(3.2808, 0.001));
      expect(viaUzbek, closeTo(viaEnglish, 1e-9));
    });

    test('round-trips through conversion and back', () {
      final converted = UnitConverter.convert(value: 42, from: 'mile', to: 'km');
      final back = UnitConverter.convert(value: converted, from: 'km', to: 'mile');
      expect(back, closeTo(42, 0.0001));
    });
  });

  group('UnitConverter.convert -- weight', () {
    test('converts pounds to kilograms', () {
      expect(UnitConverter.convert(value: 5, from: 'lb', to: 'kg'), closeTo(2.268, 0.001));
    });

    test('converts kilograms to grams via the "funt"/"untsiya" Uzbek aliases for pounds/ounces', () {
      expect(UnitConverter.convert(value: 1, from: 'kg', to: 'g'), 1000);
      expect(UnitConverter.convert(value: 16, from: 'oz', to: 'lb'), closeTo(1, 0.001));
    });
  });

  group('UnitConverter.convert -- volume', () {
    test('converts liters to gallons', () {
      expect(UnitConverter.convert(value: 10, from: 'l', to: 'gallon'), closeTo(2.6417, 0.001));
    });

    test('converts milliliters to liters', () {
      expect(UnitConverter.convert(value: 1500, from: 'ml', to: 'l'), 1.5);
    });
  });

  group('UnitConverter.convert -- temperature', () {
    test('converts celsius to fahrenheit', () {
      expect(UnitConverter.convert(value: 0, from: 'celsius', to: 'fahrenheit'), 32);
      expect(UnitConverter.convert(value: 100, from: 'c', to: 'f'), 212);
    });

    test('converts fahrenheit to celsius', () {
      expect(UnitConverter.convert(value: 32, from: 'f', to: 'celsius'), closeTo(0, 1e-9));
    });

    test('converts celsius to kelvin', () {
      expect(UnitConverter.convert(value: 0, from: 'celsius', to: 'kelvin'), closeTo(273.15, 1e-9));
    });

    test('round-trips fahrenheit -> kelvin -> fahrenheit', () {
      final kelvin = UnitConverter.convert(value: 98.6, from: 'fahrenheit', to: 'kelvin');
      final back = UnitConverter.convert(value: kelvin, from: 'kelvin', to: 'fahrenheit');
      expect(back, closeTo(98.6, 0.0001));
    });
  });

  group('UnitConverter.convert -- error handling', () {
    test('rejects unrecognized units', () {
      expect(
        () => UnitConverter.convert(value: 1, from: 'banana', to: 'km'),
        throwsA(isA<UnitConversionException>().having((e) => e.message, 'message', contains('banana'))),
      );
    });

    test('rejects mismatched categories (e.g. weight to length)', () {
      expect(
        () => UnitConverter.convert(value: 1, from: 'kg', to: 'km'),
        throwsA(isA<UnitConversionException>()),
      );
    });

    test('UnitConversionException.toString returns the message', () {
      expect(UnitConversionException('noma\'lum birlik').toString(), 'noma\'lum birlik');
    });
  });
}
