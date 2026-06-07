import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sends messages directly via the official WhatsApp Cloud API
/// (Meta Graph API — https://developers.facebook.com/docs/whatsapp/cloud-api).
///
/// IMPORTANT: WhatsApp does not allow ordinary consumer accounts to send
/// automated messages — only verified WhatsApp Business accounts with a
/// Meta-issued phone number ID and access token can. There is also a
/// 24-hour customer-service window: outside it, only pre-approved
/// message templates can be sent to a user, not free-form text. None of
/// this can be bypassed — it's enforced by Meta's servers. So real
/// "send to anyone" automation requires the user to register their own
/// WhatsApp Business number and paste its credentials in
/// Settings → Integratsiyalar.
class WhatsAppService {
  static const _phoneNumberIdKey = 'whatsapp_phone_number_id';
  static const _accessTokenKey = 'whatsapp_access_token';

  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal() : _dio = Dio(BaseOptions(
        baseUrl: 'https://graph.facebook.com/v20.0',
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
      ));

  final Dio _dio;
  String? _phoneNumberId;
  String? _accessToken;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _phoneNumberId = prefs.getString(_phoneNumberIdKey);
    _accessToken = prefs.getString(_accessTokenKey);
  }

  Future<bool> get isConfigured async {
    if (_phoneNumberId == null || _accessToken == null) await _restore();
    return (_phoneNumberId?.isNotEmpty ?? false) && (_accessToken?.isNotEmpty ?? false);
  }

  Future<void> setCredentials({String? phoneNumberId, String? accessToken}) async {
    final prefs = await SharedPreferences.getInstance();
    _phoneNumberId = phoneNumberId;
    _accessToken = accessToken;

    if (phoneNumberId == null || phoneNumberId.isEmpty) {
      await prefs.remove(_phoneNumberIdKey);
    } else {
      await prefs.setString(_phoneNumberIdKey, phoneNumberId);
    }
    if (accessToken == null || accessToken.isEmpty) {
      await prefs.remove(_accessTokenKey);
    } else {
      await prefs.setString(_accessTokenKey, accessToken);
    }
  }

  /// Sends a free-form text message to [phone] (E.164, e.g. "998901234567").
  /// Only works if the recipient messaged this business number within the
  /// last 24 hours — otherwise Meta requires a pre-approved template
  /// (see [sendTemplate]).
  Future<void> sendTextMessage({required String phone, required String text}) async {
    if (!await isConfigured) {
      throw WhatsAppException('WhatsApp Business hisobi sozlanmagan');
    }
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    try {
      await _dio.post(
        '/$_phoneNumberId/messages',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
        data: {
          'messaging_product': 'whatsapp',
          'to': cleaned,
          'type': 'text',
          'text': {'body': text},
        },
      );
    } on DioException catch (e) {
      final err = e.response?.data is Map ? e.response?.data['error']?['message'] : null;
      throw WhatsAppException(err ?? 'WhatsApp orqali xabar yuborib bo\'lmadi');
    }
  }

  /// Sends a pre-approved message template — required when the 24-hour
  /// customer-service window with the recipient is closed.
  Future<void> sendTemplate({
    required String phone,
    required String templateName,
    String languageCode = 'uz',
    List<String> parameters = const [],
  }) async {
    if (!await isConfigured) {
      throw WhatsAppException('WhatsApp Business hisobi sozlanmagan');
    }
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    try {
      await _dio.post(
        '/$_phoneNumberId/messages',
        options: Options(headers: {'Authorization': 'Bearer $_accessToken'}),
        data: {
          'messaging_product': 'whatsapp',
          'to': cleaned,
          'type': 'template',
          'template': {
            'name': templateName,
            'language': {'code': languageCode},
            if (parameters.isNotEmpty)
              'components': [
                {
                  'type': 'body',
                  'parameters': parameters.map((p) => {'type': 'text', 'text': p}).toList(),
                }
              ],
          },
        },
      );
    } on DioException catch (e) {
      final err = e.response?.data is Map ? e.response?.data['error']?['message'] : null;
      throw WhatsAppException(err ?? 'Shablon xabarini yuborib bo\'lmadi');
    }
  }
}

class WhatsAppException implements Exception {
  final String message;
  WhatsAppException(this.message);
  @override
  String toString() => message;
}
