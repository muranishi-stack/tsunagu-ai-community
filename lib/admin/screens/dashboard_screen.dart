import 'package:flutter/material.dart';
import 'dart:async';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../models/subscription.dart';
import '../../widgets/tsunagu_logo.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // ライブ時計を1秒ごとに更新
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    if (!service.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/admin/login', (_) => false);
      });
      return const Scaffold(
          backgroundColor: AppTheme.black,
          body: Center(child: CircularProgressIndicator()));
    }

    final kpi = service.kpi;
    final revenueSeries = service.getRevenueTimeSeries();
    final userSeries = service.getNewUserTimeSeries();
    final planBreakdown = service.planBreakdown;
    final activities = service.recentActivities;

    return AdminLayout(
      currentRoute: '/admin/dashboard',
      title: 'DASHBOARD',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヒーロー: ロゴ + ウェルカム + ライブ時計
            _HeroHeader(
              name: service.currentAdmin?.name ?? '',
              now: _now,
              activeUsersDau: kpi.activeUsersDau,
              activeBoosts: kpi.activeBoosts,
            ),
            const SizedBox(height: 32),

            // KPIグリッド
            const SectionHeader(
                label: 'KEY METRICS', subtitle: '主要指標 (リアルタイム)'),
            const SizedBox(height: 16),
            _KpiGrid(kpi: kpi),
            const SizedBox(height: 32),

            // チャート + アクティビティフィード
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1100;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _RevenueChart(series: revenueSeries),
                            const SizedBox(height: 20),
                            _UserChart(series: userSeries),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _ActivityFeed(activities: activities),
                            const SizedBox(height: 20),
                            _PlanBreakdownCard(items: planBreakdown),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _RevenueChart(series: revenueSeries),
                    const SizedBox(height: 20),
                    _ActivityFeed(activities: activities),
                    const SizedBox(height: 20),
                    _UserChart(series: userSeries),
                    const SizedBox(height: 20),
                    _PlanBreakdownCard(items: planBreakdown),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // 最新通報
            const _RecentReportsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String name;
  final DateTime now;
  final int activeUsersDau;
  final int activeBoosts;

  const _HeroHeader({
    required this.name,
    required this.now,
    required this.activeUsersDau,
    required this.activeBoosts,
  });

  @override
  Widget build(BuildContext context) {
    final hour = now.hour;
    final greeting = hour < 12
        ? 'おはようございます'
        : hour < 18
            ? 'こんにちは'
            : 'こんばんは';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.black, Color(0xFF2A1A1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景装飾 ロゴ
          Positioned(
            right: -40,
            top: -40,
            child: Opacity(
              opacity: 0.07,
              child: TsunaguLogo(size: 280),
            ),
          ),
          // メインコンテンツ
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const TsunaguLogo(size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'TSUNAGU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.vermillion,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  '$greeting, $name さん',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '今日も TSUNAGU の運営をよろしくお願いします',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            );

            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ライブ時計
                Row(
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
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(now),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w200,
                        fontFamily: 'monospace',
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${now.year}年${now.month}月${now.day}日 ${_weekday(now.weekday)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _heroChip(
                      label: 'DAU',
                      value: formatNumber(activeUsersDau),
                      icon: Icons.bolt,
                    ),
                    const SizedBox(width: 8),
                    _heroChip(
                      label: 'HIGHLIGHTS',
                      value: formatNumber(activeBoosts),
                      icon: Icons.rocket_launch,
                      highlight: true,
                    ),
                  ],
                ),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  right,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 20), right],
            );
          }),
        ],
      ),
    );
  }

  Widget _heroChip({
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.vermillion
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  String _weekday(int w) {
    const days = ['月', '火', '水', '木', '金', '土', '日'];
    return '${days[w - 1]}曜日';
  }
}

/// リアルタイムアクティビティフィード
class _ActivityFeed extends StatelessWidget {
  final List<ActivityEvent> activities;
  const _ActivityFeed({required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                'LIVE ACTIVITY',
                style: TextStyle(
                  color: AppTheme.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.vermillionPale,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${activities.length} 件',
                  style: const TextStyle(
                    color: AppTheme.vermillion,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  '直近のアクティビティはありません',
                  style: TextStyle(color: AppTheme.grey, fontSize: 12),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, i) {
                  final a = activities[i];
                  return _activityItem(a, isLast: i == activities.length - 1);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _activityItem(ActivityEvent a, {bool isLast = false}) {
    final color = _typeColor(a.type);
    final icon = _typeIcon(a.type);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイムラインドット
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3), width: 1),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: AppTheme.paleGrey,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // 内容
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        a.title,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(a.timestamp),
                        style: const TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a.description,
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(ActivityType t) {
    switch (t) {
      case ActivityType.userSignup:
        return Colors.blue;
      case ActivityType.subscription:
        return Colors.green;
      case ActivityType.boostPurchase:
        return AppTheme.vermillion;
      case ActivityType.report:
        return Colors.orange;
      case ActivityType.match:
        return Colors.pink;
    }
  }

  IconData _typeIcon(ActivityType t) {
    switch (t) {
      case ActivityType.userSignup:
        return Icons.person_add;
      case ActivityType.subscription:
        return Icons.workspace_premium;
      case ActivityType.boostPurchase:
        return Icons.rocket_launch;
      case ActivityType.report:
        return Icons.flag;
      case ActivityType.match:
        return Icons.favorite;
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}秒前';
    if (d.inMinutes < 60) return '${d.inMinutes}分前';
    if (d.inHours < 24) return '${d.inHours}時間前';
    return '${d.inDays}日前';
  }
}

class _KpiGrid extends StatelessWidget {
  final DashboardKPI kpi;
  const _KpiGrid({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            StatCard(
              label: 'TOTAL USERS',
              value: formatNumber(kpi.totalUsers),
              change: '+8.2%',
              changePositive: true,
              icon: Icons.people_outline,
            ),
            StatCard(
              label: 'MAU',
              value: formatNumber(kpi.activeUsersMau),
              change: '+12.4%',
              changePositive: true,
              icon: Icons.trending_up,
            ),
            StatCard(
              label: 'MRR',
              value: formatCurrency(kpi.monthlyRecurringRevenue),
              change: '+18.7%',
              changePositive: true,
              icon: Icons.payments_outlined,
            ),
            StatCard(
              label: 'REVENUE (30D)',
              value: formatCurrency(kpi.totalRevenue30d),
              change: '+22.1%',
              changePositive: true,
              icon: Icons.account_balance_wallet_outlined,
            ),
            StatCard(
              label: 'DAU',
              value: formatNumber(kpi.activeUsersDau),
              change: '+3.6%',
              changePositive: true,
              icon: Icons.bolt_outlined,
            ),
            StatCard(
              label: 'NEW TODAY',
              value: formatNumber(kpi.newUsersToday),
              change: '+5',
              changePositive: true,
              icon: Icons.person_add_alt_outlined,
            ),
            StatCard(
              label: 'ACTIVE SUBS',
              value: formatNumber(kpi.activeSubscriptions),
              change: '+6.8%',
              changePositive: true,
              icon: Icons.workspace_premium_outlined,
            ),
            StatCard(
              label: 'CONVERSION',
              value: '${kpi.conversionRate.toStringAsFixed(1)}%',
              change: '+0.4%',
              changePositive: true,
              icon: Icons.show_chart,
            ),
            StatCard(
              label: 'CHURN RATE',
              value: '${kpi.churnRate.toStringAsFixed(1)}%',
              change: '-0.6%',
              changePositive: true,
              icon: Icons.trending_down,
            ),
            StatCard(
              label: 'MATCHES (30D)',
              value: formatNumber(kpi.totalMatches30d),
              change: '+14.2%',
              changePositive: true,
              icon: Icons.favorite_outline,
            ),
            StatCard(
              label: 'ACTIVE HIGHLIGHTS',
              value: formatNumber(kpi.activeBoosts),
              change: 'LIVE',
              changePositive: true,
              icon: Icons.rocket_launch_outlined,
            ),
            StatCard(
              label: 'PENDING REPORTS',
              value: formatNumber(kpi.pendingReports),
              change: kpi.pendingReports > 5 ? 'ATTENTION' : 'OK',
              changePositive: kpi.pendingReports <= 5,
              icon: Icons.flag_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<TimeSeriesPoint> series;
  const _RevenueChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final total = series.fold<double>(0, (s, p) => s + p.value).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'REVENUE',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              Spacer(),
              Text(
                'LAST 30 DAYS',
                style: TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(total),
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: 28,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _LineChartPainter(
                points: series,
                color: AppTheme.vermillion,
                fillGradient: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${series.first.date.month}/${series.first.date.day}',
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 10,
                ),
              ),
              Text(
                '${series.last.date.month}/${series.last.date.day}',
                style: const TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserChart extends StatelessWidget {
  final List<TimeSeriesPoint> series;
  const _UserChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final total = series.fold<double>(0, (s, p) => s + p.value).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'NEW USERS',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              Spacer(),
              Text(
                'LAST 30 DAYS',
                style: TextStyle(
                  color: AppTheme.lightGrey,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '+${formatNumber(total)}',
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: 28,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _BarChartPainter(
                points: series,
                color: AppTheme.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBreakdownCard extends StatelessWidget {
  final List<PlanRevenueBreakdown> items;
  const _PlanBreakdownCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0, (s, i) => s + i.totalRevenue);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLAN BREAKDOWN',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 20),
          ...items.map((item) {
            final percent = total > 0 ? (item.totalRevenue / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _planLabel(item.planType),
                          style: const TextStyle(
                            color: AppTheme.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        formatCurrency(item.totalRevenue),
                        style: const TextStyle(
                          color: AppTheme.charcoal,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${item.count}件',
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(percent * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppTheme.vermillion,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 4,
                      backgroundColor: AppTheme.paleGrey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.vermillion),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _planLabel(PlanType t) {
    switch (t) {
      case PlanType.allCategory:
        return '全カテゴリ月額';
      case PlanType.singleCategory:
        return '単カテゴリ月額';
      case PlanType.boost:
        return 'HIGHLIGHT';
      case PlanType.freeTrial:
        return '無料体験';
    }
  }
}

class _RecentReportsCard extends StatelessWidget {
  const _RecentReportsCard();

  @override
  Widget build(BuildContext context) {
    final reports = AdminService().reports.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'RECENT REPORTS',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(
                    context, '/admin/reports'),
                child: const Row(
                  children: [
                    Text(
                      'VIEW ALL',
                      style: TextStyle(
                        color: AppTheme.vermillion,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward,
                        size: 12, color: AppTheme.vermillion),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reports.map((r) => Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.paleGrey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(r.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.reason.label,
                            style: const TextStyle(
                              color: AppTheme.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.targetUserName} ← ${r.reporterName}',
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _timeAgo(r.createdAt),
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              )),
          if (reports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No reports',
                  style: TextStyle(color: AppTheme.grey, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.pending:
        return AppTheme.vermillion;
      case ReportStatus.reviewing:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return AppTheme.lightGrey;
    }
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}分前';
    if (d.inHours < 24) return '${d.inHours}時間前';
    return '${d.inDays}日前';
  }
}

// ===== チャートペインター =====

class _LineChartPainter extends CustomPainter {
  final List<TimeSeriesPoint> points;
  final Color color;
  final bool fillGradient;

  _LineChartPainter({
    required this.points,
    required this.color,
    this.fillGradient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxV = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minV = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final path = Path();
    final fillPath = Path();
    final dx = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = dx * i;
      final normY = (points[i].value - minV) / range;
      final y = size.height - (normY * (size.height - 20)) - 10;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // グリッド線
    final gridPaint = Paint()
      ..color = AppTheme.paleGrey
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 塗りつぶし
    if (fillGradient) {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // ライン
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 終点ドット
    final lastNormY = (points.last.value - minV) / range;
    final lastY = size.height - (lastNormY * (size.height - 20)) - 10;
    canvas.drawCircle(
      Offset(size.width, lastY),
      4,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(size.width, lastY),
      6,
      Paint()
        ..color = color.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.points != points;
}

class _BarChartPainter extends CustomPainter {
  final List<TimeSeriesPoint> points;
  final Color color;

  _BarChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxV = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    if (maxV == 0) return;

    final gap = 3.0;
    final barWidth = (size.width - (gap * (points.length - 1))) / points.length;

    for (int i = 0; i < points.length; i++) {
      final h = (points[i].value / maxV) * (size.height - 10);
      final x = i * (barWidth + gap);
      final y = size.height - h;
      final isLast = i == points.length - 1;
      final paint = Paint()
        ..color = isLast ? AppTheme.vermillion : color.withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, h),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.points != points;
}
