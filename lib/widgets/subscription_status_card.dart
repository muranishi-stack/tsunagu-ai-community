import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../models/connection_category.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../screens/subscription_screen.dart';

/// プロフィール画面に表示する、現在のサブスクリプション状態カード
class SubscriptionStatusCard extends StatefulWidget {
  const SubscriptionStatusCard({super.key});

  @override
  State<SubscriptionStatusCard> createState() =>
      _SubscriptionStatusCardState();
}

class _SubscriptionStatusCardState extends State<SubscriptionStatusCard> {
  final _service = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChange);
  }

  @override
  void dispose() {
    _service.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _openSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = _service.activeSubscription;
    final boost = _service.activeBoost;
    if (sub != null) {
      return _buildActiveCard(sub, boost);
    }
    return _buildUpgradeCard(boost);
  }

  // ===== アクティブカード（プラン契約中） =====

  Widget _buildActiveCard(ActiveSubscription sub, ActiveBoost? boost) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.vermillion,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _service.currentPlanBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ACTIVE',
                style: TextStyle(
                  color: AppTheme.vermillion,
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (boost != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.vermillion, width: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bolt,
                          size: 10, color: AppTheme.vermillion),
                      SizedBox(width: 4),
                      Text(
                        'BOOST',
                        style: TextStyle(
                          color: AppTheme.vermillion,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            sub.planName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
            ),
          ),
          if (sub.selectedCategory != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(sub.selectedCategory!.activeIcon,
                    size: 11, color: AppTheme.vermillion),
                const SizedBox(width: 6),
                Text(
                  sub.selectedCategory!.label,
                  style: const TextStyle(
                    color: AppTheme.vermillion,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '残り ${sub.daysRemaining}日',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (boost != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ブースト ${boost.remainingLabel}',
                        style: const TextStyle(
                          color: AppTheme.vermillion,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openSubscription,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'MANAGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== アップグレード誘導カード（無料ユーザー） =====

  Widget _buildUpgradeCard(ActiveBoost? boost) {
    return GestureDetector(
      onTap: _openSubscription,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.offWhite,
          border: Border.all(color: AppTheme.vermillion, width: 0.8),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: AppTheme.vermillion, size: 14),
                const SizedBox(width: 8),
                const Text(
                  'TSUNAGU PREMIUM',
                  style: TextStyle(
                    color: AppTheme.vermillion,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                if (boost != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.vermillion,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.bolt, size: 10, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'BOOST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _service.hasUsedFreeTrial
                  ? 'プレミアムで\nもっと多くの繋がりを'
                  : '7日間無料で\nすべての機能を体験',
              style: const TextStyle(
                color: AppTheme.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  '詳細を見る',
                  style: TextStyle(
                    color: AppTheme.vermillion,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward,
                    size: 14, color: AppTheme.vermillion),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
