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
    'twitter', 'tiktok', 'zoom', 'calendar', 'clock', 'notes', 'files',
    'sheets', 'teams', 'meet', 'skype', 'drive', 'photos', 'dialer',
    'sms', 'gallery', 'settings',
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

    if (text.contains('uyg\'otgich') ||
        text.contains('budilnik') ||
        text.contains('alarm')) {
      final timeMatch = RegExp(r'(\d{1,2})[:\s](\d{2})').firstMatch(text);
      final time = timeMatch != null
          ? '${timeMatch.group(1)}:${timeMatch.group(2)}'
          : '';
      return OfflineCommand(
        type: 'SET_ALARM',
        params: {'time': time, 'label': 'ADM AI Eslatma'},
        replyText: 'Uyg\'otgich sozlanmoqda...',
      );
    }

    if (text.contains('eslatma') ||
        text.contains('eslat') ||
        text.contains('remind')) {
      final minuteMatch = RegExp(r'(\d+)\s*(minut|min|daqiqa|soat|hour)').firstMatch(text);
      var minutes = 5;
      if (minuteMatch != null) {
        minutes = int.tryParse(minuteMatch.group(1) ?? '') ?? 5;
        final unit = minuteMatch.group(2) ?? '';
        if (unit.contains('soat') || unit.contains('hour')) {
          minutes *= 60;
        }
      }
      return OfflineCommand(
        type: 'SET_REMINDER',
        params: {'title': rawText.trim(), 'message': rawText.trim(), 'time': '$minutes'},
        replyText: '$minutes daqiqadan so\'ng eslatiladi...',
      );
    }

    if (text.contains('musiqa') ||
        text.contains('qo\'shiq') ||
        text.contains('music')) {
      return OfflineCommand(
        type: 'OPEN_APP',
        params: {'app': 'spotify'},
        replyText: 'Musiqa ilovasi ochilmoqda...',
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
