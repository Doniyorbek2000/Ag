/// Pure-logic unit conversion across length, weight, volume and temperature --
/// powers the `CONVERT_UNITS` AI action so the assistant can answer things
/// like "10 kilometrni milga aylantir" or "30 gradus selsiyni farengeytga
/// aylantir" without any external API (unlike weather/news/currency, these
/// conversions never go stale and need no per-user API key).
class UnitConverter {
  /// Maps every accepted unit alias (Uzbek, Russian and English spellings,
  /// lowercased) to a canonical unit symbol within its category.
  static const Map<String, String> _aliases = {
    // Length -> meters
    'm': 'm', 'metr': 'm', 'meter': 'm', 'metrlar': 'm',
    'km': 'km', 'kilometr': 'km', 'kilometer': 'km',
    'cm': 'cm', 'santimetr': 'cm', 'sm': 'cm',
    'mm': 'mm', 'millimetr': 'mm',
    'mile': 'mile', 'mil': 'mile', 'milya': 'mile', 'миля': 'mile',
    'yard': 'yard', 'yd': 'yard',
    'foot': 'foot', 'feet': 'foot', 'ft': 'foot', 'fut': 'foot',
    'inch': 'inch', 'inches': 'inch', 'in': 'inch', 'dyum': 'inch',

    // Weight -> kilograms
    'kg': 'kg', 'kilogram': 'kg', 'kilogramm': 'kg',
    'g': 'g', 'gram': 'g', 'gramm': 'g',
    'mg': 'mg', 'milligram': 'mg', 'milligramm': 'mg',
    't': 'ton', 'ton': 'ton', 'tonna': 'ton',
    'lb': 'lb', 'lbs': 'lb', 'pound': 'lb', 'funt': 'lb',
    'oz': 'oz', 'ounce': 'oz', 'untsiya': 'oz',

    // Volume -> liters
    'l': 'l', 'liter': 'l', 'litr': 'l',
    'ml': 'ml', 'milliliter': 'ml', 'millilitr': 'ml',
    'gallon': 'gallon', 'gal': 'gallon', 'galon': 'gallon',
    'pint': 'pint', 'pt': 'pint',

    // Temperature
    'c': 'celsius', 'celsius': 'celsius', 'selsiy': 'celsius', '°c': 'celsius',
    'f': 'fahrenheit', 'fahrenheit': 'fahrenheit', 'farengeyt': 'fahrenheit', '°f': 'fahrenheit',
    'k': 'kelvin', 'kelvin': 'kelvin', '°k': 'kelvin',
  };

  /// Conversion factor of each canonical unit relative to its category's
  /// base unit (meters / kilograms / liters). Temperature is handled
  /// separately since its scales aren't linearly proportional to a base unit.
  static const Map<String, double> _toBase = {
    // length -> meters
    'm': 1, 'km': 1000, 'cm': 0.01, 'mm': 0.001,
    'mile': 1609.344, 'yard': 0.9144, 'foot': 0.3048, 'inch': 0.0254,
    // weight -> kilograms
    'kg': 1, 'g': 0.001, 'mg': 0.000001, 'ton': 1000,
    'lb': 0.45359237, 'oz': 0.028349523125,
    // volume -> liters
    'l': 1, 'ml': 0.001, 'gallon': 3.785411784, 'pint': 0.473176473,
  };

  static const Set<String> _lengthUnits = {'m', 'km', 'cm', 'mm', 'mile', 'yard', 'foot', 'inch'};
  static const Set<String> _weightUnits = {'kg', 'g', 'mg', 'ton', 'lb', 'oz'};
  static const Set<String> _volumeUnits = {'l', 'ml', 'gallon', 'pint'};
  static const Set<String> _temperatureUnits = {'celsius', 'fahrenheit', 'kelvin'};

  static String? _canonical(String unit) => _aliases[unit.trim().toLowerCase()];

  static Set<String>? _categoryOf(String canonical) {
    if (_lengthUnits.contains(canonical)) return _lengthUnits;
    if (_weightUnits.contains(canonical)) return _weightUnits;
    if (_volumeUnits.contains(canonical)) return _volumeUnits;
    if (_temperatureUnits.contains(canonical)) return _temperatureUnits;
    return null;
  }

  static double _toCelsius(double value, String unit) {
    switch (unit) {
      case 'celsius':
        return value;
      case 'fahrenheit':
        return (value - 32) * 5 / 9;
      case 'kelvin':
        return value - 273.15;
      default:
        throw StateError('Unknown temperature unit: $unit');
    }
  }

  static double _fromCelsius(double celsius, String unit) {
    switch (unit) {
      case 'celsius':
        return celsius;
      case 'fahrenheit':
        return celsius * 9 / 5 + 32;
      case 'kelvin':
        return celsius + 273.15;
      default:
        throw StateError('Unknown temperature unit: $unit');
    }
  }

  /// Converts [value] from [from] to [to]. Unit names are matched
  /// case-insensitively against a wide set of Uzbek/Russian/English aliases.
  /// Throws [UnitConversionException] if either unit is unrecognized or the
  /// two units belong to different categories (e.g. kilograms to liters).
  static double convert({required double value, required String from, required String to}) {
    final fromCanonical = _canonical(from);
    final toCanonical = _canonical(to);

    if (fromCanonical == null) {
      throw UnitConversionException('"$from" o\'lchov birligini tanimadim');
    }
    if (toCanonical == null) {
      throw UnitConversionException('"$to" o\'lchov birligini tanimadim');
    }

    final fromCategory = _categoryOf(fromCanonical);
    final toCategory = _categoryOf(toCanonical);
    if (fromCategory != toCategory) {
      throw UnitConversionException(
        '"$from" va "$to" turli toifalarga tegishli — ularni bir-biriga aylantirib bo\'lmaydi',
      );
    }

    if (fromCategory == _temperatureUnits) {
      return _fromCelsius(_toCelsius(value, fromCanonical), toCanonical);
    }

    final baseValue = value * _toBase[fromCanonical]!;
    return baseValue / _toBase[toCanonical]!;
  }
}

class UnitConversionException implements Exception {
  final String message;
  UnitConversionException(this.message);
  @override
  String toString() => message;
}
