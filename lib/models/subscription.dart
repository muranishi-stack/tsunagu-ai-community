import 'package:flutter/material.dart';
import 'connection_category.dart';

/// 課金プランの種類
enum PlanType {
  freeTrial,    // 7日間無料トライアル
  allCategory,  // 全カテゴリ月額
  singleCategory, // 1カテゴリ月額
  boost,        // 24時間アプローチ強化（単発）
}

/// 決済方法
enum PaymentMethod {
  applePay,
  googlePay,
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.applePay:
        return Icons.apple;
      case PaymentMethod.googlePay:
        return Icons.account_balance_wallet;
    }
  }
}

/// 課金プラン定義
class SubscriptionPlan {
  final PlanType type;
  final String name;
  final String tagline;
  final int priceJpy;       // 円
  final int durationDays;   // 期間（日）
  final List<String> features;
  final bool isPopular;     // 人気プラン表示用

  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.tagline,
    required this.priceJpy,
    required this.durationDays,
    required this.features,
    this.isPopular = false,
  });

  /// 価格表示（¥4,800形式）
  String get priceLabel {
    if (priceJpy == 0) return '無料';
    return '¥${_formatNumber(priceJpy)}';
  }

  String get periodLabel {
    if (type == PlanType.boost) return '24時間';
    if (type == PlanType.freeTrial) return '7日間';
    return '30日間';
  }

  String get unitLabel {
    if (type == PlanType.boost) return '/ 回';
    if (type == PlanType.freeTrial) return '';
    return '/ 月';
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ===== プラン定義 =====

  static const SubscriptionPlan freeTrial = SubscriptionPlan(
    type: PlanType.freeTrial,
    name: 'お試しトライアル',
    tagline: '初回限定 · 全機能を体験',
    priceJpy: 0,
    durationDays: 7,
    features: [
      '全5カテゴリにアクセス',
      '無制限マッチング',
      'AIマッチング詳細スコア',
      '7日後に自動終了（自動課金なし）',
    ],
  );

  static const SubscriptionPlan allCategory = SubscriptionPlan(
    type: PlanType.allCategory,
    name: 'プレミアム（全カテゴリ）',
    tagline: 'すべての繋がりを、ひとつのアプリで',
    priceJpy: 4800,
    durationDays: 30,
    isPopular: true,
    features: [
      '5カテゴリすべて利用可能',
      '無制限マッチング',
      '優先表示で出会いやすく',
      'AI会話アシスタント無制限',
      '既読確認',
      'いつでもキャンセル可能',
    ],
  );

  static const SubscriptionPlan singleCategory = SubscriptionPlan(
    type: PlanType.singleCategory,
    name: 'シングル（1カテゴリ）',
    tagline: '目的に絞ってシンプルに',
    priceJpy: 1980,
    durationDays: 30,
    features: [
      '選択した1カテゴリで利用',
      '無制限マッチング',
      'AI会話アシスタント',
      'いつでもキャンセル可能',
    ],
  );

  static const SubscriptionPlan boost = SubscriptionPlan(
    type: PlanType.boost,
    name: 'アプローチ強化',
    tagline: '24時間、露出を最大化',
    priceJpy: 500,
    durationDays: 1,
    features: [
      '24時間プロフィール優先表示',
      '通常の最大10倍の露出',
      'カテゴリ内トップに表示',
      '繰り返し購入可能',
    ],
  );

  static List<SubscriptionPlan> get allPlans => [
        freeTrial,
        allCategory,
        singleCategory,
        boost,
      ];

  static List<SubscriptionPlan> get monthlyPlans => [
        allCategory,
        singleCategory,
      ];
}

/// アクティブなサブスクリプションの状態
class ActiveSubscription {
  final PlanType planType;
  final DateTime startDate;
  final DateTime expiryDate;
  final ConnectionCategory? selectedCategory; // singleCategoryプランの場合のみ
  final PaymentMethod? paymentMethod;

  const ActiveSubscription({
    required this.planType,
    required this.startDate,
    required this.expiryDate,
    this.selectedCategory,
    this.paymentMethod,
  });

  bool get isActive => DateTime.now().isBefore(expiryDate);

  int get daysRemaining {
    final diff = expiryDate.difference(DateTime.now());
    return diff.inDays.clamp(0, 999);
  }

  int get hoursRemaining {
    final diff = expiryDate.difference(DateTime.now());
    return diff.inHours.clamp(0, 999);
  }

  /// プラン名表示
  String get planName {
    switch (planType) {
      case PlanType.freeTrial:
        return SubscriptionPlan.freeTrial.name;
      case PlanType.allCategory:
        return SubscriptionPlan.allCategory.name;
      case PlanType.singleCategory:
        return SubscriptionPlan.singleCategory.name;
      case PlanType.boost:
        return SubscriptionPlan.boost.name;
    }
  }
}

/// アクティブなブースト（24時間限定）
class ActiveBoost {
  final DateTime startDate;
  final DateTime expiryDate;

  const ActiveBoost({
    required this.startDate,
    required this.expiryDate,
  });

  bool get isActive => DateTime.now().isBefore(expiryDate);

  Duration get remaining => expiryDate.difference(DateTime.now());

  /// "23時間45分" 形式の残り時間
  String get remainingLabel {
    final r = remaining;
    if (r.isNegative) return '終了';
    final h = r.inHours;
    final m = r.inMinutes.remainder(60);
    return '$h時間$m分';
  }
}
