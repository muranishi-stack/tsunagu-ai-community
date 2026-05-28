import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

/// 決済結果
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final PaymentMethod? method;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    this.method,
  });
}

/// 決済処理サービス
///
/// ※ 実装段階では以下のいずれかのパッケージを使用:
///   - `pay` (Apple Pay/Google Pay 共通)
///   - `in_app_purchase` (App Store/Play Billing)
///
/// 現状はモック実装（実機決済をシミュレート）
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// プラットフォームのデフォルト決済方法
  /// iOS → Apple Pay, Android/Web → Google Pay
  PaymentMethod get defaultMethod {
    if (kIsWeb) return PaymentMethod.googlePay;
    try {
      if (Platform.isIOS || Platform.isMacOS) return PaymentMethod.applePay;
    } catch (_) {
      // Web/未サポート環境
    }
    return PaymentMethod.googlePay;
  }

  /// 利用可能な決済方法を取得
  List<PaymentMethod> get availableMethods {
    if (kIsWeb) {
      return [PaymentMethod.googlePay];
    }
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        return [PaymentMethod.applePay];
      }
      if (Platform.isAndroid) {
        return [PaymentMethod.googlePay];
      }
    } catch (_) {}
    return [PaymentMethod.googlePay];
  }

  /// 決済を実行
  /// 実環境では `pay` パッケージで PaymentItem を作成し、
  /// Apple Pay / Google Pay のシートを呼び出す。
  Future<PaymentResult> processPayment({
    required SubscriptionPlan plan,
    required PaymentMethod method,
  }) async {
    // 決済処理シミュレーション（実環境ではplatform channel経由）
    await Future.delayed(const Duration(milliseconds: 1800));

    // 無料トライアルは決済不要
    if (plan.priceJpy == 0) {
      return PaymentResult(
        success: true,
        transactionId: 'free_${DateTime.now().millisecondsSinceEpoch}',
        method: method,
      );
    }

    // モック: 常に成功扱い（実環境ではplatform decisionに従う）
    return PaymentResult(
      success: true,
      transactionId:
          '${method.name}_${DateTime.now().millisecondsSinceEpoch}',
      method: method,
    );
  }

  /// 領収書バリデーション（実環境ではバックエンドで実施）
  Future<bool> validateReceipt(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
