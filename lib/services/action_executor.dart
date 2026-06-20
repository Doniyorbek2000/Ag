import 'package:android_intent_plus/android_intent.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'telegram_service.dart';
import 'whatsapp_service.dart';
import 'weather_service.dart';
import 'news_service.dart';
import 'unit_converter_service.dart';
import 'reminder_service.dart';

class ActionExecutor {
  final Logger _logger = Logger();

  static final ActionExecutor _instance = ActionExecutor._internal();
  factory ActionExecutor() => _instance;
  ActionExecutor._internal();

  Future<ActionResult> execute(String actionType, Map<String, dynamic> params) async {
    _logger.d('Executing action: $actionType with params: $params');

    switch (actionType) {
      case 'MAKE_CALL':
        return _makeCall(params['phone'] as String? ?? '');
      case 'SEND_SMS':
        return _sendSms(
          params['phone'] as String? ?? '',
          params['message'] as String? ?? '',
        );
      case 'OPEN_APP':
        return _openApp(params['app'] as String? ?? '');
      case 'PLAY_MUSIC':
        return _playMusic(params['query'] as String? ?? '');
      case 'SEARCH_WEB':
        return _searchWeb(params['query'] as String? ?? '');
      case 'SET_ALARM':
        return _setAlarm(
          params['time'] as String? ?? '',
          params['label'] as String? ?? 'ADM AI Eslatma',
        );
      case 'OPEN_SETTINGS':
        return _openSettings(params['section'] as String? ?? '');
      case 'SEND_TELEGRAM':
        return _sendTelegram(
          params['contact'] as String? ?? '',
          params['message'] as String? ?? '',
        );
      case 'SEND_WHATSAPP':
        return _sendWhatsApp(
          params['phone'] as String? ?? '',
          params['message'] as String? ?? '',
        );
      case 'SEARCH_YOUTUBE':
        return _searchYouTube(params['query'] as String? ?? '');
      case 'OPEN_CAMERA':
        return _openCamera();
      case 'OPEN_GALLERY':
        return _openGallery();
      case 'OPEN_MAPS':
        return _openMaps(params['location'] as String? ?? '');
      case 'GET_WEATHER':
        return _getWeather(params['city'] as String? ?? '');
      case 'GET_NEWS':
        return _getNews(params['topic'] as String?);
      case 'CONVERT_UNITS':
        return _convertUnits(params);
      case 'CREATE_EVENT':
        return _createCalendarEvent(params);
      case 'SEND_EMAIL':
        return _sendEmail(params);
      case 'SET_REMINDER':
        return _setReminder(params);
      case 'FIND_CONTACT':
        return _findContact(params['name'] as String? ?? '');
      default:
        return ActionResult(
          success: false,
          message: 'Noma\'lum buyruq: $actionType',
        );
    }
  }

