import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../models/connection_category.dart';

/// 課金状態管理サービス
///
/// ※ 実環境ではShared Preferences/Firestoreに永続化、
///   App Store / Google Play Billing と連携する設計に拡張可能。
///   現状はメモリ保持の Mock 実装。
class SubscriptionService extends ChangeNotifier {
  // シングルトン
  static final SubscriptionService _instance =
      SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  ActiveSubscription? _activeSubscription;
  ActiveBoost? _activeBoost;
  bool _hasUsedFreeTrial = false;

  // ===== Getters =====

  ActiveSubscription? get activeSubscription =>
      _activeSubscription?.isActive == true ? _activeSubscription : null;

  ActiveBoost? get activeBoost =>
      _activeBoost?.isActive == true ? _activeBoost : null;

  bool get hasUsedFreeTrial => _hasUsedFreeTrial;

  bool get hasActivePremium => activeSubscription != null;

  /// メインカテゴリを自由に変更できるか。
  /// - 無料 / トライアル / 全カテゴリ(プレミアム) → true
  /// - シングルプラン → false（契約時に選んだ1カテゴリに固定）
  bool get canChangePrimaryCategory =>
      activeSubscription?.planType != PlanType.singleCategory;

  /// シングルプランで固定されているメインカテゴリ。それ以外は null。
  ConnectionCategory? get lockedPrimaryCategory {
    final sub = activeSubscription;
    if (sub != null && sub.planType == PlanType.singleCategory) {
      return sub.selectedCategory;
    }
    return null;
  }

  /// 指定カテゴリにアクセス可能か
  bool canAccessCategory(ConnectionCategory category) {
    final sub = activeSubscription;
    if (sub == null) return false;
    switch (sub.planType) {
      case PlanType.freeTrial:
      case PlanType.allCategory:
        return true;
      case PlanType.singleCategory:
        return sub.selectedCategory == category;
      case PlanType.boost:
        return false; // boost単体ではプレミアム機能は付与されない
    }
  }

  /// 現在のプランバッジ表示テキスト
  String get currentPlanBadge {
    final sub = activeSubscription;
    if (sub == null) return 'FREE';
    switch (sub.planType) {
      case PlanType.freeTrial:
        return 'TRIAL';
      case PlanType.allCategory:
        return 'PREMIUM';
      case PlanType.singleCategory:
        return 'SINGLE';
      case PlanType.boost:
        return 'FREE';
    }
  }

  // ===== サブスクリプション操作 =====

  /// 無料トライアル開始
  /// 戻り値：成功した場合 true。すでに使用済みなら false。
  bool startFreeTrial() {
    if (_hasUsedFreeTrial) return false;
    final now = DateTime.now();
    _activeSubscription = ActiveSubscription(
      planType: PlanType.freeTrial,
      startDate: now,
      expiryDate: now.add(const Duration(days: 7)),
    );
    _hasUsedFreeTrial = true;
    notifyListeners();
    return true;
  }

  /// プラン購入を確定
  void activateSubscription({
    required PlanType planType,
    required PaymentMethod paymentMethod,
    ConnectionCategory? selectedCategory,
  }) {
    final now = DateTime.now();
    final plan = _planFor(planType);
    _activeSubscription = ActiveSubscription(
      planType: planType,
      startDate: now,
      expiryDate: now.add(Duration(days: plan.durationDays)),
      selectedCategory: selectedCategory,
      paymentMethod: paymentMethod,
    );
    notifyListeners();
  }

  /// ブースト購入を確定
  void activateBoost({required PaymentMethod paymentMethod}) {
    final now = DateTime.now();
    _activeBoost = ActiveBoost(
      startDate: now,
      expiryDate: now.add(const Duration(hours: 24)),
    );
    notifyListeners();
  }

  /// サブスクリプションキャンセル
  void cancelSubscription() {
    _activeSubscription = null;
    notifyListeners();
  }

  // ===== AIスコアオプション（月額580円） =====
  // レコメンド（本日のAI TOP10）と AIマッチ度表示を解放する有料アドオン。
  // 現状は SharedPreferences 永続のモック。将来 IAP と連携する。

  static const int aiScorePriceJpy = 580;
  static const _kAiScoreExpiry = 'sub_ai_score_expiry';
  DateTime? _aiScoreExpiry;

  /// AIスコアオプションが有効か
  bool get hasAiScoreOption =>
      _aiScoreExpiry != null && DateTime.now().isBefore(_aiScoreExpiry!);

  DateTime? get aiScoreExpiry => _aiScoreExpiry;

  /// 起動時に永続化された状態を復元
  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      final ms = p.getInt(_kAiScoreExpiry);
      if (ms != null) {
        _aiScoreExpiry = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {}
    notifyListeners();
  }

  /// AIスコアオプションを購入（30日間有効）
  Future<void> subscribeAiScore() async {
    _aiScoreExpiry = DateTime.now().add(const Duration(days: 30));
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kAiScoreExpiry, _aiScoreExpiry!.millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// AIスコアオプションを解約
  Future<void> cancelAiScore() async {
    _aiScoreExpiry = null;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kAiScoreExpiry);
    } catch (_) {}
  }

  // ===== ヘルパー =====

  SubscriptionPlan _planFor(PlanType type) {
    switch (type) {
      case PlanType.freeTrial:
        return SubscriptionPlan.freeTrial;
      case PlanType.allCategory:
        return SubscriptionPlan.allCategory;
      case PlanType.singleCategory:
        return SubscriptionPlan.singleCategory;
      case PlanType.boost:
        return SubscriptionPlan.boost;
    }
  }
}
