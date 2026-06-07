/// Recognizes a small set of common Uzbek voice/text commands that can be
/// fulfilled entirely on-device (opening apps, placing calls, sending SMS,
/// camera/gallery/maps/settings shortcuts) without calling the cloud AI.
///
/// This is the "offline mode" fallback: when there is no network connection
/// (so [AiService] can't be reached), [ChatNotifier] tries this parser
/// first. If it recognizes the phrase it executes the action directly via
/// [ActionExecutor]; otherwise the user is told the assistant needs an
/// internet connection for that request.
class OfflineCommandService {
  static const _knownApps = [
    'telegram', 'whatsapp', 'instagram', 'youtube', 'gmail', 'maps',
    'chrome', 'camera', 'calculator', 'spotify', 'netflix', 'facebook',
    'tiktok',
  ];

  static final _phoneRegex = RegExp(r'(\+?\d[\d\s\-]{6,}\d)');

  /// Returns a parsed offline-capable command, or null if the phrase needs
  /// the cloud AI (e.g. open-ended questions, web search, weather/news).
  static OfflineCommand? parse(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return null;

    final phoneMatch = _phoneRegex.firstMatch(text);
    if (phoneMatch != null &&
        (text.contains('qo\'ng\'iroq') ||
            text.contains('qongiroq') ||
            text.contains('chaqir') ||
            text.contains('call'))) {
      return OfflineCommand(
        type: 'MAKE_CALL',
        params: {'phone': phoneMatch.group(1)!.replaceAll(RegExp(r'\s|-'), '')},
        replyText: '${phoneMatch.group(1)} raqamiga qo\'ng\'iroq qilinmoqda...',
      );
    }

    if (phoneMatch != null &&
        (text.contains('sms') || text.contains('xabar yubor'))) {
      return OfflineCommand(
        type: 'SEND_SMS',
        params: {
          'phone': phoneMatch.group(1)!.replaceAll(RegExp(r'\s|-'), ''),
          'message': '',
        },
        replyText: 'SMS ilovasi ochilmoqda...',
      );
    }

    for (final app in _knownApps) {
      if (text.contains(app)) {
        final isOpenIntent = text.contains('och') ||
            text.contains('ishga tushir') ||
            text.contains('open');
        if (isOpenIntent) {
          return OfflineCommand(
            type: 'OPEN_APP',
            params: {'app': app},
            replyText: '$app ochilmoqda...',
          );
        }
      }
    }

    if (text.contains('kamera')) {
      return const OfflineCommand(
        type: 'OPEN_CAMERA',
        params: {},
        replyText: 'Kamera ochilmoqda...',
      );
    }

    if (text.contains('galere') || text.contains('rasmlar')) {
      return const OfflineCommand(
        type: 'OPEN_GALLERY',
        params: {},
        replyText: 'Galereya ochilmoqda...',
      );
    }

    if (text.contains('xarita') || text.contains('joylashuv') || text.contains('manzil')) {
      return const OfflineCommand(
        type: 'OPEN_MAPS',
        params: {'location': ''},
        replyText: 'Xaritalar ochilmoqda...',
      );
    }

    if (text.contains('sozlama')) {
      return const OfflineCommand(
        type: 'OPEN_SETTINGS',
        params: {'section': ''},
        replyText: 'Sozlamalar ochilmoqda...',
      );
    }

    return null;
  }
}

class OfflineCommand {
  final String type;
  final Map<String, dynamic> params;
  final String replyText;

  const OfflineCommand({
    required this.type,
    required this.params,
    required this.replyText,
  });
}