  Future<ActionResult> _makeCall(String phone) async {
    final status = await Permission.phone.request();
    if (status.isDenied) {
      return ActionResult(
        success: false,
        message: 'Qo\'ng\'iroq ruxsati berilmagan',
      );
    }

    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      await FlutterPhoneDirectCaller.callNumber(cleaned);
      return ActionResult(success: true, message: '$cleaned ga qo\'ng\'iroq qilinmoqda');
    } catch (e) {
      final uri = Uri(scheme: 'tel', path: cleaned);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return ActionResult(success: true, message: 'Qo\'ng\'iroq qilinmoqda');
      }
      return ActionResult(success: false, message: 'Qo\'ng\'iroq qilishda xato');
    }
  }

  Future<ActionResult> _sendSms(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return ActionResult(success: true, message: 'SMS ilovasi ochildi');
    }
    return ActionResult(success: false, message: 'SMS yuborishda xato');
  }

  Future<ActionResult> _openApp(String appName) async {
    final packageMap = {
      'telegram': 'org.telegram.messenger',
      'whatsapp': 'com.whatsapp',
      'instagram': 'com.instagram.android',
      'youtube': 'com.google.android.youtube',
      'gmail': 'com.google.android.gm',
      'maps': 'com.google.android.apps.maps',
      'chrome': 'com.android.chrome',
      'camera': 'com.android.camera2',
      'calculator': 'com.android.calculator2',
      'spotify': 'com.spotify.music',
      'netflix': 'com.netflix.mediaclient',
      'facebook': 'com.facebook.katana',
      'twitter': 'com.twitter.android',
      'tiktok': 'com.zhiliaoapp.musically',
      'zoom': 'us.zoom.videomeetings',
      'calendar': 'com.google.android.calendar',
      'clock': 'com.google.android.deskclock',
      'notes': 'com.google.android.keep',
      'files': 'com.google.android.documentsui',
      'passwords': 'com.google.android.apps.authenticator2',
      'sheets': 'com.google.android.apps.docs.editors.sheets',
      'teams': 'com.microsoft.teams',
      'meet': 'com.google.android.apps.meetings',
      'skype': 'com.skype.raider',
      'radio': 'com.xiaomi.midrop',
      'drive': 'com.google.android.apps.docs',
      'photos': 'com.google.android.apps.photos',
      'dialer': 'com.google.android.dialer',
      'sms': 'com.google.android.apps.messaging',
      'gallery': 'com.google.android.apps.photos',
      'settings': 'com.android.settings',
    };

    final lowerName = appName.toLowerCase();
    String? packageName;

    for (final entry in packageMap.entries) {
      if (lowerName.contains(entry.key)) {
        packageName = entry.value;
        break;
      }
    }

    if (packageName != null) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: packageName,
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
        return ActionResult(success: true, message: '$appName ochildi');
      } catch (e) {
        final storeUrl = Uri.parse(
          'market://details?id=$packageName',
        );
        if (await canLaunchUrl(storeUrl)) {
          await launchUrl(storeUrl);
        }
        return ActionResult(
          success: false,
          message: '$appName topilmadi, Play Store ochildi',
        );
      }
    }

    return ActionResult(success: false, message: '$appName ilovasi topilmadi');
  }

  Future<ActionResult> _playMusic(String query) async {
    final spotifyUri = Uri.parse(
      'spotify:search:${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(spotifyUri)) {
      await launchUrl(spotifyUri);
      return ActionResult(success: true, message: 'Spotify\'da qidirilmoqda: $query');
    }

    final youtubeUri = Uri.parse(
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent("$query music")}',
    );
    await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: 'YouTube\'da musiqa qidirilmoqda');
  }

  Future<ActionResult> _searchWeb(String query) async {
    final uri = Uri.parse(
      'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ActionResult(success: true, message: 'Google\'da qidirilmoqda: $query');
  }

  Future<ActionResult> _setAlarm(String time, String label) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.SKIP_UI': true,
        'android.intent.extra.alarm.MESSAGE': label,
      },
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Uyg\'otgich sozlandi: $time - $label');
    } catch (e) {
      return ActionResult(success: false, message: 'Uyg\'otgich sozlashda xato');
    }
  }

  Future<ActionResult> _openSettings(String section) async {
    final settingsMap = {
      'wifi': 'android.settings.WIFI_SETTINGS',
      'bluetooth': 'android.settings.BLUETOOTH_SETTINGS',
      'sound': 'android.settings.SOUND_SETTINGS',
      'display': 'android.settings.DISPLAY_SETTINGS',
      'battery': 'android.settings.BATTERY_SAVER_SETTINGS',
      'storage': 'android.settings.INTERNAL_STORAGE_SETTINGS',
      'apps': 'android.settings.MANAGE_ALL_APPLICATIONS_SETTINGS',
      'location': 'android.settings.LOCATION_SOURCE_SETTINGS',
      'security': 'android.settings.SECURITY_SETTINGS',
      'language': 'android.settings.LOCALE_SETTINGS',
    };

    final lowerSection = section.toLowerCase();
    String action = 'android.settings.SETTINGS';

    for (final entry in settingsMap.entries) {
      if (lowerSection.contains(entry.key)) {
        action = entry.value;
        break;
      }
    }

    final intent = AndroidIntent(action: action);
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Sozlamalar ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Sozlamalar ochishda xato');
    }
  }

  Future<ActionResult> _sendTelegram(String contact, String message) async {
    final telegram = TelegramService();
    if (telegram.isConfigured && message.isNotEmpty) {
      try {
        await telegram.sendToContact(contact: contact, text: message);
        return ActionResult(
          success: true,
          message: '"$contact" ga Telegram orqali xabar yuborildi',
        );
      } on TelegramException catch (e) {
        _logger.w('Telegram avto-yuborish ishlamadi: $e');
        // Fall through to opening the app — bot can't reach this contact yet.
      }
    }

    final uri = Uri.parse('https://t.me/$contact');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(
        success: true,
        message: telegram.isConfigured
            ? 'Bu kontakt botga hali yozmagan, shuning uchun Telegram qo\'lda ochildi'
            : 'Telegram ochildi (avtomatik yuborish uchun Sozlamalar → Integratsiyalarda bot tokenini kiriting)',
      );
    }
    return ActionResult(success: false, message: 'Telegram topilmadi');
  }

  Future<ActionResult> _sendWhatsApp(String phone, String message) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    final whatsapp = WhatsAppService();

    if (await whatsapp.isConfigured && message.isNotEmpty) {
      try {
        await whatsapp.sendTextMessage(phone: cleaned, text: message);
        return ActionResult(
          success: true,
          message: '$cleaned ga WhatsApp orqali xabar yuborildi',
        );
      } on WhatsAppException catch (e) {
        _logger.w('WhatsApp avto-yuborish ishlamadi: $e');
        // Fall through to opening the app — likely outside the 24h window
        // or the recipient hasn't messaged the business number yet.
      }
    }

    final uri = Uri.parse(
      'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(
        success: true,
        message: await whatsapp.isConfigured
            ? 'Avtomatik yuborib bo\'lmadi (24 soatlik oyna yopiq), shuning uchun WhatsApp qo\'lda ochildi'
            : 'WhatsApp ochildi (avtomatik yuborish uchun Sozlamalar → Integratsiyalarda Business hisobni ulang)',
      );
    }
    return ActionResult(success: false, message: 'WhatsApp topilmadi');
  }

  Future<ActionResult> _searchYouTube(String query) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.SEARCH',
      package: 'com.google.android.youtube',
      arguments: {'query': query},
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'YouTube\'da qidirilmoqda: $query');
    } catch (e) {
      final uri = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(success: true, message: 'YouTube ochildi');
    }
  }

  Future<ActionResult> _openCamera() async {
    final intent = AndroidIntent(
      action: 'android.media.action.IMAGE_CAPTURE',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Kamera ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Kamera ochishda xato');
    }
  }

  Future<ActionResult> _openGallery() async {
    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      type: 'image/*',
      flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Galereya ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Galereya ochishda xato');
    }
  }

  Future<ActionResult> _getWeather(String city) async {
    if (city.isEmpty) {
      return ActionResult(success: false, message: 'Qaysi shahar uchun ob-havoni aytay?');
    }
    try {
      final info = await WeatherService().getCurrentWeather(city);
      return ActionResult(success: true, message: info.toSpokenSummary(), data: info);
    } on WeatherException catch (e) {
      return ActionResult(
        success: false,
        message: e.message.contains('sozlanmagan')
            ? 'Ob-havo ma\'lumotlari uchun Sozlamalar → Integratsiyalarda OpenWeatherMap API kalitini kiriting'
            : e.message,
      );
    }
  }

  Future<ActionResult> _getNews(String? topic) async {
    try {
      final articles = await NewsService().getTopHeadlines(topic: topic);
      if (articles.isEmpty) {
        return ActionResult(success: true, message: 'Hozircha yangiliklar topilmadi');
      }
      final summary = articles
          .take(5)
          .map((a) => '• ${a.title} (${a.source})')
          .join('\n');
      return ActionResult(
        success: true,
        message: 'So\'nggi yangiliklar:\n$summary',
        data: articles,
      );
    } on NewsException catch (e) {
      return ActionResult(
        success: false,
        message: e.message.contains('sozlanmagan')
            ? 'Yangiliklar uchun Sozlamalar → Integratsiyalarda GNews API kalitini kiriting'
            : e.message,
      );
    }
  }

  Future<ActionResult> _convertUnits(Map<String, dynamic> params) async {
    final rawValue = params['value'];
    final value = rawValue is num ? rawValue.toDouble() : double.tryParse(rawValue?.toString() ?? '');
    final from = params['from'] as String? ?? '';
    final to = params['to'] as String? ?? '';

    if (value == null || from.isEmpty || to.isEmpty) {
      return ActionResult(
        success: false,
        message: 'Aylantirish uchun qiymat va o\'lchov birliklarini ayting (masalan: 10 kilometrni milga aylantir)',
      );
    }

    try {
      final result = UnitConverter.convert(value: value, from: from, to: to);
      return ActionResult(
        success: true,
        message: '${_formatNumber(value)} $from = ${_formatNumber(result)} $to',
        data: result,
      );
    } on UnitConversionException catch (e) {
      return ActionResult(success: false, message: e.message);
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    final fixed = value.toStringAsFixed(4);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<ActionResult> _createCalendarEvent(Map<String, dynamic> params) async {
    final title = params['title'] as String? ?? '';
    if (title.isEmpty) {
      return const ActionResult(success: false, message: 'Tadbir nomini ayting');
    }

    final description = params['description'] as String? ?? '';
    final location = params['location'] as String? ?? '';
    final dateStr = params['date'] as String? ?? '';
    final timeStr = params['time'] as String? ?? '';

    var startTime = DateTime.now();
    if (dateStr.contains('ertaga') || dateStr.contains('tomorrow')) {
      startTime = startTime.add(const Duration(days: 1));
    } else if (dateStr.isNotEmpty && !dateStr.contains('bugun') && !dateStr.contains('today')) {
      startTime = DateTime.tryParse(dateStr) ?? startTime;
    }

    if (timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? startTime.hour;
        final minute = int.tryParse(parts[1]) ?? 0;
        startTime = DateTime(startTime.year, startTime.month, startTime.day, hour, minute);
      }
    }

    final beginMs = startTime.millisecondsSinceEpoch;
    final endMs = startTime.add(const Duration(hours: 1)).millisecondsSinceEpoch;

    final intent = AndroidIntent(
      action: 'android.intent.action.INSERT',
      data: 'content://com.android.calendar/events',
      arguments: {
        'title': title,
        'description': description,
        'eventLocation': location,
        'beginTime': beginMs,
        'endTime': endMs,
      },
    );

    try {
      await intent.launch();
      return ActionResult(success: true, message: 'Kalendarga qo\'shilmoqda: $title');
    } catch (e) {
      return ActionResult(success: false, message: 'Kalendar ochishda xato');
    }
  }

  Future<ActionResult> _sendEmail(Map<String, dynamic> params) async {
    final to = params['to'] as String? ?? '';
    final subject = params['subject'] as String? ?? '';
    final body = params['body'] as String? ?? '';

    if (to.isEmpty) {
      return const ActionResult(success: false, message: 'Email manzilini ayting');
    }

    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return ActionResult(success: true, message: '$to ga email tayyorlanmoqda');
    }
    return const ActionResult(success: false, message: 'Email ilovasi topilmadi');
  }

  Future<ActionResult> _setReminder(Map<String, dynamic> params) async {
    final title = params['title'] as String? ?? 'Eslatma';
    final message = params['message'] as String? ?? title;
    final timeStr = params['time'] as String? ?? '5';

    final minutes = int.tryParse(timeStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 5;

    final reminder = await ReminderService().add(
      title: title,
      message: message,
      minutesFromNow: minutes,
    );

    return ActionResult(
      success: true,
      message: '$minutes daqiqadan so\'ng eslatiladi: $title',
      data: reminder.id,
    );
  }

  Future<ActionResult> _findContact(String name) async {
    if (name.isEmpty) {
      return const ActionResult(success: false, message: 'Kontakt ismini ayting');
    }

    final status = await Permission.contacts.request();
    if (status.isDenied) {
      return const ActionResult(
        success: false,
        message: 'Kontaktlar ruxsati berilmagan',
      );
    }

    final contacts = await ContactsService.getContacts(
      query: name,
      withThumbnails: false,
    );

    if (contacts.isEmpty) {
      return ActionResult(
        success: false,
        message: '"$name" nomli kontakt topilmadi',
      );
    }

    final results = contacts.take(3).map((c) {
      final phone = c.phones?.firstOrNull?.value ?? 'raqam yo\'q';
      return '${c.displayName ?? "Nomsiz"}: $phone';
    }).join('\n');

    return ActionResult(
      success: true,
      message: 'Topilgan kontaktlar:\n$results',
      data: contacts.first.phones?.firstOrNull?.value,
    );
  }

  Future<ActionResult> _openMaps(String location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/${Uri.encodeComponent(location)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(success: true, message: 'Xaritada topilmoqda: $location');
    }
    return ActionResult(success: false, message: 'Xarita ochishda xato');
  }
}

class ActionResult {
  final bool success;
  final String message;
  final dynamic data;

  const ActionResult({
    required this.success,
    required this.message,
    this.data,
  });
}
