// ActionScreen — アクション
// =====================================================
// 3 セクション:
//  1. あなたへのいいね（相手から届いたいいね/つなぐ）— ここからいいね返し可能
//  2. AIおすすめ TOP5（相性スコア上位）— ここからいいね可能
//  3. 送ったいいね（自分が送ったいいね）
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/ai_matching_service.dart';
import '../services/user_preferences.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'profile_detail_screen.dart';

class ActionScreen extends StatefulWidget {
  const ActionScreen({super.key});

  @override
  State<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends State<ActionScreen> {
  final _svc = UserService();
  final _prefs = UserPreferences();

  bool _loading = true;
  List<UserProfile> _likesReceived = [];
  List<ScoredProfile> _aiTop5 = [];
  List<UserProfile> _myLikes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = _svc.currentUid;
      final results = await Future.wait([
        _svc.getLikesReceived(),
        _svc.getMyLikes(),
        if (uid != null)
          _svc.discoverUsers(
            currentUid: uid,
            excludeUids: {
              ...await _svc.getSwipedUids(uid),
              ...await _svc.getBlockedUids(),
            },
            limit: 100,
          )
        else
          Future.value(<UserProfile>[]),
      ]);
      final received = results[0];
      final myLikes = results[1];
      final candidates = results[2];

      final ranked = AIMatchingService.rankProfiles(
        profiles: candidates,
        desiredCategory: _prefs.primaryCategory,
        self: _prefs.myProfile,
      ).take(5).toList();

      if (!mounted) return;
      setState(() {
        _likesReceived = received;
        _myLikes = myLikes;
        _aiTop5 = ranked;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _like(UserProfile p, {bool superLike = false}) async {
    final uid = _svc.currentUid;
    if (uid == null) return;
    try {
      final matchId = await _svc.recordSwipe(
        fromUid: uid,
        toUid: p.id,
        liked: true,
        isSuperLike: superLike,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(matchId != null
              ? '${p.name} と MATCH!! 🎉 マッチ画面でメッセージを送れます'
              : '${p.name} に${superLike ? "「つなぐ」" : "「いいね」"}を送りました'),
        ),
      );
      _load(); // 一覧を更新
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アクション',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2.0)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.vermillion)))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.vermillion,
              child: ListView(
                children: [
                  _sectionHeader(
                      'あなたへのいいね', _likesReceived.length, Icons.favorite),
                  if (_likesReceived.isEmpty)
                    _emptyHint('まだいいねは届いていません')
                  else
                    ..._likesReceived.map((p) => _tile(p,
                        canLikeBack: true,
                        subtitle: 'あなたにいいねしています')),
                  const SizedBox(height: 8),
                  _sectionHeader('AIおすすめ TOP5', _aiTop5.length,
                      Icons.auto_awesome),
                  if (_aiTop5.isEmpty)
                    _emptyHint('おすすめできる相手が見つかりませんでした')
                  else
                    ..._aiTop5.map((s) => _tile(s.profile,
                        canLikeBack: true,
                        aiScore: s.score,
                        subtitle: '相性スコア ${s.score}')),
                  const SizedBox(height: 8),
                  _sectionHeader('送ったいいね', _myLikes.length, Icons.send),
                  if (_myLikes.isEmpty)
                    _emptyHint('まだいいねを送っていません')
                  else
                    ..._myLikes.map((p) => _tile(p,
                        canLikeBack: false,
                        subtitle: '返信待ち')),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, int count, IconData icon) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.vermillion),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.vermillion.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.vermillion,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 13, color: AppTheme.textTertiary(context))),
      );

  Widget _tile(UserProfile p,
      {required bool canLikeBack, String? subtitle, int? aiScore}) {
    return ListTile(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: p))),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.surfaceVariant(context),
        backgroundImage:
            p.photos.isNotEmpty ? NetworkImage(p.photos.first) : null,
        child: p.photos.isEmpty
            ? Icon(Icons.person, color: AppTheme.textTertiary(context))
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text('${p.name}  ${p.age}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15),
                overflow: TextOverflow.ellipsis),
          ),
          if (aiScore != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.vermillion,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('AI $aiScore',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: canLikeBack
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.link, color: AppTheme.vermillion),
                  tooltip: 'つなぐ',
                  onPressed: () => _like(p, superLike: true),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.favorite, color: AppTheme.vermillion),
                  tooltip: 'いいね',
                  onPressed: () => _like(p),
                ),
              ],
            )
          : const Icon(Icons.schedule, size: 18, color: AppTheme.lightGrey),
    );
  }
}
