import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sends messages directly via the official Telegram Bot API
/// (https://core.telegram.org/bots/api#sendmessage).
///
/// IMPORTANT: a bot can only message a chat that has *started a
/// conversation with it* (or a group/channel it was added to) — this is
/// a Telegram platform restriction, not a limitation of this code. There
/// is no way for any app (including Telegram's own clients) to push a
/// first message to an arbitrary user without their consent. So real
/// "send to anyone" automation requires:
///   1. The user creates their own bot via @BotFather and pastes the
///      token here (Settings → Integratsiyalar), and
///   2. The recipient has messaged that bot at least once (so we have
///      their numeric chat_id — fetched via getUpdates).
class TelegramService {
  static const _tokenKey = 'telegram_bot_token';
  static final TelegramService _instance = TelegramService._internal();
  factory TelegramService() => _instance;
  TelegramService._internal() : _dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
      ));

  final Dio _dio;
  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  bool get isConfigured => _token != null && _token!.isNotEmpty;

  String _apiUrl(String token, String method) => 'https://api.telegram.org/bot$token/$method';

  /// Returns chat_ids of users who have recently messaged the bot,
  /// keyed by their @username / first name — used to resolve a contact
  /// name spoken by the user into a chat_id we can message.
  Future<Map<String, int>> fetchKnownChats() async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    final res = await _dio.get(_apiUrl(t, 'getUpdates'), queryParameters: {'limit': 100});
    final updates = (res.data?['result'] as List?) ?? [];
    final chats = <String, int>{};

    for (final update in updates) {
      final chat = update['message']?['chat'] ?? update['channel_post']?['chat'];
      if (chat == null) continue;
      final id = chat['id'] as int?;
      if (id == null) continue;
      final username = chat['username'] as String?;
      final name = [chat['first_name'], chat['last_name']]
          .where((p) => p != null && (p as String).isNotEmpty)
          .join(' ');
      if (username != null) chats[username.toLowerCase()] = id;
      if (name.isNotEmpty) chats[name.toLowerCase()] = id;
    }
    return chats;
  }

  /// Sends a text message to [chatId] (numeric Telegram chat id).
  Future<void> sendMessage({required int chatId, required String text}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'sendMessage'), data: {
        'chat_id': chatId,
        'text': text,
      });
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Telegram orqali xabar yuborib bo\'lmadi');
    }
  }

  /// Resolves a spoken contact name/username to a chat_id and sends the
  /// message directly. Throws [TelegramException] if the contact hasn't
  /// messaged the bot yet (Telegram doesn't allow bots to find chat_ids
  /// any other way).
  Future<void> sendToContact({required String contact, required String text}) async {
    final chats = await fetchKnownChats();
    final key = contact.toLowerCase().replaceAll('@', '').trim();
    final chatId = chats[key];
    if (chatId == null) {
      throw TelegramException(
        '"$contact" hali botga yozmagan — Telegram bo\'tlar avval xabar yozmagan '
        'foydalanuvchilarga murojaat qila olmaydi',
      );
    }
    await sendMessage(chatId: chatId, text: text);
  }
}

class TelegramException implements Exception {
  final String message;
  TelegramException(this.message);
  @override
  String toString() => message;
}
