// NotificationPreferences — 通知設定の永続化サービス
// =====================================================
// SharedPreferences にトグル状態を保存する ChangeNotifier シングルトン。
// ThemeService と同じパターン。
//
// TSUNAGU
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences extends ChangeNotifier {
  static final NotificationPreferences _instance =
      NotificationPreferences._internal();
  factory NotificationPreferences() => _instance;
  NotificationPreferences._internal();

  static const _kNewMatch = 'notif_new_match';
  static const _kNewMessage = 'notif_new_message';
  static const _kLikes = 'notif_likes';
  static const _kHighlights = 'notif_highlights';
  static const _kAnnouncements = 'notif_announcements';
  static const _kEmail = 'notif_email';

  bool newMatch = true;
  bool newMessage = true;
  bool likes = true;
  bool highlights = true;
  bool announcements = true;
  bool email = false;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 起動時に SharedPreferences から復元
  Future<void> init() async {
    if (_initialized) return;
    try {
      final p = await SharedPreferences.getInstance();
      newMatch = p.getBool(_kNewMatch) ?? true;
      newMessage = p.getBool(_kNewMessage) ?? true;
      likes = p.getBool(_kLikes) ?? true;
      highlights = p.getBool(_kHighlights) ?? true;
      announcements = p.getBool(_kAnnouncements) ?? true;
      email = p.getBool(_kEmail) ?? false;
    } catch (_) {
      // 失敗時はデフォルト値のまま
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _save(String key, bool value) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(key, value);
    } catch (_) {}
  }

  Future<void> setNewMatch(bool v) async {
    newMatch = v;
    notifyListeners();
    await _save(_kNewMatch, v);
  }

  Future<void> setNewMessage(bool v) async {
    newMessage = v;
    notifyListeners();
    await _save(_kNewMessage, v);
  }

  Future<void> setLikes(bool v) async {
    likes = v;
    notifyListeners();
    await _save(_kLikes, v);
  }

  Future<void> setHighlights(bool v) async {
    highlights = v;
    notifyListeners();
    await _save(_kHighlights, v);
  }

  Future<void> setAnnouncements(bool v) async {
    announcements = v;
    notifyListeners();
    await _save(_kAnnouncements, v);
  }

  Future<void> setEmail(bool v) async {
    email = v;
    notifyListeners();
    await _save(_kEmail, v);
  }
}
