import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../models/connection_category.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/payment_sheet.dart';

/// 課金プラン選択画面
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _subscriptionService.addListener(_onChange);
  }

  @override
  void dispose() {
    _subscriptionService.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _purchasePlan(SubscriptionPlan plan) async {
    ConnectionCategory? selectedCategory;
    if (plan.type == PlanType.singleCategory) {
      selectedCategory = await _selectCategory();
      if (selectedCategory == null) return;
    }

    if (!mounted) return;
    await PaymentSheet.show(
      context,
      plan: plan,
      selectedCategory: selectedCategory,
    );
  }

  /// カテゴリ選択ダイアログ（singleCategoryプラン用）
  Future<ConnectionCategory?> _selectCategory() {
    return showModalBottomSheet<ConnectionCategory>(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  Container(
                      height: 1, width: 16, color: AppTheme.vermillion),
                  const SizedBox(width: 12),
                  const Text(
                    'SELECT CATEGORY',
                    style: TextStyle(
                      color: AppTheme.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'シングルプランで利用するカテゴリを1つ選択してください',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              ...ConnectionCategory.values.map((cat) => InkWell(
                    onTap: () => Navigator.pop(context, cat),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.vermillion
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(cat.activeIcon,
                                size: 16, color: AppTheme.vermillion),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.label,
                                  style: const TextStyle(
                                    color: AppTheme.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cat.description,
                                  style: const TextStyle(
                                    color: AppTheme.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 12, color: AppTheme.lightGrey),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSub = _subscriptionService.activeSubscription;

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PREMIUM',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeSub != null) _buildActiveSubscriptionCard(activeSub),
              if (activeSub == null) _buildHeader(),
              const SizedBox(height: 24),
              // 無料トライアル（未使用の場合のみ）
              if (!_subscriptionService.hasUsedFreeTrial && activeSub == null)
                _buildFreeTrialCard(),
              // 月額プラン
              const SizedBox(height: 24),
              _buildSectionHeader('MONTHLY PLANS'),
              const SizedBox(height: 12),
              ...SubscriptionPlan.monthlyPlans.map(_buildPlanCard),
              // HIGHLIGHT
              const SizedBox(height: 24),
              _buildSectionHeader('HIGHLIGHT'),
              const SizedBox(height: 12),
              _buildBoostCard(),
              const SizedBox(height: 32),
              _buildLegalFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          '繋がりを、もっと自由に。',
          style: TextStyle(
            color: AppTheme.black,
            fontSize: 24,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 32, color: AppTheme.vermillion),
        const SizedBox(height: 12),
        const Text(
          'TSUNAGUプレミアムで、すべての出会いを\n制限なく楽しめます。',
          style: TextStyle(
            color: AppTheme.grey,
            fontSize: 12,
            letterSpacing: 0.5,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSubscriptionCard(ActiveSubscription sub) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
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
                  _subscriptionService.currentPlanBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome,
                  color: AppTheme.vermillion, size: 14),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            sub.planName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
            ),
          ),
          if (sub.selectedCategory != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(sub.selectedCategory!.activeIcon,
                    size: 12, color: AppTheme.vermillion),
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
          Container(height: 0.5, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '残り',
                      style: TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sub.daysRemaining}日',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              if (sub.planType != PlanType.freeTrial)
                OutlinedButton(
                  onPressed: () => _showCancelDialog(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        title: const Text(
          'プランをキャンセル',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        content: const Text(
          '現在のプランをキャンセルしますか？\n有効期限まではご利用いただけます。',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '戻る',
              style: TextStyle(color: AppTheme.grey, letterSpacing: 1.0),
            ),
          ),
          TextButton(
            onPressed: () {
              _subscriptionService.cancelSubscription();
              Navigator.pop(context);
            },
            child: const Text(
              'キャンセル',
              style:
                  TextStyle(color: AppTheme.vermillion, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        Container(height: 1, width: 16, color: AppTheme.vermillion),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFreeTrialCard() {
    const plan = SubscriptionPlan.freeTrial;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.vermillion.withValues(alpha: 0.05),
        border: Border.all(color: AppTheme.vermillion, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard,
                  color: AppTheme.vermillion, size: 14),
              const SizedBox(width: 8),
              const Text(
                'FIRST TIME OFFER',
                style: TextStyle(
                  color: AppTheme.vermillion,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppTheme.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
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
                  ],
                ),
              ),
              const Text(
                '無料',
                style: TextStyle(
                  color: AppTheme.vermillion,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '7日間',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _purchasePlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vermillion,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
              child: const Text(
                '7日間無料で始める',
                style: TextStyle(
                  letterSpacing: 2.0,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isPopular = plan.isPopular;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border.all(
          color: isPopular ? AppTheme.black : AppTheme.paleGrey,
          width: isPopular ? 1.2 : 0.5,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.vermillion,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    style: const TextStyle(
                      color: AppTheme.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    plan.unitLabel,
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
          const SizedBox(height: 16),
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
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _purchasePlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? AppTheme.black : AppTheme.white,
                foregroundColor: isPopular ? Colors.white : AppTheme.black,
                side: BorderSide(
                  color: isPopular ? AppTheme.black : AppTheme.paleGrey,
                  width: 0.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
              child: Text(
                plan.type == PlanType.singleCategory
                    ? 'カテゴリを選んで購入'
                    : '${plan.priceLabel}で始める',
                style: const TextStyle(
                  letterSpacing: 2.0,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostCard() {
    const plan = SubscriptionPlan.boost;
    final activeBoost = _subscriptionService.activeBoost;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.vermillion.withValues(alpha: 0.08),
            AppTheme.vermillion.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: AppTheme.vermillion, width: 0.8),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.vermillion,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppTheme.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    plan.unitLabel,
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
          if (activeBoost != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.black,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt,
                      color: AppTheme.vermillion, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'HIGHLIGHT中',
                    style: TextStyle(
                      color: AppTheme.vermillion,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '残り ${activeBoost.remainingLabel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _purchasePlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vermillion,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
              child: Text(
                activeBoost != null
                    ? '追加でHIGHLIGHT購入'
                    : '${plan.priceLabel}でHIGHLIGHT',
                style: const TextStyle(
                  letterSpacing: 2.0,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalFooter() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '※ 月額プランは30日後に自動更新されます。マイページよりいつでも解約可能です。',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 10,
              height: 1.6,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '※ お支払いは Apple Pay / Google Pay でセキュアに処理されます。',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 10,
              height: 1.6,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '※ 価格は税込です。返金は各ストアのポリシーに従います。',
            style: TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 10,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
