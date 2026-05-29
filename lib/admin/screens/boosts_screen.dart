import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../models/subscription.dart';

class AdminBoostsScreen extends StatefulWidget {
  const AdminBoostsScreen({super.key});

  @override
  State<AdminBoostsScreen> createState() => _AdminBoostsScreenState();
}

class _AdminBoostsScreenState extends State<AdminBoostsScreen> {
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

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        // HIGHLIGHT購入レコードを抽出
        final boosts = service.revenues
            .where((r) => r.planType == PlanType.boost)
            .toList();
        final completed = boosts
            .where((b) => b.status == TransactionStatus.completed)
            .toList();
        final totalRevenue =
            completed.fold(0, (s, r) => s + r.amountJpy);
        final kpi = service.kpi;

        // 時間帯別集計（24時間）
        final hourCounts = List<int>.filled(24, 0);
        for (final b in completed) {
          hourCounts[b.date.hour]++;
        }
        final maxHour = hourCounts.reduce((a, b) => a > b ? a : b);

        return AdminLayout(
          currentRoute: '/admin/boosts',
          title: 'HIGHLIGHTS',
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // サマリー
                LayoutBuilder(builder: (context, constraints) {
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
                        label: 'ACTIVE NOW',
                        value: formatNumber(kpi.activeBoosts),
                        change: 'LIVE',
                        icon: Icons.rocket_launch,
                      ),
                      StatCard(
                        label: 'TOTAL PURCHASES',
                        value: formatNumber(completed.length),
                        change: '+24',
                        icon: Icons.shopping_bag_outlined,
                      ),
                      StatCard(
                        label: 'HIGHLIGHT REVENUE',
                        value: formatCurrency(totalRevenue),
                        change: '+18.6%',
                        icon: Icons.payments_outlined,
                      ),
                      StatCard(
                        label: 'PEAK HOUR',
                        value:
                            '${hourCounts.indexOf(maxHour)}:00',
                        icon: Icons.schedule,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 32),

                // HIGHLIGHT時間帯分布
                Container(
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
                            'PURCHASES BY HOUR',
                            style: TextStyle(
                              color: AppTheme.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '24-HOUR DISTRIBUTION',
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(24, (h) {
                            final count = hourCounts[h];
                            final ratio =
                                maxHour > 0 ? count / maxHour : 0.0;
                            final isPeak = count == maxHour && count > 0;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 1.5),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      count.toString(),
                                      style: TextStyle(
                                        color: isPeak
                                            ? AppTheme.vermillion
                                            : AppTheme.lightGrey,
                                        fontSize: 9,
                                        fontWeight: isPeak
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 130 * ratio + 4,
                                      decoration: BoxDecoration(
                                        color: isPeak
                                            ? AppTheme.vermillion
                                            : AppTheme.charcoal
                                                .withValues(alpha: 0.85),
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      h.toString(),
                                      style: TextStyle(
                                        color: h % 6 == 0
                                            ? AppTheme.charcoal
                                            : AppTheme.lightGrey,
                                        fontSize: 9,
                                        fontWeight: h % 6 == 0
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 履歴テーブル
                const SectionHeader(label: 'PURCHASE HISTORY'),
                const SizedBox(height: 16),
                Container(
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth:
                              MediaQuery.of(context).size.width - 320),
                      child: DataTable(
                        columnSpacing: 32,
                        horizontalMargin: 24,
                        headingRowHeight: 44,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 52,
                        headingTextStyle: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                        columns: const [
                          DataColumn(label: Text('TX ID')),
                          DataColumn(label: Text('USER')),
                          DataColumn(label: Text('PURCHASED AT')),
                          DataColumn(label: Text('EXPIRES')),
                          DataColumn(label: Text('AMOUNT'), numeric: true),
                          DataColumn(label: Text('STATUS')),
                        ],
                        rows: boosts.take(50).map((b) {
                          final expiry =
                              b.date.add(const Duration(hours: 24));
                          final isActive =
                              b.status == TransactionStatus.completed &&
                                  DateTime.now().isBefore(expiry);
                          return DataRow(cells: [
                            DataCell(Text(
                              b.id,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppTheme.charcoal),
                            )),
                            DataCell(Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.userName,
                                  style: const TextStyle(
                                      color: AppTheme.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  b.userId,
                                  style: const TextStyle(
                                      color: AppTheme.grey, fontSize: 10),
                                ),
                              ],
                            )),
                            DataCell(Text(
                              _formatDateTime(b.date),
                              style: const TextStyle(
                                  color: AppTheme.charcoal, fontSize: 12),
                            )),
                            DataCell(Text(
                              _formatDateTime(expiry),
                              style: TextStyle(
                                color: isActive
                                    ? AppTheme.vermillion
                                    : AppTheme.grey,
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            )),
                            DataCell(Text(
                              formatCurrency(b.amountJpy),
                              style: const TextStyle(
                                color: AppTheme.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                            DataCell(
                              isActive
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.vermillion,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.rocket_launch,
                                              size: 10,
                                              color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : _txStatusBadge(b.status),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _txStatusBadge(TransactionStatus s) {
    Color color;
    switch (s) {
      case TransactionStatus.completed:
        color = Colors.green;
        break;
      case TransactionStatus.refunded:
        color = AppTheme.vermillion;
        break;
      case TransactionStatus.failed:
        color = AppTheme.darkGrey;
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        s.label == '完了' ? 'EXPIRED' : s.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime d) =>
      '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
