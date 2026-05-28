import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SuperLike機能の月別制限を管理するサービス
///
/// 仕様:
/// - 月5回まで送信可能
/// - 月初0時にリセット（YearMonthキーで管理）
/// - SharedPreferencesに残数とリセット月を永続化
class SuperLikeService extends ChangeNotifier {
  static final SuperLikeService _instance = SuperLikeService._internal();
  factory SuperLikeService() => _instance;
  SuperLikeService._internal();

  static const int monthlyQuota = 5;
  static const String _kRemainingKey = 'superlike_remaining';
  static const String _kMonthKey = 'superlike_period';

  int _remaining = monthlyQuota;
  bool _initialized = false;

  int get remaining => _remaining;
  int get used => monthlyQuota - _remaining;
  bool get canSend => _remaining > 0;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final storedPeriod = prefs.getString(_kMonthKey);

    if (storedPeriod != currentPeriod) {
      // 月が変わったらリセット
      _remaining = monthlyQuota;
      await prefs.setString(_kMonthKey, currentPeriod);
      await prefs.setInt(_kRemainingKey, _remaining);
    } else {
      _remaining = prefs.getInt(_kRemainingKey) ?? monthlyQuota;
    }
    _initialized = true;
    notifyListeners();
  }

  /// SuperLikeを1回消費する
  /// 戻り値: 消費成功なら true、残数0なら false
  Future<bool> consumeSuperLike() async {
    if (!_initialized) await initialize();
    if (_remaining <= 0) return false;
    _remaining -= 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRemainingKey, _remaining);
    notifyListeners();
    return true;
  }

  /// 開発・テスト用: リセット
  Future<void> resetForDebug() async {
    _remaining = monthlyQuota;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRemainingKey, _remaining);
    notifyListeners();
  }
}
