// RecommendScreen — レコメンド（本日のAI TOP10）
// =====================================================
// AIスコアオプション（月額580円）加入者のみ。Gemini が相性を判定した
// 本日の上位10人を表示。非加入者にはアップセルを表示。
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/ai_matching_service.dart';
import '../services/ai_profile_service.dart';
import '../services/subscription_service.dart';
import '../services/user_preferences.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'profile_detail_screen.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final _svc = UserService();
  final _prefs = UserPreferences();
  final _sub = SubscriptionService();
  final _ai = AiProfileService();

  bool _loading = false;
  String? _error;
  List<_RankedProfile> _items = [];

  @override
  void initState() {
    super.initState();
    _sub.addListener(_onSub);
    if (_sub.hasAiScoreOption) _load();
  }

  @override
  void dispose() {
    _sub.removeListener(_onSub);
    super.dispose();
  }

  void _onSub() {
    if (!mounted) return;
    setState(() {});
    if (_sub.hasAiScoreOption && _items.isEmpty && !_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _svc.currentUid;
      if (uid == null) throw Exception('ログインが必要です');

      // 候補取得 → ローカルスコアで上位30に絞る（コスト対策）
      final candidates = await _svc.discoverUsers(
        currentUid: uid,
        excludeUids: {
          ...await _svc.getSwipedUids(uid),
          ...await _svc.getBlockedUids(),
        },
        limit: 100,
      );
      final pre = AIMatchingService.rankProfiles(
        profiles: candidates,
        desiredCategory: _prefs.primaryCategory,
        self: _prefs.myProfile,
      ).take(30).map((s) => s.profile).toList();

      if (pre.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }

      final selfProfile = await _svc.getCurrentUserProfile();
      final self = {
        'age': selfProfile?.age ?? _prefs.age,
        'occupation': selfProfile?.occupation ?? _prefs.occupation,
        'interests': selfProfile?.interests ?? _prefs.interests,
        'primaryCategory': _prefs.primaryCategory.name,
        'bio': selfProfile?.bio ?? '',
      };
      final candPayload = pre
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'age': p.age,
                'category': p.primaryCategory.name,
                'interests': p.interests,
                'bio': p.bio,
                'prefecture': p.prefecture,
              })
          .toList();

      final recs = await _ai.recommendTop(self: self, candidates: candPayload);
      final byId = {for (final p in pre) p.id: p};
      final ranked = <_RankedProfile>[];
      for (final r in recs) {
        final p = byId[r.id];
        if (p != null) {
          ranked.add(_RankedProfile(p, r.score, r.reason));
        }
      }
      if (!mounted) return;
      setState(() {
        _items = ranked;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _like(UserProfile p, {bool superLike = false}) async {
    final uid = _svc.currentUid;
    if (uid == null) return;
    try {
      final matchId = await _svc.recordSwipe(
          fromUid: uid, toUid: p.id, liked: true, isSuperLike: superLike);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(matchId != null
                ? '${p.name} と MATCH!! 🎉'
                : '${p.name} に${superLike ? "「つなぐ」" : "「いいね」"}を送りました')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レコメンド',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2.0)),
        actions: [
          if (_sub.hasAiScoreOption)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loading ? null : _load,
            ),
        ],
      ),
      body: _sub.hasAiScoreOption ? _buildContent() : _buildUpsell(),
    );
  }

  // ───── 加入者向けコンテンツ ─────
  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.vermillion)),
            SizedBox(height: 16),
            Text('AIが本日のおすすめを分析中…',
                style: TextStyle(fontSize: 13, color: AppTheme.grey)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('再試行')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('本日のおすすめが見つかりませんでした'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.vermillion,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: AppTheme.vermillion, size: 18),
                  SizedBox(width: 8),
                  Text('本日のAIおすすめ TOP10',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }
          return _rankTile(i, _items[i - 1]);
        },
      ),
    );
  }

  Widget _rankTile(int rank, _RankedProfile rp) {
    final p = rp.profile;
    return ListTile(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: p))),
      leading: SizedBox(
        width: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.surfaceVariant(context),
              backgroundImage:
                  p.photos.isNotEmpty ? NetworkImage(p.photos.first) : null,
              child: p.photos.isEmpty
                  ? Icon(Icons.person, color: AppTheme.textTertiary(context))
                  : null,
            ),
            Positioned(
              left: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: rank <= 3 ? AppTheme.vermillion : AppTheme.charcoal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$rank',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text('${p.name}  ${p.age}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.vermillion,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('AI ${rp.score}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      subtitle: rp.reason.isNotEmpty
          ? Text(rp.reason,
              style: const TextStyle(fontSize: 12), maxLines: 2)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.link, color: AppTheme.vermillion),
            tooltip: 'つなぐ',
            onPressed: () => _like(p, superLike: true),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: AppTheme.vermillion),
            tooltip: 'いいね',
            onPressed: () => _like(p),
          ),
        ],
      ),
    );
  }

  // ───── 非加入者向けアップセル ─────
  Widget _buildUpsell() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.vermillion.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppTheme.vermillion, size: 36),
            ),
            const SizedBox(height: 24),
            const Text('AIスコアオプション',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              'AIがあなたとの相性を判定し、本日のおすすめ TOP10 と\nマッチ度スコアを表示します。',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 24),
            _feature('本日のAIおすすめ TOP10'),
            _feature('Gemini によるマッチ度スコア'),
            _feature('相性が高い理由の表示'),
            const SizedBox(height: 28),
            Text('月額 ¥${SubscriptionService.aiScorePriceJpy}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.vermillion)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vermillion,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('オプションに申し込む',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, letterSpacing: 1.0)),
              ),
            ),
            const SizedBox(height: 12),
            Text('いつでも解約できます',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textTertiary(context))),
          ],
        ),
      ),
    );
  }

  Widget _feature(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: AppTheme.vermillion, size: 18),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );

  Future<void> _confirmSubscribe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AIスコアオプション'),
        content: Text(
            '月額 ¥${SubscriptionService.aiScorePriceJpy} で AIレコメンドとマッチ度スコアを利用できます。\n'
            '（デモ環境のため実際の課金は発生しません）'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('申し込む',
                  style: TextStyle(color: AppTheme.vermillion))),
        ],
      ),
    );
    if (ok != true) return;
    await _sub.subscribeAiScore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AIスコアオプションを有効にしました')),
    );
  }
}

class _RankedProfile {
  final UserProfile profile;
  final int score;
  final String reason;
  _RankedProfile(this.profile, this.score, this.reason);
}
