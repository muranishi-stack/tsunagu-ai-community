import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  ReportStatus _activeTab = ReportStatus.pending;
  final Set<String> _selectedIds = <String>{};

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
        // ステータス別カウント
        final counts = <ReportStatus, int>{};
        for (final r in service.reports) {
          counts[r.status] = (counts[r.status] ?? 0) + 1;
        }
        final filtered =
            service.reports.where((r) => r.status == _activeTab).toList();

        // 選択IDのうち現タブに残っているものだけ保持
        final visibleIds = filtered.map((r) => r.id).toSet();
        _selectedIds.removeWhere((id) => !visibleIds.contains(id));

        final allSelected = filtered.isNotEmpty &&
            filtered.every((r) => _selectedIds.contains(r.id));
        final canBulkAction = _activeTab == ReportStatus.pending ||
            _activeTab == ReportStatus.reviewing;

        return AdminLayout(
          currentRoute: '/admin/reports',
          title: 'MODERATION',
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
                        label: 'PENDING',
                        value: (counts[ReportStatus.pending] ?? 0).toString(),
                        change: (counts[ReportStatus.pending] ?? 0) > 5
                            ? 'URGENT'
                            : 'OK',
                        changePositive:
                            (counts[ReportStatus.pending] ?? 0) <= 5,
                        icon: Icons.priority_high,
                      ),
                      StatCard(
                        label: 'REVIEWING',
                        value:
                            (counts[ReportStatus.reviewing] ?? 0).toString(),
                        icon: Icons.search,
                      ),
                      StatCard(
                        label: 'RESOLVED',
                        value:
                            (counts[ReportStatus.resolved] ?? 0).toString(),
                        icon: Icons.check_circle_outline,
                      ),
                      StatCard(
                        label: 'DISMISSED',
                        value:
                            (counts[ReportStatus.dismissed] ?? 0).toString(),
                        icon: Icons.do_not_disturb_outlined,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 32),

                // タブ
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
                  child: Row(
                    children: ReportStatus.values.map((s) {
                      final isActive = _activeTab == s;
                      final count = counts[s] ?? 0;
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _activeTab = s;
                            _selectedIds.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isActive
                                      ? AppTheme.vermillion
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s.label,
                                  style: TextStyle(
                                    color: isActive
                                        ? AppTheme.black
                                        : AppTheme.grey,
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppTheme.vermillion
                                          : AppTheme.paleGrey,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : AppTheme.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // 一括選択ツールバー
                if (canBulkAction && filtered.isNotEmpty)
                  _BulkToolbar(
                    selectedCount: _selectedIds.length,
                    totalCount: filtered.length,
                    allSelected: allSelected,
                    onToggleAll: () => setState(() {
                      if (allSelected) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(filtered.map((r) => r.id));
                      }
                    }),
                    onBulkResolve: _selectedIds.isEmpty
                        ? null
                        : () => _confirmBulk(
                              context,
                              status: ReportStatus.resolved,
                              ids: _selectedIds.toList(),
                            ),
                    onBulkDismiss: _selectedIds.isEmpty
                        ? null
                        : () => _confirmBulk(
                              context,
                              status: ReportStatus.dismissed,
                              ids: _selectedIds.toList(),
                            ),
                    onClearSelection: _selectedIds.isEmpty
                        ? null
                        : () => setState(_selectedIds.clear),
                  ),

                if (canBulkAction && filtered.isNotEmpty)
                  const SizedBox(height: 12),

                // 通報リスト
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(60),
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
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: AppTheme.lightGrey),
                          SizedBox(height: 12),
                          Text(
                            'No reports in this category',
                            style: TextStyle(
                                color: AppTheme.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((r) => _ReportCard(
                        report: r,
                        showCheckbox: canBulkAction,
                        selected: _selectedIds.contains(r.id),
                        onSelectChanged: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedIds.add(r.id);
                            } else {
                              _selectedIds.remove(r.id);
                            }
                          });
                        },
                        onAction: (status) => _handleAction(r, status),
                      )),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleAction(Report r, ReportStatus newStatus) {
    AdminService().resolveReport(r.id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('通報 ${r.id} を「${newStatus.label}」にしました'),
        backgroundColor: AppTheme.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmBulk(
    BuildContext context, {
    required ReportStatus status,
    required List<String> ids,
  }) {
    final isResolve = status == ReportStatus.resolved;
    final actionLabel = isResolve ? '対応済' : '却下';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          '${ids.length}件を一括処理しますか？',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        content: Text(
          '選択した ${ids.length} 件の通報を「$actionLabel」にします。\nこの操作は個別に取り消すことができます。',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('キャンセル', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isResolve ? Colors.green : AppTheme.vermillion,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AdminService().bulkResolveReports(ids, status);
              setState(() => _selectedIds.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('${ids.length}件を「$actionLabel」に一括処理しました'),
                  backgroundColor: AppTheme.black,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('$actionLabelにする (${ids.length})',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 一括選択ツールバー
// ============================================================================

class _BulkToolbar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final VoidCallback? onBulkResolve;
  final VoidCallback? onBulkDismiss;
  final VoidCallback? onClearSelection;

  const _BulkToolbar({
    required this.selectedCount,
    required this.totalCount,
    required this.allSelected,
    required this.onToggleAll,
    required this.onBulkResolve,
    required this.onBulkDismiss,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasSelection ? AppTheme.black : Colors.white,
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
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: allSelected
                  ? true
                  : (selectedCount > 0 ? null : false),
              tristate: true,
              onChanged: (_) => onToggleAll(),
              activeColor: AppTheme.vermillion,
              checkColor: Colors.white,
              side: BorderSide(
                color: hasSelection ? Colors.white70 : AppTheme.lightGrey,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            hasSelection
                ? '$selectedCount件を選択中'
                : '$totalCount件中  チェックボックスで一括選択',
            style: TextStyle(
              color: hasSelection ? Colors.white : AppTheme.grey,
              fontSize: 12,
              fontWeight:
                  hasSelection ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (hasSelection) ...[
            TextButton.icon(
              onPressed: onClearSelection,
              icon: const Icon(Icons.clear, size: 14, color: Colors.white70),
              label: const Text(
                '選択解除',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
            const SizedBox(width: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 13),
              label: Text(
                '一括却下 ($selectedCount)',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              onPressed: onBulkDismiss,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 13),
              label: Text(
                '一括対応 ($selectedCount)',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              onPressed: onBulkResolve,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final bool showCheckbox;
  final bool selected;
  final ValueChanged<bool> onSelectChanged;
  final void Function(ReportStatus) onAction;

  const _ReportCard({
    required this.report,
    required this.showCheckbox,
    required this.selected,
    required this.onSelectChanged,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: selected
            ? Border.all(color: AppTheme.vermillion, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppTheme.vermillion.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: selected ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCheckbox) ...[
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: selected,
                    onChanged: (v) => onSelectChanged(v ?? false),
                    activeColor: AppTheme.vermillion,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.vermillionPale,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  report.reason.label,
                  style: const TextStyle(
                    color: AppTheme.vermillion,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                report.id,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppTheme.grey,
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(report.createdAt),
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 当事者
          Row(
            children: [
              Expanded(
                child: _personChip(
                  label: '通報者',
                  name: report.reporterName,
                  id: report.reporterId,
                  color: AppTheme.charcoal,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward,
                    color: AppTheme.lightGrey, size: 16),
              ),
              Expanded(
                child: _personChip(
                  label: '対象',
                  name: report.targetUserName,
                  id: report.targetUserId,
                  color: AppTheme.vermillion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 詳細
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              report.description,
              style: const TextStyle(
                color: AppTheme.charcoal,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          if (report.status == ReportStatus.pending ||
              report.status == ReportStatus.reviewing) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (report.status == ReportStatus.pending)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.search, size: 14),
                    label: const Text('レビュー開始',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.black,
                      side: const BorderSide(color: AppTheme.paleGrey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    onPressed: () => onAction(ReportStatus.reviewing),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('対応済にする',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  onPressed: () => onAction(ReportStatus.resolved),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('却下', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.grey,
                    side: const BorderSide(color: AppTheme.paleGrey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  onPressed: () => onAction(ReportStatus.dismissed),
                ),
              ],
            ),
          ] else
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: report.status == ReportStatus.resolved
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppTheme.paleGrey,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    report.status == ReportStatus.resolved
                        ? Icons.check_circle
                        : Icons.do_not_disturb,
                    size: 12,
                    color: report.status == ReportStatus.resolved
                        ? Colors.green
                        : AppTheme.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    report.status.label,
                    style: TextStyle(
                      color: report.status == ReportStatus.resolved
                          ? Colors.green[700]
                          : AppTheme.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _personChip({
    required String label,
    required String name,
    required String id,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name.substring(0, 1) : '?',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 9,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  id,
                  style: const TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}
