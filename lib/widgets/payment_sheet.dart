import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../models/connection_category.dart';
import '../services/payment_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

/// 決済確認・実行ボトムシート
class PaymentSheet extends StatefulWidget {
  final SubscriptionPlan plan;
  final ConnectionCategory? selectedCategory; // singleCategoryプランの場合

  const PaymentSheet({
    super.key,
    required this.plan,
    this.selectedCategory,
  });

  static Future<bool?> show(
    BuildContext context, {
    required SubscriptionPlan plan,
    ConnectionCategory? selectedCategory,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PaymentSheet(
        plan: plan,
        selectedCategory: selectedCategory,
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  late PaymentMethod _selectedMethod;
  bool _processing = false;
  bool _completed = false;

  final _paymentService = PaymentService();
  final _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _selectedMethod = _paymentService.defaultMethod;
  }

  Future<void> _processPayment() async {
    setState(() => _processing = true);
    final result = await _paymentService.processPayment(
      plan: widget.plan,
      method: _selectedMethod,
    );

    if (!mounted) return;

    if (result.success) {
      // サブスクリプション/HIGHLIGHT有効化
      if (widget.plan.type == PlanType.freeTrial) {
        _subscriptionService.startFreeTrial();
      } else if (widget.plan.type == PlanType.boost) {
        _subscriptionService.activateBoost(paymentMethod: _selectedMethod);
      } else {
        _subscriptionService.activateSubscription(
          planType: widget.plan.type,
          paymentMethod: _selectedMethod,
          selectedCategory: widget.selectedCategory,
        );
      }

      setState(() {
        _processing = false;
        _completed = true;
      });

      // 完了画面を1.8秒表示してから閉じる
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? '決済に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return _buildCompletedView();
    if (_processing) return _buildProcessingView();
    return _buildConfirmView();
  }

  // ===== 確認画面 =====

  Widget _buildConfirmView() {
    final plan = widget.plan;
    final isFree = plan.priceJpy == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.paleGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Row(
            children: [
              Container(height: 1, width: 16, color: AppTheme.vermillion),
              const SizedBox(width: 12),
              const Text(
                'CHECKOUT',
                style: TextStyle(
                  color: AppTheme.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3.0,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: const Icon(Icons.close, size: 18, color: AppTheme.grey),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Plan summary
          _buildPlanSummary(),
          const SizedBox(height: 24),
          if (!isFree) ...[
            const Text(
              'お支払い方法',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.charcoal,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentService.availableMethods
                .map((m) => _buildPaymentMethodTile(m)),
            const SizedBox(height: 16),
            _buildLegalText(),
            const SizedBox(height: 20),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.vermillion.withValues(alpha: 0.06),
                border: Border.all(
                    color: AppTheme.vermillion.withValues(alpha: 0.3),
                    width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.vermillion, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '7日後に自動的に終了します。自動課金はありません。',
                      style: TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isFree) ...[
                    Icon(_selectedMethod.icon, size: 18, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    isFree
                        ? '無料で始める'
                        : '${_selectedMethod.label}で支払う',
                    style: const TextStyle(
                      letterSpacing: 2.0,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isFree ? '' : '合計 ${plan.priceLabel} ${plan.unitLabel}',
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummary() {
    final plan = widget.plan;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        border: Border.all(color: AppTheme.paleGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppTheme.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.tagline,
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                    if (widget.selectedCategory != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.vermillion,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.selectedCategory!.activeIcon,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              widget.selectedCategory!.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    style: const TextStyle(
                      color: AppTheme.vermillion,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    plan.unitLabel.isEmpty ? plan.periodLabel : plan.unitLabel,
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: AppTheme.paleGrey),
          const SizedBox(height: 12),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check,
                        size: 12, color: AppTheme.vermillion),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          color: AppTheme.charcoal,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final selected = _selectedMethod == method;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.black : AppTheme.white,
            border: Border.all(
              color: selected ? AppTheme.black : AppTheme.paleGrey,
              width: selected ? 1.2 : 0.5,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Icon(
                method.icon,
                size: 22,
                color: selected ? Colors.white : AppTheme.black,
              ),
              const SizedBox(width: 12),
              Text(
                method.label,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.charcoal,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 16,
                color: selected ? Colors.white : AppTheme.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalText() {
    final plan = widget.plan;
    if (plan.type == PlanType.boost) {
      return const Text(
        '※ HIGHLIGHTは購入後ただちに有効化され、24時間継続します。返金不可。',
        style: TextStyle(color: AppTheme.lightGrey, fontSize: 10, height: 1.5),
      );
    }
    return const Text(
      '※ 月額プランは30日後に自動更新されます。マイページからいつでもキャンセル可能。',
      style: TextStyle(color: AppTheme.lightGrey, fontSize: 10, height: 1.5),
    );
  }

  // ===== 処理中 =====

  Widget _buildProcessingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 1.2,
              color: AppTheme.vermillion,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.plan.priceJpy == 0
                ? 'アカウントを準備しています...'
                : '${_selectedMethod.label}で決済中...',
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'しばらくお待ちください',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ===== 完了 =====

  Widget _buildCompletedView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.vermillion.withValues(alpha: 0.1),
              border: Border.all(color: AppTheme.vermillion, width: 1),
            ),
            child: const Icon(Icons.check,
                color: AppTheme.vermillion, size: 28),
          ),
          const SizedBox(height: 20),
          const Text(
            '繋がりました',
            style: TextStyle(
              color: AppTheme.black,
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.plan.type == PlanType.boost
                ? '24時間、あなたのプロフィールは優先表示されます'
                : widget.plan.type == PlanType.freeTrial
                    ? '7日間の無料トライアルが開始されました'
                    : '${widget.plan.name}が有効になりました',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 11,
              letterSpacing: 1.0,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
