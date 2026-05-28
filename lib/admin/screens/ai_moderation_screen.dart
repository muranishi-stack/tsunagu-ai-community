import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';

class AdminAiModerationScreen extends StatefulWidget {
  const AdminAiModerationScreen({super.key});

  @override
  State<AdminAiModerationScreen> createState() =>
      _AdminAiModerationScreenState();
}

class _AdminAiModerationScreenState extends State<AdminAiModerationScreen> {
  AiFlagSeverity? _filterSeverity;
  AiFlagCategory? _filterCategory;
  AiFlagReviewStatus? _filterStatus = AiFlagReviewStatus.pending;
  AiModerationFlag? _selectedFlag;

  @override
  void initState() {
    super.initState();
    // 画面に来た時にスキャナーを起動
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = AdminService();
      if (svc.isLoggedIn && !svc.aiScannerStats.isRunning) {
        svc.startAiScanner();
      }
    });
  }

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
        final stats = service.aiScannerStats;
        final all = service.aiFlags;
        final filtered = all.where((f) {
          if (_filterSeverity != null && f.severity != _filterSeverity) {
            return false;
          }
          if (_filterCategory != null && f.category != _filterCategory) {
            return false;
          }
          if (_filterStatus != null && f.status != _filterStatus) {
            return false;
          }
          return true;
        }).toList();

        // 選択中のフラグも同期
        AiModerationFlag? syncedSelection;
        if (_selectedFlag != null) {
          try {
            syncedSelection =
                service.aiFlags.firstWhere((f) => f.id == _selectedFlag!.id);
          } catch (_) {
            syncedSelection = _selectedFlag;
          }
        }

        return AdminLayout(
          currentRoute: '/admin/ai-moderation',
          title: 'AI MODERATION',
          actions: [
            _ScannerControl(
              isRunning: stats.isRunning,
              onStart: () => service.startAiScanner(),
              onStop: () => service.stopAiScanner(),
              onScanNow: () {
                service.triggerAiScanNow();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('AI 巡回スキャンを実行しました'),
                    backgroundColor: AppTheme.black,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー説明
                    _PolicyBanner(),
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
                            label: 'CRITICAL',
                            value: stats.criticalCount.toString(),
                            change: stats.criticalCount > 0
                                ? 'URGENT'
                                : 'CLEAR',
                            changePositive: stats.criticalCount == 0,
                            icon: Icons.crisis_alert,
                          ),
                          StatCard(
                            label: 'PENDING REVIEW',
                            value: stats.pendingReviewCount.toString(),
                            icon: Icons.hourglass_empty,
                          ),
                          StatCard(
                            label: 'FLAGGED TODAY',
                            value: stats.totalFlaggedToday.toString(),
                            icon: Icons.flag_outlined,
                          ),
                          StatCard(
                            label: 'SCANNED TODAY',
                            value: formatNumber(stats.totalScannedToday),
                            change: stats.isRunning ? 'LIVE' : 'IDLE',
                            changePositive: stats.isRunning,
                            icon: Icons.radar,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 24),

                    // フィルタ
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
                                _DropdownFilter<AiFlagReviewStatus?>(
                                  label: 'ステータス',
                                  value: _filterStatus,
                                  items: [
                                    const _DropEntry<AiFlagReviewStatus?>(
                                        value: null, label: 'すべて'),
                                    ...AiFlagReviewStatus.values.map((s) =>
                                        _DropEntry<AiFlagReviewStatus?>(
                                            value: s, label: s.labelJa)),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _filterStatus = v),
                                ),
                                _DropdownFilter<AiFlagSeverity?>(
                                  label: '重大度',
                                  value: _filterSeverity,
                                  items: [
                                    const _DropEntry<AiFlagSeverity?>(
                                        value: null, label: 'すべて'),
                                    ...AiFlagSeverity.values.map((s) =>
                                        _DropEntry<AiFlagSeverity?>(
                                            value: s, label: s.labelJa)),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _filterSeverity = v),
                                ),
                                _DropdownFilter<AiFlagCategory?>(
                                  label: 'カテゴリ',
                                  value: _filterCategory,
                                  items: [
                                    const _DropEntry<AiFlagCategory?>(
                                        value: null, label: 'すべて'),
                                    ...AiFlagCategory.values.map((c) =>
                                        _DropEntry<AiFlagCategory?>(
                                            value: c, label: c.label)),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _filterCategory = v),
                                ),
                                if (_filterStatus != null ||
                                    _filterSeverity != null ||
                                    _filterCategory != null)
                                  TextButton.icon(
                                    onPressed: () => setState(() {
                                      _filterStatus = null;
                                      _filterSeverity = null;
                                      _filterCategory = null;
                                    }),
                                    icon: const Icon(Icons.clear,
                                        size: 14, color: AppTheme.grey),
                                    label: const Text('クリア',
                                        style: TextStyle(
                                            color: AppTheme.grey,
                                            fontSize: 12)),
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
                    const SizedBox(height: 16),

                    // フラグリスト
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
                              Icon(Icons.shield_outlined,
                                  size: 48, color: AppTheme.lightGrey),
                              SizedBox(height: 12),
                              Text(
                                '該当するフラグはありません',
                                style: TextStyle(
                                    color: AppTheme.grey, fontSize: 13),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'AI が定期的に巡回しています',
                                style: TextStyle(
                                    color: AppTheme.lightGrey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtered.map((flag) => _FlagCard(
                            flag: flag,
                            isSelected: syncedSelection?.id == flag.id,
                            onTap: () =>
                                setState(() => _selectedFlag = flag),
                          )),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // サイドパネル
              if (syncedSelection != null)
                _FlagDetailPanel(
                  key: ValueKey(syncedSelection.id),
                  flag: syncedSelection,
                  onClose: () => setState(() => _selectedFlag = null),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// ポリシーバナー (この機能の運用ポリシー)
// ============================================================================

class _PolicyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.black, AppTheme.charcoal],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.vermillion,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI 自動巡回 + 人間レビューモデル',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AIは規約違反・事件性のあるコンテンツをリスト化するのみ。実際の利用制限は、必ず管理者がトリガーを引きます。',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// スキャナーコントロール
// ============================================================================

class _ScannerControl extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onScanNow;
  const _ScannerControl({
    required this.isRunning,
    required this.onStart,
    required this.onStop,
    required this.onScanNow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isRunning
                ? Colors.green.withValues(alpha: 0.1)
                : AppTheme.paleGrey,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isRunning
                  ? Colors.green.withValues(alpha: 0.3)
                  : AppTheme.lightGrey,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isRunning ? Colors.green : AppTheme.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isRunning ? 'SCANNER ON' : 'SCANNER OFF',
                style: TextStyle(
                  color: isRunning ? Colors.green[700] : AppTheme.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.radar, size: 14),
          label: const Text(
            'SCAN NOW',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.black,
            side: const BorderSide(color: AppTheme.lightGrey),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2)),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onPressed: onScanNow,
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: Icon(
            isRunning ? Icons.pause : Icons.play_arrow,
            size: 14,
          ),
          label: Text(
            isRunning ? 'PAUSE' : 'START',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isRunning ? AppTheme.charcoal : AppTheme.vermillion,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: isRunning ? onStop : onStart,
        ),
      ],
    );
  }
}

// ============================================================================
// フラグカード
// ============================================================================

class _FlagCard extends StatelessWidget {
  final AiModerationFlag flag;
  final bool isSelected;
  final VoidCallback onTap;
  const _FlagCard({
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  Color get _severityColor {
    switch (flag.severity) {
      case AiFlagSeverity.critical:
        return AppTheme.vermillion;
      case AiFlagSeverity.high:
        return Colors.orange;
      case AiFlagSeverity.medium:
        return Colors.amber[700]!;
      case AiFlagSeverity.low:
        return AppTheme.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(color: _severityColor, width: 4),
            top: BorderSide(
                color: isSelected ? _severityColor : Colors.transparent,
                width: 1),
            right: BorderSide(
                color: isSelected ? _severityColor : Colors.transparent,
                width: 1),
            bottom: BorderSide(
                color: isSelected ? _severityColor : Colors.transparent,
                width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _severityColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー行
            Row(
              children: [
                _severityBadge(),
                const SizedBox(width: 8),
                _statusBadge(),
                const SizedBox(width: 8),
                _sourceBadge(),
                const Spacer(),
                Text(
                  flag.id,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatTime(flag.detectedAt),
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // カテゴリ + 信頼度 + ユーザー
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.paleGrey,
                        backgroundImage:
                            NetworkImage(flag.targetUserAvatar),
                        onBackgroundImageError: (_, __) {},
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              flag.targetUserName,
                              style: const TextStyle(
                                color: AppTheme.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              flag.targetUserId,
                              style: const TextStyle(
                                color: AppTheme.grey,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
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
                    flag.category.label,
                    style: const TextStyle(
                      color: AppTheme.vermillion,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ConfidenceMeter(confidence: flag.confidence),
              ],
            ),
            const SizedBox(height: 14),
            // 検出内容 (ハイライト付き)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.offWhite,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                    color: AppTheme.paleGrey, width: 1),
              ),
              child: _HighlightedText(
                text: flag.content,
                keywords: flag.matchedKeywords,
                style: const TextStyle(
                  color: AppTheme.charcoal,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 詳細を見るボタンのインジケータ
            Row(
              children: [
                Icon(Icons.psychology_outlined,
                    size: 13, color: _severityColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    flag.aiReasoning,
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isSelected ? '詳細表示中' : 'タップで詳細・対応',
                  style: TextStyle(
                    color: _severityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 14, color: _severityColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _severityColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flag.severity == AiFlagSeverity.critical) ...[
            const Icon(Icons.warning_amber_rounded,
                size: 11, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            flag.severity.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    Color color;
    switch (flag.status) {
      case AiFlagReviewStatus.pending:
        color = Colors.blue;
        break;
      case AiFlagReviewStatus.underReview:
        color = Colors.orange;
        break;
      case AiFlagReviewStatus.confirmed:
        color = AppTheme.vermillion;
        break;
      case AiFlagReviewStatus.falsePositive:
        color = AppTheme.grey;
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
        flag.status.labelJa,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sourceBadge() {
    IconData icon;
    switch (flag.source) {
      case AiFlagSource.message:
        icon = Icons.chat_bubble_outline;
        break;
      case AiFlagSource.profile:
        icon = Icons.person_outline;
        break;
      case AiFlagSource.photo:
        icon = Icons.image_outlined;
        break;
      case AiFlagSource.username:
        icon = Icons.badge_outlined;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.paleGrey,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.charcoal),
          const SizedBox(width: 4),
          Text(
            flag.source.englishLabel,
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
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

// ============================================================================
// 信頼度メーター
// ============================================================================

class _ConfidenceMeter extends StatelessWidget {
  final double confidence;
  const _ConfidenceMeter({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = confidence >= 0.9
        ? AppTheme.vermillion
        : confidence >= 0.75
            ? Colors.orange
            : Colors.amber[700]!;
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 3,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ハイライト付きテキスト
// ============================================================================

class _HighlightedText extends StatelessWidget {
  final String text;
  final List<String> keywords;
  final TextStyle style;
  const _HighlightedText({
    required this.text,
    required this.keywords,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return Text(text, style: style);

    final spans = <TextSpan>[];
    String remaining = text;

    // 全マッチ位置を見つけて分割
    while (remaining.isNotEmpty) {
      int matchStart = -1;
      String? matchedKw;
      for (final kw in keywords) {
        if (kw.isEmpty) continue;
        final idx = remaining.indexOf(kw);
        if (idx >= 0 && (matchStart == -1 || idx < matchStart)) {
          matchStart = idx;
          matchedKw = kw;
        }
      }
      if (matchStart == -1 || matchedKw == null) {
        spans.add(TextSpan(text: remaining, style: style));
        break;
      }
      if (matchStart > 0) {
        spans.add(
            TextSpan(text: remaining.substring(0, matchStart), style: style));
      }
      spans.add(TextSpan(
        text: matchedKw,
        style: style.copyWith(
          color: AppTheme.vermillionDark,
          fontWeight: FontWeight.w700,
          backgroundColor: AppTheme.vermillionPale,
        ),
      ));
      remaining = remaining.substring(matchStart + matchedKw.length);
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

// ============================================================================
// 詳細サイドパネル + 対応アクション
// ============================================================================

class _FlagDetailPanel extends StatefulWidget {
  final AiModerationFlag flag;
  final VoidCallback onClose;
  const _FlagDetailPanel({
    super.key,
    required this.flag,
    required this.onClose,
  });

  @override
  State<_FlagDetailPanel> createState() => _FlagDetailPanelState();
}

class _FlagDetailPanelState extends State<_FlagDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
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

  Color get _severityColor {
    switch (widget.flag.severity) {
      case AiFlagSeverity.critical:
        return AppTheme.vermillion;
      case AiFlagSeverity.high:
        return Colors.orange;
      case AiFlagSeverity.medium:
        return Colors.amber[700]!;
      case AiFlagSeverity.low:
        return AppTheme.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width >= 1100
        ? 480.0
        : width >= 900
            ? 440.0
            : width * 0.94;

    return Positioned.fill(
      child: Stack(
        children: [
          FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _animatedClose,
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
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
                  child: _buildPanelContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent() {
    final flag = widget.flag;
    final isResolved = flag.status == AiFlagReviewStatus.confirmed ||
        flag.status == AiFlagReviewStatus.falsePositive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー (重大度カラー)
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _severityColor,
                _severityColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      flag.severity.label,
                      style: TextStyle(
                        color: _severityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 18),
                    onPressed: _animatedClose,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                flag.category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Flag ID: ${flag.id} · ${_formatDateTime(flag.detectedAt)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
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
                // 対象ユーザー
                const _SectionLabel('対象ユーザー'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.paleGrey,
                        backgroundImage:
                            NetworkImage(flag.targetUserAvatar),
                        onBackgroundImageError: (_, __) {},
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flag.targetUserName,
                              style: const TextStyle(
                                color: AppTheme.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              flag.targetUserId,
                              style: const TextStyle(
                                color: AppTheme.grey,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // AIの判定
                const _SectionLabel('AIの判定理由'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: _severityColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, size: 14,
                              color: _severityColor),
                          const SizedBox(width: 6),
                          Text(
                            '信頼度 ${(flag.confidence * 100).round()}%',
                            style: TextStyle(
                              color: _severityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _severityColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              flag.category.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        flag.aiReasoning,
                        style: const TextStyle(
                          color: AppTheme.charcoal,
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 検出内容
                _SectionLabel('検出内容 (${flag.source.label})'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.paleGrey),
                  ),
                  child: _HighlightedText(
                    text: flag.content,
                    keywords: flag.matchedKeywords,
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ),
                if (flag.matchedKeywords.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: flag.matchedKeywords
                        .map((kw) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.vermillionPale,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                kw,
                                style: const TextStyle(
                                  color: AppTheme.vermillion,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // 対応履歴 or アクション
                if (isResolved) ...[
                  const _SectionLabel('対応履歴'),
                  const SizedBox(height: 10),
                  _buildResolutionInfo(flag),
                ] else ...[
                  const _SectionLabel('管理者の判断'),
                  const SizedBox(height: 6),
                  const Text(
                    'AI はリスト化のみを行います。実際の制限は以下から選択してください。',
                    style: TextStyle(
                      color: AppTheme.grey,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildActionButtons(),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionInfo(AiModerationFlag flag) {
    final isFalsePositive =
        flag.status == AiFlagReviewStatus.falsePositive;
    final color = isFalsePositive ? AppTheme.grey : AppTheme.vermillion;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFalsePositive
                    ? Icons.do_not_disturb_alt
                    : Icons.gavel,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isFalsePositive ? '誤検知として却下' : '違反確定 → 制限実行済',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          if (flag.appliedEnforcement != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('実行アクション:',
                    style: TextStyle(
                        color: AppTheme.grey,
                        fontSize: 11,
                        letterSpacing: 0.5)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    flag.appliedEnforcement!.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (flag.reviewedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '対応日時: ${_formatDateTime(flag.reviewedAt!)}',
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 11,
              ),
            ),
          ],
          if (flag.reviewerNote != null && flag.reviewerNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                flag.reviewerNote!,
                style: const TextStyle(
                    color: AppTheme.charcoal, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final flag = widget.flag;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (flag.status == AiFlagReviewStatus.pending)
          OutlinedButton.icon(
            icon: const Icon(Icons.search, size: 14),
            label: const Text(
              'レビュー開始',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.black,
              side: const BorderSide(color: AppTheme.lightGrey),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              AdminService().startReviewAiFlag(flag.id);
            },
          ),
        if (flag.status == AiFlagReviewStatus.pending)
          const SizedBox(height: 12),

        // CRITICAL なら警察相談を強調
        if (flag.severity == AiFlagSeverity.critical) ...[
          _ActionButton(
            icon: Icons.local_police_outlined,
            label: '警察相談・通報 (CRITICAL)',
            description: '事件性ありと判断。警察庁・所轄署への相談を行います',
            color: AppTheme.vermillion,
            isPrimary: true,
            onPressed: () => _confirmEnforcement(
              AiFlagEnforcement.policeReport,
            ),
          ),
          const SizedBox(height: 8),
        ],

        _ActionButton(
          icon: Icons.block,
          label: 'アカウント凍結',
          description: 'このユーザーは即時にサービス利用不可になります',
          color: AppTheme.vermillion,
          isPrimary:
              flag.severity == AiFlagSeverity.high,
          onPressed: () => _confirmEnforcement(AiFlagEnforcement.suspend),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.access_time,
          label: '48時間機能制限',
          description: 'メッセージ送信・新規マッチを48時間停止',
          color: Colors.orange,
          onPressed: () =>
              _confirmEnforcement(AiFlagEnforcement.feature48hLimit),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.delete_outline,
          label: 'コンテンツ削除',
          description: '当該メッセージ/写真/プロフィール記述のみを削除',
          color: AppTheme.charcoal,
          onPressed: () =>
              _confirmEnforcement(AiFlagEnforcement.contentRemoval),
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.warning_amber_outlined,
          label: '警告通知のみ',
          description: 'プッシュ通知で本人に注意喚起',
          color: Colors.blue,
          onPressed: () =>
              _confirmEnforcement(AiFlagEnforcement.warning),
        ),
        const SizedBox(height: 20),
        const Divider(color: AppTheme.paleGrey, height: 1),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.do_not_disturb_alt, size: 14),
          label: const Text(
            '誤検知として却下',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.grey,
            side: const BorderSide(color: AppTheme.lightGrey),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2)),
          ),
          onPressed: _confirmFalsePositive,
        ),
      ],
    );
  }

  void _confirmEnforcement(AiFlagEnforcement enforcement) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          '${enforcement.label} を実行しますか？',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.offWhite,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '対象: ${widget.flag.targetUserName} (${widget.flag.targetUserId})',
                        style: const TextStyle(
                          color: AppTheme.charcoal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '対応メモ (任意)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('キャンセル', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _severityColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AdminService().confirmAiFlagViolation(
                flagId: widget.flag.id,
                enforcement: enforcement,
                reviewerNote: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${enforcement.label} を実行しました'),
                    backgroundColor: AppTheme.black,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('実行',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  void _confirmFalsePositive() {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          '誤検知として却下しますか？',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'このフラグは違反ではないと判断します。AIモデルの精度改善のためフィードバックされます。',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '理由 (任意)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('キャンセル', style: TextStyle(color: AppTheme.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.grey,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AdminService().dismissAiFlagAsFalsePositive(
                widget.flag.id,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('誤検知として却下しました'),
                    backgroundColor: AppTheme.black,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('却下',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isPrimary;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPrimary ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isPrimary
                ? color.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.2),
            width: isPrimary ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<_DropEntry<T>> items;
  final ValueChanged<T?> onChanged;
  const _DropdownFilter({
    required this.label,
    required this.value,
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
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
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

class _DropEntry<T> {
  final T value;
  final String label;
  const _DropEntry({required this.value, required this.label});
}
