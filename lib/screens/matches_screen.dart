// MatchesScreen — Firestoreのmatchesコレクションから取得
// =====================================================
// Phase 1.5 - TSUNAGU
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/boost_button.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _svc = UserService();

  @override
  Widget build(BuildContext context) {
    final uid = _svc.currentUid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('ログインが必要です')),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.surface(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        title: Text(
          'CONNECTIONS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: AppTheme.textPrimary(context),
          ),
        ),
        actions: const [
          // HIGHLIGHTボタンをCONNECTIONS画面に配置
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: BoostButton(compact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SuperLike受信通知バナー（受信中のみ表示）
            _SuperLikeReceivedBanner(uid: uid),
            Expanded(
              child: _buildMatchesStream(uid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesStream(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _svc.watchMatches(uid),
      builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.vermillion),
                ),
              );
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('読込エラー: ${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.grey)),
                ),
              );
            }
            final docs = snap.data ?? const [];
            if (docs.isEmpty) {
              return _buildEmptyState();
            }

            // matched_at で降順ソート (メモリ側)
            docs.sort((a, b) {
              final ta = (a['matched_at'] as Timestamp?)?.toDate() ??
                  DateTime(2000);
              final tb = (b['matched_at'] as Timestamp?)?.toDate() ??
                  DateTime(2000);
              return tb.compareTo(ta);
            });

            return _MatchesList(matches: docs, currentUid: uid);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_outlined,
              size: 64, color: AppTheme.textTertiary(context)),
          const SizedBox(height: 16),
          const Text(
            'まだマッチがありません',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              '気になる相手にATTACKを送って、\n相互ATTACKでCOMPLETE!!を獲得しよう！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textTertiary(context),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Matchesリスト本体 (各マッチについて相手のUserProfileを取得して表示)
class _MatchesList extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final String currentUid;
  const _MatchesList({required this.matches, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final newMatches = matches.where((m) {
      final t = (m['matched_at'] as Timestamp?)?.toDate();
      if (t == null) return false;
      return t.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (newMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(height: 1, width: 16, color: AppTheme.gold),
                const SizedBox(width: 12),
                Text(
                  'NEW MATCHES',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${newMatches.length}',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: newMatches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _MatchAvatar(
                  match: newMatches[index],
                  currentUid: currentUid,
                  isNew: true,
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Container(height: 0.5, color: AppTheme.surfaceVariant(context)),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Container(height: 1, width: 16, color: AppTheme.gold),
              const SizedBox(width: 12),
              Text(
                'MESSAGES',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
        ),
        ...matches.map((m) => _MatchTile(match: m, currentUid: currentUid)),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// 相手のUIDを抽出
String _peerUid(Map<String, dynamic> match, String currentUid) {
  final uids = (match['uids'] as List?)?.cast<String>() ?? const [];
  return uids.firstWhere((u) => u != currentUid, orElse: () => '');
}

/// 未読フラグ判定
bool _hasUnread(Map<String, dynamic> match, String currentUid) {
  final userA = match['user_a'] as String?;
  final unreadA = (match['unread_for_a'] as num?)?.toInt() ?? 0;
  final unreadB = (match['unread_for_b'] as num?)?.toInt() ?? 0;
  if (currentUid == userA) {
    return unreadA > 0;
  }
  return unreadB > 0;
}

class _MatchAvatar extends StatelessWidget {
  final Map<String, dynamic> match;
  final String currentUid;
  final bool isNew;
  const _MatchAvatar({
    required this.match,
    required this.currentUid,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final peer = _peerUid(match, currentUid);
    return FutureBuilder<UserProfile?>(
      future: UserService().getProfile(peer),
      builder: (context, snap) {
        if (!snap.hasData) {
          return _placeholderAvatar(context);
        }
        final user = snap.data!;
        return GestureDetector(
          onTap: () => _openChat(context, match, user),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.gold, width: 1),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: user.photos.isNotEmpty
                          ? Image.network(
                              user.photos.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: AppTheme.surfaceVariant(context)),
                            )
                          : Container(color: AppTheme.surfaceVariant(context)),
                    ),
                  ),
                  if (_hasUnread(match, currentUid))
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppTheme.surface(context), width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                user.name,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholderAvatar(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceVariant(context),
          ),
        ),
        const SizedBox(height: 8),
        Text('...',
            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 12)),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  final Map<String, dynamic> match;
  final String currentUid;
  const _MatchTile({required this.match, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final peer = _peerUid(match, currentUid);
    return FutureBuilder<UserProfile?>(
      future: UserService().getProfile(peer),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceVariant(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('...',
                      style: TextStyle(
                          color: AppTheme.textTertiary(context))),
                ),
              ],
            ),
          );
        }
        final user = snap.data!;
        final hasUnread = _hasUnread(match, currentUid);
        final lastMsg = match['last_message'] as String?;
        final lastTime = (match['last_message_time'] as Timestamp?)?.toDate();
        final matchedAt =
            (match['matched_at'] as Timestamp?)?.toDate() ?? DateTime.now();

        return InkWell(
          onTap: () => _openChat(context, match, user),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppTheme.surfaceVariant(context), width: 0.5),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: user.photos.isNotEmpty
                        ? Image.network(
                            user.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppTheme.surfaceVariant(context)),
                          )
                        : Container(color: AppTheme.surfaceVariant(context)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${user.age}',
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMsg ?? 'マッチしました',
                        style: TextStyle(
                          color: hasUnread
                              ? AppTheme.charcoal
                              : AppTheme.grey,
                          fontSize: 12,
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(lastTime ?? matchedAt),
                      style: TextStyle(
                        color: hasUnread
                            ? AppTheme.gold
                            : AppTheme.lightGrey,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasUnread)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.gold,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 6),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

void _openChat(
  BuildContext context,
  Map<String, dynamic> matchData,
  UserProfile peer,
) {
  final matchId = matchData['id'] as String? ?? '';
  final matchedAt =
      (matchData['matched_at'] as Timestamp?)?.toDate() ?? DateTime.now();
  final lastMsg = matchData['last_message'] as String?;
  final lastTime =
      (matchData['last_message_time'] as Timestamp?)?.toDate();
  final match = Match(
    user: peer,
    matchedAt: matchedAt,
    lastMessage: lastMsg,
    lastMessageTime: lastTime,
    hasUnread: false,
    matchId: matchId,
  );
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ChatScreen(match: match)),
  );
}

/// SuperLike受信通知バナー
/// Firestoreから自分宛の未読SuperLikeを監視し、目立つカードで表示
class _SuperLikeReceivedBanner extends StatefulWidget {
  final String uid;
  const _SuperLikeReceivedBanner({required this.uid});

  @override
  State<_SuperLikeReceivedBanner> createState() =>
      _SuperLikeReceivedBannerState();
}

class _SuperLikeReceivedBannerState extends State<_SuperLikeReceivedBanner>
    with SingleTickerProviderStateMixin {
  final _svc = UserService();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _svc.watchSuperLikesReceived(widget.uid),
      builder: (context, snap) {
        final notifications = snap.data ?? const [];
        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildBanner(notifications);
      },
    );
  }

  Widget _buildBanner(List<Map<String, dynamic>> notifications) {
    final count = notifications.length;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glow = 0.3 + (_pulseCtrl.value * 0.3);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.vermillion,
                AppTheme.vermillion.withValues(alpha: 0.85),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.vermillion.withValues(alpha: glow),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showSuperLikersList(notifications),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'SUPER ATTACK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: AppTheme.vermillion,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count人があなたにSUPER ATTACKを送りました',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuperLikersList(List<Map<String, dynamic>> notifications) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtl) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.vermillion, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'あなたに SUPER ATTACK (${notifications.length})',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtl,
                  itemCount: notifications.length,
                  itemBuilder: (_, idx) {
                    final n = notifications[idx];
                    final fromUid = (n['from_uid'] as String?) ?? '';
                    final notifId = n['id'] as String;
                    return _SuperLikerTile(
                      fromUid: fromUid,
                      notificationId: notifId,
                      onTap: () {
                        _svc.markSuperLikeSeen(notifId);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// SuperLike送信者のプロフィール表示タイル
class _SuperLikerTile extends StatelessWidget {
  final String fromUid;
  final String notificationId;
  final VoidCallback onTap;
  const _SuperLikerTile({
    required this.fromUid,
    required this.notificationId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: UserService().getProfile(fromUid),
      builder: (context, snap) {
        final profile = snap.data;
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.surfaceVariant(context),
                backgroundImage:
                    (profile?.photos.isNotEmpty == true)
                        ? NetworkImage(profile!.photos.first)
                        : null,
                child: (profile?.photos.isEmpty == true)
                    ? Icon(Icons.person,
                        color: AppTheme.textTertiary(context))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.vermillion,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.surface(context),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            profile?.name ?? '...',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'あなたに SUPER ATTACK を送りました',
            style: TextStyle(
              color: AppTheme.vermillion,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppTheme.vermillion,
          ),
          onTap: onTap,
        );
      },
    );
  }
}
