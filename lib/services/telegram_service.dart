import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'action_executor.dart';

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

  // ── NEW TELEGRAM BOT API METHODS ────────────────────────────────────────

  /// Returns bot info via getMe API.
  Future<ActionResult> getMyBotInfo() async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      final res = await _dio.get(_apiUrl(t, 'getMe'));
      final result = res.data?['result'];
      if (result == null) {
        return const ActionResult(success: false, message: 'Bot ma\'lumotlarini olishda xato');
      }
      final botName = result['first_name'] ?? 'Noma\'lum';
      final username = result['username'] ?? 'noma\'lum';
      final canJoinGroups = result['can_join_groups'] == true ? 'Ha' : 'Yo\'q';
      return ActionResult(
        success: true,
        message: 'Bot ma\'lumotlari:\n'
            '• Ism: $botName\n'
            '• Username: @$username\n'
            '• Guruhlarga qo\'shilishi mumkin: $canJoinGroups',
        data: result,
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Bot ma\'lumotlarini olishda xato yuz berdi');
    }
  }

  /// Gets recent messages sent to the bot via getUpdates.
  Future<ActionResult> getUnreadMessages({int limit = 10}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      final res = await _dio.get(_apiUrl(t, 'getUpdates'), queryParameters: {'limit': limit});
      final updates = (res.data?['result'] as List?) ?? [];

      if (updates.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Yangi xabarlar yo\'q',
        );
      }

      final messages = <String>[];
      for (final update in updates) {
        final msg = update['message'];
        if (msg == null) continue;
        final from = msg['from'];
        final senderName = [from?['first_name'], from?['last_name']]
            .where((p) => p != null && (p as String).isNotEmpty)
            .join(' ');
        final text = msg['text'] ?? '[matn yo\'q]';
        final date = msg['date'] as int?;
        final dateStr = date != null
            ? DateTime.fromMillisecondsSinceEpoch(date * 1000).toString().substring(0, 16)
            : 'noma\'lum';
        messages.add('• $senderName: $text ($dateStr)');
      }

      if (messages.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Yangi matnli xabarlar yo\'q',
        );
      }

      return ActionResult(
        success: true,
        message: 'So\'nggi xabarlar (${messages.length}):\n${messages.join('\n')}',
        data: updates,
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Xabarlarni olishda xato yuz berdi');
    }
  }

  /// Sends a photo by URL to a chat.
  Future<ActionResult> sendPhoto({required int chatId, required String photoUrl, String? caption}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'sendPhoto'), data: {
        'chat_id': chatId,
        'photo': photoUrl,
        if (caption != null) 'caption': caption,
      });
      return ActionResult(
        success: true,
        message: 'Rasm yuborildi${caption != null ? ' (izoh: $caption)' : ''}',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Rasm yuborishda xato yuz berdi');
    }
  }

  /// Sends a document by URL to a chat.
  Future<ActionResult> sendDocument({required int chatId, required String documentUrl, String? caption}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'sendDocument'), data: {
        'chat_id': chatId,
        'document': documentUrl,
        if (caption != null) 'caption': caption,
      });
      return ActionResult(
        success: true,
        message: 'Hujjat yuborildi${caption != null ? ' (izoh: $caption)' : ''}',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Hujjat yuborishda xato yuz berdi');
    }
  }

  /// Sends a location to a chat.
  Future<ActionResult> sendLocation({required int chatId, required double latitude, required double longitude}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'sendLocation'), data: {
        'chat_id': chatId,
        'latitude': latitude,
        'longitude': longitude,
      });
      return ActionResult(
        success: true,
        message: 'Joylashuv yuborildi ($latitude, $longitude)',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Joylashuv yuborishda xato yuz berdi');
    }
  }

  /// Sends a contact card to a chat.
  Future<ActionResult> sendContact({required int chatId, required String phone, required String firstName, String? lastName}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'sendContact'), data: {
        'chat_id': chatId,
        'phone_number': phone,
        'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      });
      return ActionResult(
        success: true,
        message: 'Kontakt yuborildi: $firstName ${lastName ?? ''} ($phone)',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Kontakt yuborishda xato yuz berdi');
    }
  }

  /// Forwards a message from one chat to another.
  Future<ActionResult> forwardMessage({required int fromChatId, required int toChatId, required int messageId}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'forwardMessage'), data: {
        'chat_id': toChatId,
        'from_chat_id': fromChatId,
        'message_id': messageId,
      });
      return ActionResult(
        success: true,
        message: 'Xabar muvaffaqiyatli yo\'naltirildi',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Xabarni yo\'naltirishda xato yuz berdi');
    }
  }

  /// Creates a poll in a chat.
  Future<ActionResult> sendPoll({required int chatId, required String question, required List<String> options}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    if (options.length < 2) {
      return const ActionResult(
        success: false,
        message: 'So\'rovnoma uchun kamida 2 ta variant kerak',
      );
    }

    try {
      await _dio.post(_apiUrl(t, 'sendPoll'), data: {
        'chat_id': chatId,
        'question': question,
        'options': options,
      });
      return ActionResult(
        success: true,
        message: 'So\'rovnoma yuborildi: $question (${options.length} ta variant)',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'So\'rovnoma yuborishda xato yuz berdi');
    }
  }

  /// Pins a message in a chat.
  Future<ActionResult> pinMessage({required int chatId, required int messageId}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'pinChatMessage'), data: {
        'chat_id': chatId,
        'message_id': messageId,
      });
      return const ActionResult(
        success: true,
        message: 'Xabar muvaffaqiyatli qadaldi',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Xabarni qadashda xato yuz berdi');
    }
  }

  /// Gets the member count of a group or channel.
  Future<ActionResult> getChatMemberCount(int chatId) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      final res = await _dio.get(_apiUrl(t, 'getChatMemberCount'), queryParameters: {
        'chat_id': chatId,
      });
      final count = res.data?['result'] ?? 0;
      return ActionResult(
        success: true,
        message: 'Guruh a\'zolari soni: $count',
        data: count,
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Guruh a\'zolari sonini olishda xato yuz berdi');
    }
  }

  /// Leaves a group or channel.
  Future<ActionResult> leaveChat(int chatId) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'leaveChat'), data: {
        'chat_id': chatId,
      });
      return const ActionResult(
        success: true,
        message: 'Guruhdan muvaffaqiyatli chiqildi',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Guruhdan chiqishda xato yuz berdi');
    }
  }

  /// Sends a sticker by emoji or file_id.
  Future<ActionResult> sendSticker({required int chatId, required String stickerEmoji}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      // If stickerEmoji looks like a file_id (long alphanumeric string), use it directly.
      // Otherwise, send the emoji as a sticker search hint — Telegram accepts emoji
      // strings as sticker identifiers in some contexts, but for reliability we
      // pass it as the sticker parameter directly.
      await _dio.post(_apiUrl(t, 'sendSticker'), data: {
        'chat_id': chatId,
        'sticker': stickerEmoji,
      });
      return ActionResult(
        success: true,
        message: 'Stiker yuborildi',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Stiker yuborishda xato yuz berdi');
    }
  }

  /// Deletes a message from a chat.
  Future<ActionResult> deleteMessage({required int chatId, required int messageId}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'deleteMessage'), data: {
        'chat_id': chatId,
        'message_id': messageId,
      });
      return const ActionResult(
        success: true,
        message: 'Xabar muvaffaqiyatli o\'chirildi',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Xabarni o\'chirishda xato yuz berdi');
    }
  }

  /// Edits a previously sent message.
  Future<ActionResult> editMessage({required int chatId, required int messageId, required String newText}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'editMessageText'), data: {
        'chat_id': chatId,
        'message_id': messageId,
        'text': newText,
      });
      return const ActionResult(
        success: true,
        message: 'Xabar muvaffaqiyatli tahrirlandi',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Xabarni tahrirlashda xato yuz berdi');
    }
  }

  /// Sends a voice note by URL.
  Future<ActionResult> sendVoiceNote({required int chatId, required String voiceUrl}) async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      await _dio.post(_apiUrl(t, 'sendVoice'), data: {
        'chat_id': chatId,
        'voice': voiceUrl,
      });
      return const ActionResult(
        success: true,
        message: 'Ovozli xabar yuborildi',
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Ovozli xabar yuborishda xato yuz berdi');
    }
  }

  /// Returns a formatted list of all users who have messaged the bot.
  Future<ActionResult> getKnownChatsList() async {
    final t = await token;
    if (t == null) throw TelegramException('Bot token sozlanmagan');

    try {
      final chats = await fetchKnownChats();
      if (chats.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Hozircha botga hech kim yozmagan. Foydalanuvchilar botga /start yuborishi kerak.',
        );
      }

      // Deduplicate: group by chat_id so each user appears once
      final seen = <int, String>{};
      for (final entry in chats.entries) {
        final id = entry.value;
        if (!seen.containsKey(id)) {
          seen[id] = entry.key;
        }
      }

      final lines = seen.entries
          .map((e) => '• ${e.value}: ${e.key}')
          .toList();

      return ActionResult(
        success: true,
        message: 'Botga yozgan foydalanuvchilar (${lines.length}):\n${lines.join('\n')}',
        data: chats,
      );
    } on DioException catch (e) {
      final desc = e.response?.data is Map ? e.response?.data['description'] : null;
      throw TelegramException(desc ?? 'Foydalanuvchilar ro\'yxatini olishda xato yuz berdi');
    }
  }
}

class TelegramException implements Exception {
  final String message;
  TelegramException(this.message);
  @override
  String toString() => message;
}
