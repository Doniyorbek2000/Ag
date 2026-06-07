import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AdmBackgroundService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _initNotifications();

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'adm_ai_service',
        initialNotificationTitle: 'ADM AI',
        initialNotificationContent: 'Ovozli yordamchi faol',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    service.on('voiceActivate').listen((event) {
      // Handle voice activation from background
    });
  }

  static Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    const androidChannel = AndroidNotificationChannel(
      'adm_ai_service',
      'ADM AI Xizmat',
      description: 'ADM AI yordamchi xizmati',
      importance: Importance.low,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'adm_ai_alerts',
      'ADM AI Bildirishnomalar',
      channelDescription: 'ADM AI muhim bildirishnomalar',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, details, payload: payload);
  }

  static Future<void> startVoiceService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopVoiceService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}
