// ThemeService — Light/Dark mode switcher with SharedPreferences persistence
// =====================================================
// Singleton ChangeNotifier. Listen with AnimatedBuilder or
// `service.addListener(rebuild)` in MaterialApp to apply themeMode.
//
// Phase 1.6 - TSUNAGU

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const _key = 'tsunagu_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _initialized;

  /// 起動時にSharedPreferencesから復元
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      _themeMode = _decode(saved);
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
    _initialized = true;
    notifyListeners();
  }

  /// テーマモードを変更して永続化
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _encode(mode));
    } catch (_) {
      // 永続化に失敗してもUIには反映済み
    }
  }

  /// ライト/ダークをトグル (system → light → dark → light ...)
  Future<void> toggle() async {
    switch (_themeMode) {
      case ThemeMode.system:
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  static String _encode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _decode(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// 現在のモードのラベル（UI表示用）
  String get currentLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'ライト';
      case ThemeMode.dark:
        return 'ダーク';
      case ThemeMode.system:
        return 'システム連動';
    }
  }
}
