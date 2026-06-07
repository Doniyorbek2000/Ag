import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches real headlines from GNews (https://gnews.io — free tier
/// available, supports Uzbek/Russian results). Requires the user's own
/// API key (Settings → Integratsiyalar) for the same reason as weather:
/// shared keys get rate-limited instantly.
class NewsService {
  static const _apiKeyKey = 'gnews_api_key';

  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal() : _dio = Dio(BaseOptions(
        baseUrl: 'https://gnews.io/api/v4',
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

  /// Returns top headlines, optionally filtered by [topic]
  /// (e.g. "texnologiya", "sport", "iqtisodiyot").
  Future<List<NewsArticle>> getTopHeadlines({String? topic, String lang = 'uz'}) async {
    final key = await apiKey;
    if (key == null || key.isEmpty) {
      throw NewsException('Yangiliklar API kaliti sozlanmagan');
    }

    try {
      final res = await _dio.get(
        topic == null || topic.isEmpty ? '/top-headlines' : '/search',
        queryParameters: {
          'apikey': key,
          'lang': lang,
          'max': 8,
          if (topic != null && topic.isNotEmpty) 'q': topic,
        },
      );
      final articles = (res.data?['articles'] as List?) ?? [];
      return articles
          .map((a) => NewsArticle(
                title: a['title'] ?? '',
                description: a['description'] ?? '',
                source: a['source']?['name'] ?? '',
                url: a['url'] ?? '',
                publishedAt: a['publishedAt'] ?? '',
              ))
          .toList();
    } on DioException catch (_) {
      throw NewsException('Yangiliklarni olib bo\'lmadi');
    }
  }
}

class NewsArticle {
  final String title;
  final String description;
  final String source;
  final String url;
  final String publishedAt;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    required this.publishedAt,
  });
}

class NewsException implements Exception {
  final String message;
  NewsException(this.message);
  @override
  String toString() => message;
}
