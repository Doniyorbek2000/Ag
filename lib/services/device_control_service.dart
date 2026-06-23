import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'action_executor.dart';

class DeviceControlService {
  // Open specific settings screens (different from OPEN_SETTINGS which handles generic sections)
  Future<ActionResult> openWifiSettings() async {
    return _launchSettings('android.settings.WIFI_SETTINGS', 'WiFi');
  }

  Future<ActionResult> openBluetoothSettings() async {
    return _launchSettings('android.settings.BLUETOOTH_SETTINGS', 'Bluetooth');
  }

  Future<ActionResult> openDndSettings() async {
    return _launchSettings('android.settings.ZEN_MODE_SETTINGS', 'Bezovta qilmang rejimi');
  }

  Future<ActionResult> openAirplaneSettings() async {
    return _launchSettings('android.settings.AIRPLANE_MODE_SETTINGS', 'Samolyot rejimi');
  }

  Future<ActionResult> openBrightnessSettings() async {
    return _launchSettings('android.settings.DISPLAY_SETTINGS', 'Ekran yorqinligi');
  }

  Future<ActionResult> openNotificationSettings() async {
    return _launchSettings('android.settings.NOTIFICATION_LISTENER_SETTINGS', 'Bildirishnomalar');
  }

  Future<ActionResult> openBatterySettings() async {
    return _launchSettings('android.settings.BATTERY_SAVER_SETTINGS', 'Batareya');
  }

  Future<ActionResult> openStorageSettings() async {
    return _launchSettings('android.settings.INTERNAL_STORAGE_SETTINGS', 'Xotira');
  }

  Future<ActionResult> openNfcSettings() async {
    return _launchSettings('android.settings.NFC_SETTINGS', 'NFC');
  }

  Future<ActionResult> openDeveloperSettings() async {
    return _launchSettings('android.settings.APPLICATION_DEVELOPMENT_SETTINGS', 'Dasturchi');
  }

  Future<ActionResult> openAccessibilitySettings() async {
    return _launchSettings('android.settings.ACCESSIBILITY_SETTINGS', 'Maxsus imkoniyatlar');
  }

  Future<ActionResult> openDateTimeSettings() async {
    return _launchSettings('android.settings.DATE_SETTINGS', 'Sana va vaqt');
  }

  Future<ActionResult> openAccountSettings() async {
    return _launchSettings('android.settings.SYNC_SETTINGS', 'Akkauntlar');
  }

  Future<ActionResult> openLocationSettings() async {
    return _launchSettings('android.settings.LOCATION_SOURCE_SETTINGS', 'Joylashuv');
  }

  Future<ActionResult> openSecuritySettings() async {
    return _launchSettings('android.settings.SECURITY_SETTINGS', 'Xavfsizlik');
  }

  Future<ActionResult> openLanguageSettings() async {
    return _launchSettings('android.settings.LOCALE_SETTINGS', 'Til');
  }

  Future<ActionResult> openSoundSettings() async {
    return _launchSettings('android.settings.SOUND_SETTINGS', 'Ovoz');
  }

  Future<ActionResult> openHotspotSettings() async {
    return _launchSettings('android.settings.TETHER_SETTINGS', 'Hotspot');
  }

  Future<ActionResult> openVpnSettings() async {
    return _launchSettings('android.settings.VPN_SETTINGS', 'VPN');
  }

  Future<ActionResult> openDataUsageSettings() async {
    return _launchSettings('android.settings.DATA_USAGE_SETTINGS', 'Data sarfi');
  }

  // Open app info page for a specific app
  Future<ActionResult> openAppInfo(String packageName) async {
    try {
      final intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:$packageName',
      );
      await intent.launch();
      return ActionResult(success: true, message: '$packageName haqida ma\'lumot ochildi');
    } catch (e) {
      return ActionResult(success: false, message: 'Ilova ma\'lumotini ochishda xato');
    }
  }

  // Uninstall app
  Future<ActionResult> uninstallApp(String packageName) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.DELETE',
        data: 'package:$packageName',
      );
      await intent.launch();
      return ActionResult(success: true, message: '$packageName o\'chirish so\'raldi');
    } catch (e) {
      return ActionResult(success: false, message: 'Ilovani o\'chirishda xato');
    }
  }

  // Copy text to clipboard
  Future<ActionResult> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    return ActionResult(success: true, message: '📋 Nusxa olindi (${text.length} belgi)');
  }

  // Read clipboard content
  Future<ActionResult> readClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) {
      return const ActionResult(success: true, message: 'Bufer bo\'sh');
    }
    return ActionResult(success: true, message: '📋 Bufer: ${data.text}');
  }

  // Dial USSD code
  Future<ActionResult> dialUssd(String code) async {
    final encoded = Uri.encodeComponent(code);
    final uri = Uri.parse('tel:$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return ActionResult(success: true, message: 'USSD: $code');
    }
    return const ActionResult(success: false, message: 'USSD kodni terishda xato');
  }

  // Open Play Store for an app
  Future<ActionResult> openPlayStore(String packageName) async {
    final uri = Uri.parse('market://details?id=$packageName');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return ActionResult(success: true, message: 'Play Store ochildi');
      }
      final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return ActionResult(success: true, message: 'Play Store ochildi');
    } catch (e) {
      return const ActionResult(success: false, message: 'Play Store ochishda xato');
    }
  }

  // Open a speed test website
  Future<ActionResult> speedTest() async {
    final uri = Uri.parse('https://fast.com');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return const ActionResult(success: true, message: '🌐 Internet tezlik testi ochildi');
  }

  // Private helper for settings
  Future<ActionResult> _launchSettings(String action, String label) async {
    try {
      final intent = AndroidIntent(action: action);
      await intent.launch();
      return ActionResult(success: true, message: '$label sozlamalari ochildi');
    } catch (e) {
      return ActionResult(success: false, message: '$label sozlamalarini ochishda xato');
    }
  }
}
