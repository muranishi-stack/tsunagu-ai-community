import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';

class AdminDataSourcesScreen extends StatefulWidget {
  const AdminDataSourcesScreen({super.key});

  @override
  State<AdminDataSourcesScreen> createState() =>
      _AdminDataSourcesScreenState();
}

class _AdminDataSourcesScreenState extends State<AdminDataSourcesScreen> {
  DataSourceProvider? _selectedProvider;

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
        final sources = service.dataSources;
        final activeCount = sources
            .where((s) => s.status == DataSourceStatus.active)
            .length;
        final configuredCount = sources
            .where((s) => s.status == DataSourceStatus.configured)
            .length;
        final totalImported = service.totalImportedRecords;

        // カテゴリ別グルーピング
        final byCategory = <String, List<DataSourceIntegration>>{};
        for (final s in sources) {
          final cat = s.provider.category;
          byCategory.putIfAbsent(cat, () => []).add(s);
        }
        // 推奨度順
        for (final entry in byCategory.entries) {
          entry.value.sort((a, b) => b.provider.recommendationLevel
              .compareTo(a.provider.recommendationLevel));
        }

        DataSourceIntegration? selected;
        if (_selectedProvider != null) {
          try {
            selected = sources
                .firstWhere((s) => s.provider == _selectedProvider);
          } catch (_) {}
        }

        return AdminLayout(
          currentRoute: '/admin/data-sources',
          title: 'DATA SOURCES',
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヒーローバナー
                    _IntroBanner(),
                    const SizedBox(height: 24),

                    // KPI
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
                            label: 'ACTIVE',
                            value: activeCount.toString(),
                            change: 'CONNECTED',
                            changePositive: activeCount > 0,
                            icon: Icons.link,
                          ),
                          StatCard(
                            label: 'CONFIGURED',
                            value: configuredCount.toString(),
                            icon: Icons.settings_outlined,
                          ),
                          StatCard(
                            label: 'TOTAL SOURCES',
                            value: sources.length.toString(),
                            icon: Icons.dns_outlined,
                          ),
                          StatCard(
                            label: 'IMPORTED',
                            value: formatNumber(totalImported),
                            icon: Icons.cloud_download_outlined,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 32),

                    // 提案バナー (立ち上げ期向け)
                    _LaunchProposal(
                      onUseSyntheticSeed: () =>
                          _runSync(DataSourceProvider.syntheticSeed),
                    ),
                    const SizedBox(height: 32),

                    // カテゴリ別リスト
                    for (final entry in _orderedCategories(byCategory)) ...[
                      SectionHeader(label: entry.key),
                      const SizedBox(height: 12),
                      for (final s in entry.value)
                        _SourceCard(
                          source: s,
                          isSelected: s.provider == _selectedProvider,
                          onTap: () => setState(
                              () => _selectedProvider = s.provider),
                          onToggle: () =>
                              service.toggleDataSource(
                                  s.provider,
                                  s.status != DataSourceStatus.active),
                          onSync: () => _runSync(s.provider),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),

              // 詳細パネル
              if (selected != null)
                _SourceDetailPanel(
                  key: ValueKey(selected.provider),
                  source: selected,
                  onClose: () => setState(() => _selectedProvider = null),
                  onSync: () => _runSync(selected!.provider),
                  onToggle: () => service.toggleDataSource(
                      selected!.provider,
                      selected.status != DataSourceStatus.active),
                ),
            ],
          ),
        );
      },
    );
  }

  Iterable<MapEntry<String, List<DataSourceIntegration>>>
      _orderedCategories(Map<String, List<DataSourceIntegration>> map) {
    const order = ['認証・ID', 'イベント・シード', 'ソーシャル', '内部ツール'];
    final entries = <MapEntry<String, List<DataSourceIntegration>>>[];
    for (final cat in order) {
      if (map.containsKey(cat)) {
        entries.add(MapEntry(cat, map[cat]!));
      }
    }
    return entries;
  }

  Future<void> _runSync(DataSourceProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${provider.displayName} のデータ取り込みを開始しました...'),
        backgroundColor: AppTheme.charcoal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
    final delta = await AdminService().runDataSourceSync(provider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${provider.displayName} から $delta 件取り込みました'),
        backgroundColor: AppTheme.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// ヒーローバナー
// ============================================================================

class _IntroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.black, AppTheme.charcoal],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.vermillion,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'LAUNCH PHASE TOOL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  '🇯🇵 国内サービス限定',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'データ取り込みセンター',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '立ち上げ初期のコンテンツ空白を防ぐため、国内のサービスと連携してプロフィール・イベント情報・認証情報を取り込みます。\n本人同意とサービス規約に従って利用してください。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 立ち上げ期の推奨構成バナー
// ============================================================================

class _LaunchProposal extends StatelessWidget {
  final VoidCallback onUseSyntheticSeed;
  const _LaunchProposal({required this.onUseSyntheticSeed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.vermillionPale, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vermillion.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.vermillion,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TSUNAGU ローンチ時の推奨構成',
                style: TextStyle(
                  color: AppTheme.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProposalStep(
            number: '01',
            title: '認証基盤を整備',
            services: ['Apple ID', 'Google サインイン', 'Yahoo! JAPAN ID'],
            description:
                'iOS必須のApple、Android用Google、国内で広く認知されるYahoo!の3つを揃えれば、ほぼ全ユーザーをカバー可能。',
          ),
          const SizedBox(height: 12),
          _ProposalStep(
            number: '02',
            title: 'LINE 公式アカウントで集客',
            services: ['LINE 公式アカウント'],
            description:
                '日本人の80%超が利用するLINEで公式アカウントを開設。友だち追加 → 招待リンク → アプリインストールの導線を作成。',
          ),
          const SizedBox(height: 12),
          _ProposalStep(
            number: '03',
            title: 'イベント連動でコンテンツ強化',
            services: ['Connpass', 'Doorkeeper'],
            description:
                '「学び」「仕事」「趣味」カテゴリ用のイベント情報を表示。イベント参加予定者同士のマッチングを提案。',
          ),
          const SizedBox(height: 12),
          _ProposalStep(
            number: '04',
            title: 'シードデータで「賑わい感」を演出',
            services: ['シードデータ生成'],
            description:
                'ローンチ直後のデータ空白を回避。架空ユーザーで管理画面UIの検証や社内デモも可能。本番リリース時は無効化。',
            actionLabel: '今すぐ生成',
            onAction: onUseSyntheticSeed,
          ),
        ],
      ),
    );
  }
}

