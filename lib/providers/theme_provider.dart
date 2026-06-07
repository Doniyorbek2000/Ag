import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists the user's preferred [ThemeMode] (system / light / dark) in the
/// `settings` Hive box so the choice survives app restarts.
class ThemeModeController extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeModeController() : super(ThemeMode.dark) {
    _restore();
  }

  void _restore() {
    final box = Hive.box('settings');
    final stored = box.get(_key) as String?;
    state = _fromString(stored) ?? ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await Hive.box('settings').put(_key, _toString(mode));
  }

  static ThemeMode? _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});
