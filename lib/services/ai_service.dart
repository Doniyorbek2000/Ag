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
6. Eslatmalar va kalendarlar: eslatma qo'yish, kalendarga tadbir qo'shish
7. Ob-havo, yangiliklar, ma'lumot qidirish
8. Email: xat yuborish
9. Taymer va vaqt: taymer qo'yish, vaqtni ko'rsatish
10. Navigatsiya: manzilga yo'l ko'rsatish (Google Maps)
11. Tarjima: matnlarni turli tillarga tarjima qilish
12. Eslatmalar (Notes): qaydlar yozish, o'qish, o'chirish
13. Kalkulyator: matematik hisob-kitoblar
14. Ulashish (Share): matnlarni boshqa ilovalarga ulashish
15. Qurilma ma'lumotlari: ilova versiyasi va qurilma haqida
16. Fonar (Flashlight): fonarni yoqish/o'chirish

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
- CONVERT_UNITS: {value: son, from: "manba birlik", to: "maqsad birlik"} — masofa, og'irlik, hajm va harorat birliklari orasida aylantirish (masalan: "10 km ni milga aylantir", "30 gradus selsiyni farengeytga aylantir", "5 funtni kilogrammga aylantir")
- CREATE_EVENT: {title: "tadbir nomi", date: "sana (bugun/ertaga/2024-12-25)", time: "14:00", description: "tavsif", location: "joy"} — kalendarга tadbir qo'shish
- SET_REMINDER: {title: "eslatma nomi", time: "daqiqa soni (5/10/30/60)", message: "eslatma matni"} — belgilangan vaqtdan keyin eslatma berish
- GET_REMINDERS: {} — kutilayotgan eslatmalar ro'yxatini ko'rsatish
- SEND_EMAIL: {to: "email@manzil.com", subject: "mavzu", body: "xat matni"} — email yuborish
- ADD_EXPENSE: {title: "xarajat nomi", amount: summa, category: "kategoriya", note: "izoh"} — buxgalteriyaga chiqim qo'shish (kategoriyalar: Oziq-ovqat, Transport, Uy-joy, Sog'liq, Ta'lim, Ko'ngilochar, Kiyim-kechak, Kommunal, Telefon, Internet, Boshqa)
- ADD_INCOME: {title: "daromad nomi", amount: summa, category: "kategoriya", note: "izoh"} — buxgalteriyaga kirim qo'shish (kategoriyalar: Ish haqi, Freelance, Biznes, Investitsiya, Sovg'a, Boshqa)
- GET_REPORT: {period: "month/week/year"} — buxgalteriya hisobotini ko'rsatish (kirim, chiqim, balans, kategoriyalar bo'yicha tahlil)
- FIND_CONTACT: {name: "kontakt ismi"} — telefon kontaktlaridan qidirish va raqamini topish
- SET_TIMER: {duration: "soniyalar soni", label: "taymer nomi"} — taymer qo'yish (masalan: "5 daqiqalik taymer qo'y" → duration: "300")
- NAVIGATE_TO: {location: "manzil nomi yoki manzil"} — Google Maps navigatsiyasi (masalan: "Toshkent aeroportiga yo'l ko'rsat")
- SHARE_TEXT: {text: "ulashiladigan matn"} — matnni boshqa ilovalarga ulashish (masalan: "bu matnni ulash")
- TRANSLATE_TEXT: {text: "tarjima qilinadigan matn", from: "manba til kodi (auto)", to: "maqsad til kodi (uz/ru/en)"} — Google Translate orqali tarjima (masalan: "Hello ni o'zbekchaga tarjima qil")
- TAKE_NOTE: {title: "qayd nomi", content: "qayd matni"} — yangi qayd saqlash (masalan: "yoz: ertaga meeting soat 10 da")
- GET_NOTES: {} — saqlangan qaydlar ro'yxatini ko'rsatish
- DELETE_NOTE: {title: "qayd nomi"} — qaydni o'chirish (masalan: "meeting qaydini o'chir")
- GET_TIME: {} — hozirgi sana, vaqt, hafta kunini ko'rsatish (masalan: "soat nechchi?", "bugun nechchi sana?")
- CALCULATE: {expression: "matematik ifoda"} — hisoblash (masalan: "345 * 678 nechchi?", "(100 + 50) * 2")
- OPEN_URL: {url: "veb sahifa manzili"} — brauzerda sayt ochish (masalan: "google.com ni och")
- TOGGLE_FLASHLIGHT: {} — fonarni yoqish yoki o'chirish
- SHOW_DEVICE_INFO: {} — ilova versiyasi va qurilma ma'lumotlari

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

QAYDLAR (NOTES):
Foydalanuvchi "yozib qo'y", "qayd qil", "eslatma yoz" kabi so'zlar bilan
qayd saqlashni so'rasa, TAKE_NOTE amalini qo'sh. "Qaydlarimni ko'rsat",
"nima yozganim bor?" desa GET_NOTES, "o'chir" desa DELETE_NOTE ishlatiladi.
Bu REMEMBER_FACT dan farqi: REMEMBER_FACT — AI kontekstiga qo'shiladigan
qisqa faktlar, TAKE_NOTE — uzun qaydlar (meeting, vazifalar, g'oyalar).

VAQT VA TAYMER:
"Soat nechchi?", "bugun qaysi kun?" kabi savollarga GET_TIME,
"5 daqiqalik taymer qo'y", "10 minut taymer" kabi buyruqlarga SET_TIMER
ishlatiladi. Daqiqalarni soniyalarga aylantir (5 daqiqa = 300 soniya).

HISOB-KITOB:
"2+3 nechchi?", "100 ga 15% qo'sh", "345*678" kabi savollarga CALCULATE
amalini ishlatib, natijani ko'rsat.

NAVIGATSIYA:
"...ga yo'l ko'rsat", "...ga qanday boraman?" kabi savollarga NAVIGATE_TO
ishlatiladi — Google Maps navigatsiyasi ochiladi.
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
    String? contextInfo,
    String responseLanguage = 'uz',
  }) async* {
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