class _ProposalStep extends StatelessWidget {
  final String number;
  final String title;
  final List<String> services;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _ProposalStep({
    required this.number,
    required this.title,
    required this.services,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.black,
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: services
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.vermillionPale,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                color: AppTheme.vermillion,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vermillion,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2)),
              ),
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// データソースカード
// ============================================================================

class _SourceCard extends StatelessWidget {
  final DataSourceIntegration source;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onSync;
  const _SourceCard({
    required this.source,
    required this.isSelected,
    required this.onTap,
    required this.onToggle,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = source.status == DataSourceStatus.active;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(color: AppTheme.vermillion, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.vermillion.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // プロバイダーロゴエリア
            _ProviderLogo(provider: source.provider),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        source.provider.displayName,
                        style: const TextStyle(
                          color: AppTheme.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RecommendationStars(
                          level: source.provider.recommendationLevel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source.purpose,
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 11,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: source.status),
                const SizedBox(height: 6),
                Text(
                  source.importedRecords > 0
                      ? '${formatNumber(source.importedRecords)} 件取込'
                      : '未取込',
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 11,
                  ),
                ),
                if (source.lastSyncAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '最終: ${_formatTime(source.lastSyncAt!)}',
                    style: const TextStyle(
                      color: AppTheme.lightGrey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.sync, size: 12),
                  label: const Text('SYNC',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: const Size(72, 28),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  onPressed: onSync,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 72,
                  child: Switch(
                    value: isActive,
                    activeThumbColor: AppTheme.vermillion,
                    onChanged: (_) => onToggle(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}

class _StatusBadge extends StatelessWidget {
  final DataSourceStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case DataSourceStatus.active:
        color = Colors.green;
        break;
      case DataSourceStatus.configured:
        color = Colors.blue;
        break;
      case DataSourceStatus.notConfigured:
        color = AppTheme.lightGrey;
        break;
      case DataSourceStatus.error:
        color = AppTheme.vermillion;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _RecommendationStars extends StatelessWidget {
  final int level; // 0-3
  const _RecommendationStars({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Icon(
          Icons.star,
          size: 11,
          color: i < level ? AppTheme.vermillion : AppTheme.paleGrey,
        );
      }),
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  final DataSourceProvider provider;
  const _ProviderLogo({required this.provider});

  @override
  Widget build(BuildContext context) {
    final spec = _ProviderLogoSpec.forProvider(provider);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: spec.bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.paleGrey),
      ),
      alignment: Alignment.center,
      child: spec.icon != null
          ? Icon(spec.icon, color: spec.fgColor, size: 24)
          : Text(
              spec.text ?? '?',
              style: TextStyle(
                color: spec.fgColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}

class _ProviderLogoSpec {
  final Color bgColor;
  final Color fgColor;
  final IconData? icon;
  final String? text;
  const _ProviderLogoSpec({
    required this.bgColor,
    required this.fgColor,
    this.icon,
    this.text,
  });

  static _ProviderLogoSpec forProvider(DataSourceProvider p) {
    switch (p) {
      case DataSourceProvider.lineOfficial:
        return const _ProviderLogoSpec(
          bgColor: Color(0xFF06C755),
          fgColor: Colors.white,
          icon: Icons.chat_bubble,
        );
      case DataSourceProvider.yahooJapan:
        return const _ProviderLogoSpec(
          bgColor: Color(0xFFFF0033),
          fgColor: Colors.white,
          text: 'Y!',
        );
      case DataSourceProvider.apple:
        return const _ProviderLogoSpec(
          bgColor: Colors.black,
          fgColor: Colors.white,
          icon: Icons.apple,
        );
      case DataSourceProvider.google:
        return const _ProviderLogoSpec(
          bgColor: Colors.white,
          fgColor: Color(0xFF4285F4),
          text: 'G',
        );
      case DataSourceProvider.connpass:
        return const _ProviderLogoSpec(
          bgColor: Color(0xFFF59500),
          fgColor: Colors.white,
          icon: Icons.event,
        );
      case DataSourceProvider.doorkeeper:
        return const _ProviderLogoSpec(
          bgColor: Color(0xFF1A4571),
          fgColor: Colors.white,
          icon: Icons.meeting_room,
        );
      case DataSourceProvider.xJapan:
        return const _ProviderLogoSpec(
          bgColor: Colors.black,
          fgColor: Colors.white,
          text: 'X',
        );
      case DataSourceProvider.facebook:
        return const _ProviderLogoSpec(
          bgColor: Color(0xFF1877F2),
          fgColor: Colors.white,
          icon: Icons.facebook,
        );
      case DataSourceProvider.syntheticSeed:
        return const _ProviderLogoSpec(
          bgColor: AppTheme.vermillion,
          fgColor: Colors.white,
          icon: Icons.auto_awesome,
        );
    }
  }
}

// ============================================================================
// 詳細パネル
// ============================================================================

class _SourceDetailPanel extends StatefulWidget {
  final DataSourceIntegration source;
  final VoidCallback onClose;
  final VoidCallback onSync;
  final VoidCallback onToggle;
  const _SourceDetailPanel({
    super.key,
    required this.source,
    required this.onClose,
    required this.onSync,
    required this.onToggle,
  });

  @override
  State<_SourceDetailPanel> createState() => _SourceDetailPanelState();
}

class _SourceDetailPanelState extends State<_SourceDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 280), vsync: this);
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animatedClose() async {
    await _ctrl.reverse();
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width >= 1100
        ? 480.0
        : width >= 900
            ? 440.0
            : width * 0.94;
    final s = widget.source;

    return Positioned.fill(
      child: Stack(
        children: [
          FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _animatedClose,
              child: Container(
                  color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SlideTransition(
              position: _slide,
              child: Material(
                elevation: 16,
                color: Colors.white,
                child: SizedBox(
                  width: panelWidth,
                  height: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ヘッダー
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.black, AppTheme.charcoal],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _ProviderLogo(provider: s.provider),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.provider.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _StatusBadge(status: s.status),
                                          const SizedBox(width: 8),
                                          _RecommendationStars(
                                              level: s.provider
                                                  .recommendationLevel),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white, size: 18),
                                  onPressed: _animatedClose,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 本文
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel('利用目的'),
                              const SizedBox(height: 10),
                              Text(
                                s.purpose,
                                style: const TextStyle(
                                  color: AppTheme.charcoal,
                                  fontSize: 13,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const _SectionLabel('セットアップ方法'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.offWhite,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.howToSetup,
                                  style: const TextStyle(
                                    color: AppTheme.charcoal,
                                    fontSize: 12,
                                    height: 1.7,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const _SectionLabel('法的・規約上の注意'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: Colors.amber
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.gavel,
                                        size: 14,
                                        color: Colors.amber[800]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.legalNote,
                                        style: TextStyle(
                                          color: Colors.amber[900],
                                          fontSize: 12,
                                          height: 1.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _SectionLabel('取り込み統計'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.offWhite,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('累計取り込み件数',
                                            style: TextStyle(
                                                color: AppTheme.grey,
                                                fontSize: 12)),
                                        Text(
                                          formatNumber(s.importedRecords),
                                          style: const TextStyle(
                                            color: AppTheme.vermillion,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('最終同期',
                                            style: TextStyle(
                                                color: AppTheme.grey,
                                                fontSize: 12)),
                                        Text(
                                          s.lastSyncAt != null
                                              ? _formatDateTime(
                                                  s.lastSyncAt!)
                                              : '未同期',
                                          style: const TextStyle(
                                            color: AppTheme.charcoal,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _SectionLabel('アクション'),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.sync, size: 16),
                                  label: const Text(
                                    'データ取り込みを実行',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.vermillion,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(2)),
                                  ),
                                  onPressed: widget.onSync,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: Icon(
                                    s.status == DataSourceStatus.active
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    size: 16,
                                  ),
                                  label: Text(
                                    s.status == DataSourceStatus.active
                                        ? '連携を停止'
                                        : '連携を有効化',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.black,
                                    side: const BorderSide(
                                        color: AppTheme.lightGrey),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(2)),
                                  ),
                                  onPressed: widget.onToggle,
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 12, color: AppTheme.vermillion),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
