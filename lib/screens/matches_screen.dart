import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matches = SampleData.getMatches();
    final newMatches = matches.where((m) =>
        m.matchedAt.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text(
          'CONNECTIONS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: AppTheme.black,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
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
                      style: const TextStyle(
                        color: AppTheme.black,
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
                    return _buildNewMatchAvatar(context, newMatches[index]);
                  },
                ),
              ),
              const SizedBox(height: 32),
              Container(height: 0.5, color: AppTheme.paleGrey),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(height: 1, width: 16, color: AppTheme.gold),
                  const SizedBox(width: 12),
                  const Text(
                    'MESSAGES',
                    style: TextStyle(
                      color: AppTheme.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
            ),
            ...matches.map((match) => _buildMatchTile(context, match)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNewMatchAvatar(BuildContext context, Match match) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(match: match)),
        );
      },
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
                  child: Image.network(
                    match.user.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.paleGrey),
                  ),
                ),
              ),
              if (match.hasUnread)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            match.user.name,
            style: const TextStyle(
              color: AppTheme.black,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTile(BuildContext context, Match match) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(match: match)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.paleGrey, width: 0.5),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image.network(
                  match.user.photos.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTheme.paleGrey),
                ),
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
                        match.user.name,
                        style: TextStyle(
                          color: AppTheme.black,
                          fontSize: 15,
                          fontWeight:
                              match.hasUnread ? FontWeight.w500 : FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${match.user.age}',
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
                    match.lastMessage ?? 'マッチしました',
                    style: TextStyle(
                      color: match.hasUnread ? AppTheme.charcoal : AppTheme.grey,
                      fontSize: 12,
                      fontWeight:
                          match.hasUnread ? FontWeight.w500 : FontWeight.w300,
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
                  _formatTime(match.lastMessageTime ?? match.matchedAt),
                  style: TextStyle(
                    color: match.hasUnread ? AppTheme.gold : AppTheme.lightGrey,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                if (match.hasUnread)
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
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
