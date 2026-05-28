import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tsunagu_logo.dart';

/// 管理画面の共通レイアウト（サイドバー + コンテンツエリア）
class AdminLayout extends StatelessWidget {
  final String currentRoute;
  final Widget child;
  final String title;
  final List<Widget>? actions;

  const AdminLayout({
    super.key,
    required this.currentRoute,
    required this.child,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      drawer: isWide ? null : const _Sidebar(),
      body: AnimatedBuilder(
        animation: AdminService(),
        builder: (context, _) => Row(
          children: [
            if (isWide) const _Sidebar(),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: title,
                    showMenuButton: !isWide,
                    actions: actions,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    final admin = AdminService().currentAdmin;
    final service = AdminService();
    final pendingCount = service
        .reports
        .where((r) => r.status == ReportStatus.pending)
        .length;
    // AI巡回: pending + critical の合計をバッジ表示
    final aiStats = service.aiScannerStats;
    final aiCriticalCount = aiStats.criticalCount;
    final aiPendingCount = aiStats.pendingReviewCount;
    // データ連携: アクティブな連携数
    final activeSourcesCount = service.dataSources
        .where((s) => s.status == DataSourceStatus.active)
        .length;

    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: AppTheme.black,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(2, 0))
        ],
      ),
      child: Column(
        children: [
          // ロゴエリア (本物の結びマークロゴを使用)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Row(
              children: [
                // 朱色のロゴ背景パネル
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.vermillion.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const TsunaguLogo(size: 36),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TSUNAGU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'ADMIN CONSOLE',
                        style: TextStyle(
                          color: AppTheme.vermillion,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // メニュー
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _menuSection('MAIN'),
                _menuItem(context, route, Icons.dashboard_outlined,
                    Icons.dashboard, 'ダッシュボード', '/admin/dashboard'),
                _menuItem(context, route, Icons.people_outline, Icons.people,
                    'ユーザー管理', '/admin/users'),
                const SizedBox(height: 16),
                _menuSection('MONETIZATION'),
                _menuItem(context, route, Icons.payments_outlined,
                    Icons.payments, '課金・売上', '/admin/revenue'),
                _menuItem(context, route, Icons.rocket_launch_outlined,
                    Icons.rocket_launch, 'ブースト履歴', '/admin/boosts'),
                const SizedBox(height: 16),
                _menuSection('OPERATIONS'),
                _menuItem(
                  context,
                  route,
                  Icons.flag_outlined,
                  Icons.flag,
                  'モデレーション',
                  '/admin/reports',
                  badge: pendingCount > 0 ? pendingCount.toString() : null,
                ),
                _menuItem(
                  context,
                  route,
                  Icons.shield_outlined,
                  Icons.shield,
                  'AI巡回',
                  '/admin/ai-moderation',
                  badge: aiCriticalCount > 0
                      ? aiCriticalCount.toString()
                      : (aiPendingCount > 0 ? aiPendingCount.toString() : null),
                  badgeIsCritical: aiCriticalCount > 0,
                ),
                _menuItem(context, route, Icons.analytics_outlined,
                    Icons.analytics, '分析', '/admin/analytics'),
                _menuItem(context, route, Icons.campaign_outlined,
                    Icons.campaign, 'お知らせ配信', '/admin/announcements'),
                const SizedBox(height: 16),
                _menuSection('LAUNCH'),
                _menuItem(
                  context,
                  route,
                  Icons.dns_outlined,
                  Icons.dns,
                  'データ連携',
                  '/admin/data-sources',
                  badge: activeSourcesCount > 0
                      ? activeSourcesCount.toString()
                      : null,
                ),
                const SizedBox(height: 16),
                _menuSection('SYSTEM'),
                _menuItem(context, route, Icons.settings_outlined,
                    Icons.settings, '設定', '/admin/settings'),
              ],
            ),
          ),
          // 管理者プロフィール
          if (admin != null) _adminFooter(context, admin),
        ],
      ),
    );
  }

  Widget _menuSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    String currentRoute,
    IconData icon,
    IconData activeIcon,
    String label,
    String route, {
    String? badge,
    bool badgeIsCritical = false,
  }) {
    final isActive = currentRoute == route;
    final badgeColor =
        badgeIsCritical ? const Color(0xFFD32F2F) : AppTheme.vermillion;
    return InkWell(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.vermillion.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border(
            left: BorderSide(
              color: isActive ? AppTheme.vermillion : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 16,
              color: isActive ? AppTheme.vermillion : Colors.white70,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _adminFooter(BuildContext context, AdminAccount admin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.vermillion, AppTheme.vermillionDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: Text(
                admin.name.isNotEmpty ? admin.name.substring(0, 1) : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  admin.role.label,
                  style: const TextStyle(
                    color: AppTheme.vermillion,
                    fontSize: 8,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'サインアウト',
            icon: const Icon(Icons.logout, color: Colors.white60, size: 16),
            onPressed: () async {
              await AdminService().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, '/admin/login', (_) => false);
            },
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool showMenuButton;
  final List<Widget>? actions;

  const _TopBar({
    required this.title,
    required this.showMenuButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final pendingReports = AdminService()
        .reports
        .where((r) => r.status == ReportStatus.pending)
        .length;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: AppTheme.paleGrey, width: 0.5)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          // モバイル時は小ロゴをタイトル横に
          if (showMenuButton) ...[
            const TsunaguLogo(size: 22),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 16,
            color: AppTheme.paleGrey,
          ),
          const SizedBox(width: 12),
          Text(
            _greeting(),
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          // カスタムアクション
          if (actions != null) ...[
            ...actions!,
            const SizedBox(width: 12),
          ],
          // 通知バッジ
          _NotificationButton(pendingCount: pendingReports),
          const SizedBox(width: 16),
          // LIVE バッジ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.vermillion.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: AppTheme.vermillion.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.vermillion,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppTheme.vermillion,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final now = DateTime.now();
    final months = '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    return months;
  }
}

class _NotificationButton extends StatelessWidget {
  final int pendingCount;
  const _NotificationButton({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, '/admin/reports'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined,
                color: AppTheme.charcoal, size: 20),
            if (pendingCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.vermillion,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    pendingCount > 99 ? '99+' : pendingCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 統計カードウィジェット
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final bool changePositive;
  final IconData icon;
  final Color? accentColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.change,
    this.changePositive = true,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppTheme.vermillion;
    return Container(
      padding: const EdgeInsets.all(20),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const Spacer(),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (changePositive ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        changePositive
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 9,
                        color: changePositive ? Colors.green[700] : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        change!,
                        style: TextStyle(
                          color:
                              changePositive ? Colors.green[700] : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// セクションヘッダー
class SectionHeader extends StatelessWidget {
  final String label;
  final Widget? action;
  final String? subtitle;

  const SectionHeader(
      {super.key, required this.label, this.action, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(height: 1, width: 16, color: AppTheme.vermillion),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 10),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

/// 数値フォーマッタ（カンマ区切り）
String formatNumber(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatCurrency(int yen) => '¥${formatNumber(yen)}';
