import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../models/subscription.dart';
// dart:html を Web 限定で安全に使用するための conditional import
import '_web_download_stub.dart'
    if (dart.library.html) '_web_download.dart' as web_download;

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

enum _DateRange { all, last7d, last30d, last90d }

extension _DateRangeX on _DateRange {
  String get label {
    switch (this) {
      case _DateRange.all:
        return '全期間';
      case _DateRange.last7d:
        return '直近7日';
      case _DateRange.last30d:
        return '直近30日';
      case _DateRange.last90d:
        return '直近90日';
    }
  }

  Duration? get duration {
    switch (this) {
      case _DateRange.all:
        return null;
      case _DateRange.last7d:
        return const Duration(days: 7);
      case _DateRange.last30d:
        return const Duration(days: 30);
      case _DateRange.last90d:
        return const Duration(days: 90);
    }
  }
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  TransactionStatus? _filterStatus;
  PlanType? _filterPlan;
  _DateRange _dateRange = _DateRange.all;

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
        // 売上集計
        final completed = service.revenues
            .where((r) => r.status == TransactionStatus.completed);
        final total30d = completed
            .where((r) => r.date.isAfter(
                DateTime.now().subtract(const Duration(days: 30))))
            .fold(0, (s, r) => s + r.amountJpy);
        final total7d = completed
            .where((r) => r.date.isAfter(
                DateTime.now().subtract(const Duration(days: 7))))
            .fold(0, (s, r) => s + r.amountJpy);
        final totalAll = completed.fold(0, (s, r) => s + r.amountJpy);
        final refundCount = service.revenues
            .where((r) => r.status == TransactionStatus.refunded)
            .length;

        // フィルタ
        final rangeDuration = _dateRange.duration;
        final rangeThreshold = rangeDuration == null
            ? null
            : DateTime.now().subtract(rangeDuration);
        final filtered = service.revenues.where((r) {
          if (_filterStatus != null && r.status != _filterStatus) return false;
          if (_filterPlan != null && r.planType != _filterPlan) return false;
          if (rangeThreshold != null && r.date.isBefore(rangeThreshold)) {
            return false;
          }
          return true;
        }).toList();

