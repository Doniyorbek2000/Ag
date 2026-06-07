import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches real current-weather data from OpenWeatherMap
/// (https://openweathermap.org/current — free tier available).
/// Requires the user to paste their own API key in
/// Settings → Integratsiyalar (anonymous/shared keys would get rate-limited
/// and banned instantly, so there is no way around this).
class WeatherService {
  static const _apiKeyKey = 'openweather_api_key';

  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal() : _dio = Dio(BaseOptions(
        baseUrl: 'https://api.openweathermap.org/data/2.5',
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
      ));

  final Dio _dio;
  String? _apiKey;

  Future<String?> get apiKey async {
    if (_apiKey != null) return _apiKey;
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyKey);
    return _apiKey;
  }

  Future<void> setApiKey(String? key) async {
    _apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove(_apiKeyKey);
    } else {
      await prefs.setString(_apiKeyKey, key);
    }
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Returns current weather for [city] (e.g. "Tashkent").
  Future<WeatherInfo> getCurrentWeather(String city) async {
    final key = await apiKey;
    if (key == null || key.isEmpty) {
      throw WeatherException('Ob-havo API kaliti sozlanmagan');
    }

    try {
      final res = await _dio.get('/weather', queryParameters: {
        'q': city,
        'appid': key,
        'units': 'metric',
        'lang': 'uz',
      });
      final data = res.data as Map<String, dynamic>;
      final weatherList = data['weather'] as List?;
      final description = (weatherList != null && weatherList.isNotEmpty)
          ? weatherList.first['description'] as String? ?? ''
          : '';
      return WeatherInfo(
        city: data['name'] ?? city,
        description: description,
        tempC: (data['main']?['temp'] as num?)?.toDouble() ?? 0,
        feelsLikeC: (data['main']?['feels_like'] as num?)?.toDouble() ?? 0,
        humidity: (data['main']?['humidity'] as num?)?.toInt() ?? 0,
        windSpeed: (data['wind']?['speed'] as num?)?.toDouble() ?? 0,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw WeatherException('"$city" shahri topilmadi');
      }
      throw WeatherException('Ob-havo ma\'lumotini olib bo\'lmadi');
    }
  }
}

class WeatherInfo {
  final String city;
  final String description;
  final double tempC;
  final double feelsLikeC;
  final int humidity;
  final double windSpeed;

  const WeatherInfo({
    required this.city,
    required this.description,
    required this.tempC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windSpeed,
  });

  String toSpokenSummary() {
    return '$city shahrida hozir $description, harorat ${tempC.round()} daraja, '
        'his qilinishi ${feelsLikeC.round()} daraja, namlik $humidity foiz, '
        'shamol tezligi soniyasiga ${windSpeed.toStringAsFixed(1)} metr.';
  }
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  @override
  String toString() => message;
}
