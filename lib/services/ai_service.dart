import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class AiService {
  static const String _baseUrl = 'https://api.anthropic.com/v1';
  static const String _model = 'claude-opus-4-8';
  static const int _maxTokens = 4096;

  final Dio _dio;
  final Logger _logger = Logger();
  String _apiKey = '';

  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  AiService._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Content-Type': 'application/json',
            'anthropic-version': '2023-06-01',
          },
        ));

  void setApiKey(String key) {
    _apiKey = key;
    _dio.options.headers['x-api-key'] = key;
  }

  static const String _systemPrompt = '''
Sen ADM AI - foydalanuvchining eng aqlli va ishonchli shaxsiy yordamchisisan.
Sen Siri, Google Assistant va boshqa barcha AI yordamchilaridan ustun bo'lishga mo'ljallangan.
Sen O'zbek, Rus va Ingliz tillarida gaplasha olasan.

QOBILIYATLARING:
1. Telefon boshqaruvi: qo'ng'iroq qilish, xabar yuborish, sozlamalar
2. Ilova boshqaruvi: YouTube, Telegram, WhatsApp, Instagram, Google
3. Buxgalteriya: daromad/xarajat hisobi, hisobotlar
4. Call Center: qo'ng'iroqlarga javob berish, savol-javob
5. Musiqa: qo'shiq qidirish, ijro etish
6. Eslatmalar va kalendarlar
7. Ob-havo, yangiliklar, ma'lumot qidirish
8. Aqlli uy boshqaruvi

XULQ-ATVOR:
- Har doim mehribon, samarali va professional bo'l
- Qisqa va aniq javoblar ber
- Buyruqlarni darhol bajar
- Foydalanuvchi xatosi bo'lsa, muloyimlik bilan to'g'irla
- Har doim foydalanuvchi manfaatini o'yla

BUYRUQ FORMATI:
Agar maxsus amal bajarish kerak bo'lsa, javobingga quyidagi formatda JSON qo'sh:
{"action": "ACTION_TYPE", "params": {...}}

Amallar turlari:
- MAKE_CALL: {phone: "raqam"}
- SEND_SMS: {phone: "raqam", message: "matn"}
- OPEN_APP: {app: "app_nomi"}
- PLAY_MUSIC: {query: "qo'shiq nomi"}
- SEARCH_WEB: {query: "qidiruv"}
- SET_ALARM: {time: "vaqt", label: "nom"}
- OPEN_SETTINGS: {section: "bo'lim"}
- SEND_TELEGRAM: {contact: "ism", message: "matn"}
- SEND_WHATSAPP: {contact: "ism", message: "matn"}
- SEARCH_YOUTUBE: {query: "video nomi"}
- GET_WEATHER: {city: "shahar nomi"}
- GET_NEWS: {topic: "mavzu (ixtiyoriy)"}
- REMEMBER_FACT: {key: "qisqa nom", value: "eslab qolish kerak bo'lgan ma'lumot"}
- FORGET_FACT: {key: "o'chiriladigan eslatma nomi"}

UZOQ MUDDATLI XOTIRA:
Foydalanuvchi senga biror narsani "es ket", "yodingda tut", "eslab qol"
kabi so'zlar bilan eslab qolishni so'rasa, REMEMBER_FACT amalini qo'sh —
bu ma'lumot keyingi barcha suhbatlarda senga avtomatik ko'rsatiladi
("FOYDALANUVCHI HAQIDA ESLAB QOLINGAN MA'LUMOTLAR" bo'limida). Agar u
biror narsani unutishingni so'rasa, FORGET_FACT'dan foydalan. Bu
ma'lumotlardan tabiiy ravishda, eslatib turilganday emas, foydalanuvchi
seni avval ham tanigandek foydalan.

GET_WEATHER va GET_NEWS amallari foydalanuvchi sozlagan tashqi API orqali
real ma'lumot qaytaradi (agar API kaliti sozlanmagan bo'lsa, tizim buni
foydalanuvchiga aytadi — bunday holda o'zingning bilim bazangdan taxminiy
javob bermay, API kalitini Sozlamalar → Integratsiyalarda kiritish
kerakligini tushuntir).
''';

  static const Map<String, String> _languageInstructions = {
    'uz': 'Foydalanuvchiga O\'zbek tilida javob ber.',
    'ru': 'Отвечай пользователю на русском языке.',
    'en': 'Respond to the user in English.',
  };

  Future<AiResponse> sendMessage({
    required String message,
    List<Map<String, String>> conversationHistory = const [],
    String? contextInfo,
    String responseLanguage = 'uz',
  }) async {
    try {
      final messages = [
        ...conversationHistory,
        {'role': 'user', 'content': message},
      ];

      var systemContent = _systemPrompt;
      final languageInstruction = _languageInstructions[responseLanguage];
      if (languageInstruction != null && responseLanguage != 'uz') {
        systemContent = '$systemContent\n\nTIL: $languageInstruction';
      }
      if (contextInfo != null) {
        systemContent = '$systemContent\n\nQO\'SHIMCHA KONTEKST:\n$contextInfo';
      }

      final response = await _dio.post(
        '/messages',
        data: {
          'model': _model,
          'max_tokens': _maxTokens,
          'system': systemContent,
          'messages': messages,
        },
      );

      final data = response.data;
      final content = data['content'][0]['text'] as String;
      final parsed = parseActionFromContent(content);

      return AiResponse(
        text: parsed.cleanText,
        action: parsed.action,
        inputTokens: data['usage']?['input_tokens'] as int? ?? 0,
        outputTokens: data['usage']?['output_tokens'] as int? ?? 0,
      );
    } on DioException catch (e) {
      _logger.e('AI API Error: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw AiException('API kalit noto\'g\'ri. Iltimos, sozlamalarda tekshiring.');
      } else if (e.response?.statusCode == 429) {
        throw AiException('So\'rovlar limiti to\'ldi. Keyinroq urinib ko\'ring.');
      }
      throw AiException('Tarmoq xatosi. Internetni tekshiring.');
    } catch (e) {
      _logger.e('Unexpected error: $e');
      throw AiException('Kutilmagan xato yuz berdi.');
    }
  }

  Stream<String> sendMessageStream({
    required String message,
    List<Map<String, String>> conversationHistory = const [],
  }) async* {
    try {
      final messages = [
        ...conversationHistory,
        {'role': 'user', 'content': message},
      ];

      final response = await _dio.post(
        '/messages',
        data: {
          'model': _model,
          'max_tokens': _maxTokens,
          'system': _systemPrompt,
          'messages': messages,
          'stream': true,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') return;
            try {
              final parsed = jsonDecode(data);
              if (parsed['type'] == 'content_block_delta') {
                yield parsed['delta']['text'] as String? ?? '';
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      _logger.e('Stream error: $e');
    }
  }
}

/// Extracts an embedded `{"action": "...", "params": {...}}` JSON block from
/// an AI text response (if present) and returns the text with that block
/// stripped out. Pulled out as a pure top-level function so the parsing
/// logic can be unit-tested without the network layer.
ParsedAiContent parseActionFromContent(String content) {
  ActionCommand? action;
  final actionMatch = RegExp(r'\{"action":\s*"(\w+)".*?\}', dotAll: true).firstMatch(content);
  if (actionMatch != null) {
    try {
      final jsonStr = actionMatch.group(0)!;
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      action = ActionCommand(
        type: parsed['action'] as String,
        params: (parsed['params'] as Map<String, dynamic>?) ?? {},
      );
    } catch (_) {}
  }

  final cleanText =
      content.replaceAll(RegExp(r'\{"action".*?\}', dotAll: true), '').trim();

  return ParsedAiContent(cleanText: cleanText, action: action);
}

class ParsedAiContent {
  final String cleanText;
  final ActionCommand? action;

  const ParsedAiContent({required this.cleanText, this.action});
}

class AiResponse {
  final String text;
  final ActionCommand? action;
  final int inputTokens;
  final int outputTokens;

  const AiResponse({
    required this.text,
    this.action,
    required this.inputTokens,
    required this.outputTokens,
  });
}

class ActionCommand {
  final String type;
  final Map<String, dynamic> params;

  const ActionCommand({required this.type, required this.params});
}

class AiException implements Exception {
  final String message;
  AiException(this.message);

  @override
  String toString() => message;
}
