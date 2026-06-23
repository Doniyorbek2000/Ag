import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'action_executor.dart';

class QrService {
  /// Generate a QR code by opening a web-based QR generator
  Future<ActionResult> generateQr(String data) async {
    if (data.isEmpty) {
      return const ActionResult(success: false, message: 'QR kod uchun ma\'lumot kiriting');
    }
    // Use a free QR code API to show the QR image
    final uri = Uri.parse(
      'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(data)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ActionResult(
        success: true,
        message: '📱 QR kod yaratildi: "$data"',
        data: uri.toString(),
      );
    } catch (e) {
      return ActionResult(success: false, message: 'QR kod yaratishda xato');
    }
  }

  /// Open QR code scanner (uses Google Lens or default camera)
  Future<ActionResult> scanQr() async {
    // Try Google Lens first
    try {
      final lensIntent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.google.ar.lens',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await lensIntent.launch();
      return const ActionResult(success: true, message: '📷 QR skaner ochildi (Google Lens)');
    } catch (_) {}

    // Try generic barcode scanner
    try {
      final scanIntent = AndroidIntent(
        action: 'com.google.zxing.client.android.SCAN',
        arguments: {'SCAN_MODE': 'QR_CODE_MODE'},
      );
      await scanIntent.launch();
      return const ActionResult(success: true, message: '📷 QR skaner ochildi');
    } catch (_) {}

    // Fallback: open camera
    try {
      final cameraIntent = AndroidIntent(
        action: 'android.media.action.IMAGE_CAPTURE',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await cameraIntent.launch();
      return const ActionResult(success: true, message: '📷 Kamera ochildi — QR kodni ko\'rsating');
    } catch (e) {
      return const ActionResult(success: false, message: 'QR skaner ochishda xato');
    }
  }

  /// Generate a WiFi QR code
  Future<ActionResult> generateWifiQr({
    required String ssid,
    required String password,
    String encryption = 'WPA',
  }) async {
    final wifiString = 'WIFI:T:$encryption;S:$ssid;P:$password;;';
    return generateQr(wifiString);
  }

  /// Generate a vCard QR code
  Future<ActionResult> generateContactQr({
    required String name,
    String? phone,
    String? email,
  }) async {
    final vcard = StringBuffer('BEGIN:VCARD\nVERSION:3.0\nFN:$name\n');
    if (phone != null) vcard.write('TEL:$phone\n');
    if (email != null) vcard.write('EMAIL:$email\n');
    vcard.write('END:VCARD');
    return generateQr(vcard.toString());
  }
}