        return AdminLayout(
          currentRoute: '/admin/revenue',
          title: 'REVENUE',
          actions: [
            _ExportCsvButton(
              onExport: () => _exportCsv(context, filtered),
            ),
          ],
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // サマリーカード
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
                        label: 'TOTAL REVENUE',
                        value: formatCurrency(totalAll),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      StatCard(
                        label: 'LAST 30 DAYS',
                        value: formatCurrency(total30d),
                        change: '+22.1%',
                        icon: Icons.calendar_month_outlined,
                      ),
                      StatCard(
                        label: 'LAST 7 DAYS',
                        value: formatCurrency(total7d),
                        change: '+8.4%',
                        icon: Icons.date_range_outlined,
                      ),
                      StatCard(
                        label: 'REFUNDS',
                        value: refundCount.toString(),
                        change: refundCount > 20 ? 'ALERT' : 'NORMAL',
                        changePositive: refundCount <= 20,
                        icon: Icons.replay_outlined,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 32),

                // フィルタ
                const SectionHeader(label: 'TRANSACTIONS'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _FilterChip<_DateRange>(
                              label: '期間',
                              current: _dateRange,
                              items: _DateRange.values
                                  .map((d) =>
                                      _ChipItem(value: d, label: d.label))
                                  .toList(),
                              onChanged: (v) => setState(
                                  () => _dateRange = v ?? _DateRange.all),
                            ),
                            _FilterChip<TransactionStatus?>(
                              label: 'ステータス',
                              current: _filterStatus,
                              items: [
                                const _ChipItem(value: null, label: 'すべて'),
                                ...TransactionStatus.values.map((s) =>
                                    _ChipItem(value: s, label: s.label)),
                              ],
                              onChanged: (v) =>
                                  setState(() => _filterStatus = v),
                            ),
                            _FilterChip<PlanType?>(
                              label: 'プラン',
                              current: _filterPlan,
                              items: [
                                const _ChipItem(value: null, label: 'すべて'),
                                const _ChipItem(
                                    value: PlanType.allCategory,
                                    label: '全カテゴリ月額'),
                                const _ChipItem(
                                    value: PlanType.singleCategory,
                                    label: '単カテゴリ月額'),
                                const _ChipItem(
                                    value: PlanType.boost, label: 'ブースト'),
                                const _ChipItem(
                                    value: PlanType.freeTrial, label: '無料体験'),
                              ],
                              onChanged: (v) =>
                                  setState(() => _filterPlan = v),
                            ),
                            if (_dateRange != _DateRange.all ||
                                _filterStatus != null ||
                                _filterPlan != null)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _dateRange = _DateRange.all;
                                  _filterStatus = null;
                                  _filterPlan = null;
                                }),
                                icon: const Icon(Icons.clear,
                                    size: 14, color: AppTheme.grey),
                                label: const Text(
                                  'クリア',
                                  style: TextStyle(
                                      color: AppTheme.grey, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.vermillionPale,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '${formatNumber(filtered.length)}件',
                          style: const TextStyle(
                            color: AppTheme.vermillion,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // テーブル
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
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 56,
                        headingTextStyle: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                        columns: const [
                          DataColumn(label: Text('TX ID')),
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('USER')),
                          DataColumn(label: Text('PLAN')),
                          DataColumn(label: Text('AMOUNT'), numeric: true),
                          DataColumn(label: Text('METHOD')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('')),
                        ],
                        rows: filtered.take(50).map((r) {
                          return DataRow(cells: [
                            DataCell(Text(
                              r.id,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppTheme.charcoal),
                            )),
                            DataCell(Text(
                              _formatDateTime(r.date),
                              style: const TextStyle(
                                  color: AppTheme.charcoal, fontSize: 12),
                            )),
                            DataCell(Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.userName,
                                  style: const TextStyle(
                                    color: AppTheme.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  r.userId,
                                  style: const TextStyle(
                                      color: AppTheme.grey, fontSize: 10),
                                ),
                              ],
                            )),
                            DataCell(_planChip(r.planType)),
                            DataCell(Text(
                              formatCurrency(r.amountJpy),
                              style: const TextStyle(
                                color: AppTheme.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  r.paymentMethod == PaymentMethod.applePay
                                      ? Icons.apple
                                      : Icons.account_balance_wallet,
                                  size: 14,
                                  color: AppTheme.charcoal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  r.paymentMethod == PaymentMethod.applePay
                                      ? 'Apple Pay'
                                      : 'Google Pay',
                                  style: const TextStyle(
                                      color: AppTheme.charcoal, fontSize: 11),
                                ),
                              ],
                            )),
                            DataCell(_txStatusBadge(r.status)),
                            DataCell(
                              r.status == TransactionStatus.completed
                                  ? TextButton(
                                      onPressed: () => _confirmRefund(
                                          context, r),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            AppTheme.vermillion,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        '返金',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                if (filtered.length > 50) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '先頭50件を表示中（全${formatNumber(filtered.length)}件）',
                      style: const TextStyle(
                          color: AppTheme.grey, fontSize: 11),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportCsv(
      BuildContext context, List<RevenueRecord> filtered) async {
    // フィルタ状態を反映したCSVを生成 (全件版もServiceに残す)
    final buffer = StringBuffer();
    buffer.writeln('id,date,user_id,user_name,plan,amount_jpy,'
        'payment_method,status');
    for (final r in filtered) {
      buffer.writeln([
        r.id,
        r.date.toIso8601String(),
        r.userId,
        _csvEscape(r.userName),
        r.planType.name,
        r.amountJpy,
        r.paymentMethod.name,
        r.status.name,
      ].join(','));
    }
    final csv = buffer.toString();
    final ts = DateTime.now();
    final fname =
        'tsunagu_revenue_${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}'
        '_${ts.hour.toString().padLeft(2, '0')}${ts.minute.toString().padLeft(2, '0')}.csv';

    if (kIsWeb) {
      try {
        web_download.downloadCsv(fname, csv);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fname をダウンロードしました'),
            backgroundColor: AppTheme.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        // Web以外/失敗時はクリップボードへフォールバック
        await Clipboard.setData(ClipboardData(text: csv));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CSVをクリップボードにコピーしました'),
            backgroundColor: AppTheme.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Non-web: クリップボードにコピー
      await Clipboard.setData(ClipboardData(text: csv));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV ${filtered.length}件をクリップボードにコピーしました'),
          backgroundColor: AppTheme.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _csvEscape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      final escaped = s.replaceAll('"', '""');
      return '"$escaped"';
    }
    return s;
  }

  void _confirmRefund(BuildContext context, RevenueRecord r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('返金を実行しますか？',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text(
          '${r.userName} に ${formatCurrency(r.amountJpy)} を返金します。\n'
          'この操作は取り消せません。',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vermillion,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AdminService().refundTransaction(r.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${r.id} を返金しました'),
                  backgroundColor: AppTheme.black,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('返金実行',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _planChip(PlanType p) {
    String label;
    switch (p) {
      case PlanType.allCategory:
        label = 'PREMIUM';
        break;
      case PlanType.singleCategory:
        label = 'SINGLE';
        break;
      case PlanType.boost:
        label = 'BOOST';
        break;
      case PlanType.freeTrial:
        label = 'TRIAL';
        break;
    }
    final isPremium = p == PlanType.allCategory;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPremium ? AppTheme.black : AppTheme.vermillionPale,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPremium ? Colors.white : AppTheme.vermillion,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
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
        s.label,
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

class _ChipItem<T> {
  final T value;
  final String label;
  const _ChipItem({required this.value, required this.label});
}

class _FilterChip<T> extends StatelessWidget {
  final String label;
  final T current;
  final List<_ChipItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterChip({
    required this.label,
    required this.current,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.paleGrey),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: current,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            items: items
                .map((e) => DropdownMenuItem<T>(
                      value: e.value,
                      child: Text(e.label),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ExportCsvButton extends StatelessWidget {
  final Future<void> Function() onExport;
  const _ExportCsvButton({required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'フィルタ結果をCSVエクスポート',
      child: ElevatedButton.icon(
        icon: const Icon(Icons.file_download_outlined, size: 14),
        label: const Text(
          'EXPORT CSV',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        onPressed: onExport,
      ),
    );
  }
}
