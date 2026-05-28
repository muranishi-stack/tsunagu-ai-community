import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../models/connection_category.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    if (!service.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/admin/login', (_) => false);
      });
      return const Scaffold(body: SizedBox());
    }

    final categoryDist = service.categoryDistribution;
    final prefectures = service.topPrefectures.take(10).toList();
    final kpi = service.kpi;

    return AdminLayout(
      currentRoute: '/admin/analytics',
      title: 'ANALYTICS',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            const Text(
              'ユーザー分析',
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 22,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'カテゴリ・エリア・行動の傾向を可視化',
              style: TextStyle(color: AppTheme.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),

            // カテゴリ分布
            const SectionHeader(label: 'CATEGORY DISTRIBUTION'),
            const SizedBox(height: 16),
            _CategoryDistribution(items: categoryDist),
            const SizedBox(height: 32),

            // 都道府県分布 + ファネル
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 1,
                          child:
                              _PrefectureRanking(items: prefectures)),
                      const SizedBox(width: 20),
                      Expanded(
                          flex: 1,
                          child: _ConversionFunnel(
                              totalUsers: kpi.totalUsers,
                              activeSubs: kpi.activeSubscriptions,
                              conversion: kpi.conversionRate)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _PrefectureRanking(items: prefectures),
                    const SizedBox(height: 20),
                    _ConversionFunnel(
                        totalUsers: kpi.totalUsers,
                        activeSubs: kpi.activeSubscriptions,
                        conversion: kpi.conversionRate),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // エンゲージメント
            const SectionHeader(label: 'ENGAGEMENT'),
            const SizedBox(height: 16),
            _EngagementMetrics(kpi: kpi),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CategoryDistribution extends StatelessWidget {
  final List<CategoryDistribution> items;
  const _CategoryDistribution({required this.items});

  @override
  Widget build(BuildContext context) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final children = items.map((d) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.vermillionPale,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Icon(d.category.icon,
                        color: AppTheme.vermillion, size: 18),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 60,
                    child: Text(
                      d.category.label,
                      style: const TextStyle(
                        color: AppTheme.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: d.percentage / 100,
                            minHeight: 8,
                            backgroundColor: AppTheme.paleGrey,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.vermillion),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${formatNumber(d.userCount)} (${d.percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList();

          if (isWide) {
            return Column(children: children);
          }
          return Column(children: children);
        },
      ),
    );
  }
}

class _PrefectureRanking extends StatelessWidget {
  final List<PrefectureDistribution> items;
  const _PrefectureRanking({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        items.isNotEmpty ? items.first.userCount.toDouble() : 1.0;
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
            'TOP PREFECTURES',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 20),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i < 3 ? AppTheme.vermillion : AppTheme.grey,
                        fontSize: 12,
                        fontWeight: i < 3 ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      p.prefecture,
                      style: const TextStyle(
                        color: AppTheme.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: p.userCount / maxCount,
                        minHeight: 6,
                        backgroundColor: AppTheme.paleGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            i < 3
                                ? AppTheme.vermillion
                                : AppTheme.charcoal),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Text(
                      formatNumber(p.userCount),
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
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
}

class _ConversionFunnel extends StatelessWidget {
  final int totalUsers;
  final int activeSubs;
  final double conversion;

  const _ConversionFunnel({
    required this.totalUsers,
    required this.activeSubs,
    required this.conversion,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      _FunnelStage(
          label: 'TOTAL USERS', value: totalUsers, color: AppTheme.charcoal),
      _FunnelStage(
          label: 'ACTIVE USERS',
          value: (totalUsers * 0.72).round(),
          color: AppTheme.darkGrey),
      _FunnelStage(
          label: 'FREE TRIAL',
          value: (totalUsers * 0.18).round(),
          color: AppTheme.grey),
      _FunnelStage(
          label: 'PAID',
          value: activeSubs,
          color: AppTheme.vermillion),
    ];

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
                'CONVERSION FUNNEL',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Text(
                '${conversion.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppTheme.vermillion,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...stages.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final widthRatio = s.value / stages.first.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth * widthRatio;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            s.label,
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatNumber(s.value),
                            style: const TextStyle(
                              color: AppTheme.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            i == 0
                                ? '100%'
                                : '${(widthRatio * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.paleGrey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            height: 24,
                            width: w,
                            decoration: BoxDecoration(
                              color: s.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FunnelStage {
  final String label;
  final int value;
  final Color color;
  const _FunnelStage(
      {required this.label, required this.value, required this.color});
}

class _EngagementMetrics extends StatelessWidget {
  final DashboardKPI kpi;
  const _EngagementMetrics({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8,
        children: [
          StatCard(
            label: 'DAU / MAU',
            value:
                '${(kpi.activeUsersDau / kpi.activeUsersMau * 100).toStringAsFixed(1)}%',
            change: 'STICKY',
            icon: Icons.bolt_outlined,
          ),
          StatCard(
            label: 'AVG SESSION',
            value: '8.4分',
            change: '+0.6',
            icon: Icons.timer_outlined,
          ),
          StatCard(
            label: 'MATCHES / DAY',
            value: formatNumber(kpi.totalMatches30d ~/ 30),
            change: '+12.4%',
            icon: Icons.favorite_outline,
          ),
          StatCard(
            label: 'AVG MATCHES / USER',
            value: '6.8',
            change: '+0.4',
            icon: Icons.show_chart,
          ),
        ],
      );
    });
  }
}
