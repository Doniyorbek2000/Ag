import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bridges Flutter to the native `AdmCallScreeningService`
/// (android/app/.../AdmCallScreeningService.kt), Android's real
/// `CallScreeningService` integration.
///
/// Android only allows ONE app to hold `ROLE_CALL_SCREENING`, and only the
/// system role picker can grant it — [requestRole] launches that system
/// dialog and the user must explicitly approve it. Once held, the native
/// service screens incoming calls using the rules written here.
///
/// Rules and the resulting log are stored as plain JSON strings in
/// SharedPreferences (the same store the `shared_preferences` plugin backs),
/// using `flutter.`-prefixed keys so the native side can read them without a
/// running Dart VM. See AdmCallScreeningService.kt for the matching keys.
class CallScreeningService {
  static const _channel = MethodChannel('com.admai.app/call_screening');

  static const _keyBlocked = 'adm_blocked_numbers_json';
  static const _keyQuietMode = 'adm_quiet_mode_enabled';
  static const _keyAllowContactsOnly = 'adm_allow_contacts_only';
  static const _keyKnownContacts = 'adm_known_contacts_json';
  static const _keyLog = 'adm_call_screening_log_json';

  static final CallScreeningService _instance = CallScreeningService._internal();
  factory CallScreeningService() => _instance;
  CallScreeningService._internal();

  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isRoleHeld() async {
    try {
      return await _channel.invokeMethod<bool>('isRoleHeld') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Launches the system role picker. Returns true once the role is granted
  /// (or already held); false if unsupported, unavailable, or declined.
  Future<bool> requestRole() async {
    try {
      return await _channel.invokeMethod<bool>('requestRole') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> getBlockedNumbers() => _readJsonList(_keyBlocked);

  Future<void> setBlockedNumbers(List<String> numbers) =>
      _writeJsonList(_keyBlocked, numbers);

  Future<void> blockNumber(String number) async {
    final numbers = await getBlockedNumbers();
    if (!numbers.contains(number)) {
      numbers.add(number);
      await setBlockedNumbers(numbers);
    }
  }

  Future<void> unblockNumber(String number) async {
    final numbers = await getBlockedNumbers();
    numbers.remove(number);
    await setBlockedNumbers(numbers);
  }

  Future<List<String>> getKnownContacts() => _readJsonList(_keyKnownContacts);

  Future<void> setKnownContacts(List<String> numbers) =>
      _writeJsonList(_keyKnownContacts, numbers);

  Future<bool> getQuietModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefixed(_keyQuietMode)) ?? false;
  }

  Future<void> setQuietModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefixed(_keyQuietMode), enabled);
  }

  Future<bool> getAllowContactsOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefixed(_keyAllowContactsOnly)) ?? false;
  }

  Future<void> setAllowContactsOnly(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefixed(_keyAllowContactsOnly), enabled);
  }

  /// Returns the screening decision log (most recent first), each entry
  /// shaped as `{number, decision, timestamp}` -- written natively by
  /// AdmCallScreeningService.appendLog().
  Future<List<Map<String, dynamic>>> getLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefixed(_keyLog));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _readJsonList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefixed(key));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeJsonList(String key, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefixed(key), jsonEncode(values));
  }

  String _prefixed(String key) => 'flutter.$key';
}
