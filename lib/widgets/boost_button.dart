import 'dart:async';
import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import 'payment_sheet.dart';

/// Discover画面のアクションボタン横に表示する、
/// 「アプローチ強化（ブースト）」ボタン
class BoostButton extends StatefulWidget {
  /// コンパクト表示（AppBar内に収まるサイズ）
  final bool compact;
  const BoostButton({super.key, this.compact = false});

  @override
  State<BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<BoostButton> {
  final _service = SubscriptionService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    _timer?.cancel();
    super.dispose();
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
      _startTimerIfNeeded();
    }
  }

  /// ブースト中はカウントダウンを毎分更新
  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (_service.activeBoost != null) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _purchaseBoost() async {
    await PaymentSheet.show(
      context,
      plan: SubscriptionPlan.boost,
    );
  }

  @override
  Widget build(BuildContext context) {
    final boost = _service.activeBoost;
    if (boost != null) {
      return _buildActiveBoost(boost);
    }
    return _buildPurchaseButton();
  }

  Widget _buildPurchaseButton() {
    if (widget.compact) {
      return GestureDetector(
        onTap: _purchaseBoost,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.vermillion,
                AppTheme.vermillion.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.vermillion.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.rocket_launch, size: 12, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'BOOST',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _purchaseBoost,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.vermillion,
              AppTheme.vermillion.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.vermillion.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.rocket_launch, size: 14, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'BOOST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(width: 6),
            Text(
              '¥500',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBoost(ActiveBoost boost) {
    if (widget.compact) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.vermillion.withValues(alpha: 0.12),
          border: Border.all(color: AppTheme.vermillion, width: 0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.vermillion,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              boost.remainingLabel,
              style: const TextStyle(
                color: AppTheme.vermillion,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.black,
        border: Border.all(color: AppTheme.vermillion, width: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // パルスドット
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.vermillion,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'BOOST中',
            style: TextStyle(
              color: AppTheme.vermillion,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            boost.remainingLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
