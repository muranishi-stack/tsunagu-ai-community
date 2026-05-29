// NotificationSettingsScreen — 通知設定
// =====================================================
// SharedPreferences に永続化されるトグル群。
import 'package:flutter/material.dart';

import '../../services/notification_preferences.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _prefs = NotificationPreferences();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      ),
      body: AnimatedBuilder(
        animation: _prefs,
        builder: (context, _) => ListView(
          children: [
            _sectionHeader('プッシュ通知'),
            _tile(
              icon: Icons.favorite_outline,
              title: 'マッチ成立',
              subtitle: '相互にいいねが成立したとき',
              value: _prefs.newMatch,
              onChanged: _prefs.setNewMatch,
            ),
            _tile(
              icon: Icons.chat_bubble_outline,
              title: 'メッセージ受信',
              subtitle: '新しいメッセージが届いたとき',
              value: _prefs.newMessage,
              onChanged: _prefs.setNewMessage,
            ),
            _tile(
              icon: Icons.thumb_up_outlined,
              title: 'いいね',
              subtitle: '誰かがあなたにいいねしたとき',
              value: _prefs.likes,
              onChanged: _prefs.setLikes,
            ),
            _tile(
              icon: Icons.rocket_launch_outlined,
              title: 'HIGHLIGHT',
              subtitle: 'HIGHLIGHT関連の通知',
              value: _prefs.highlights,
              onChanged: _prefs.setHighlights,
            ),
            const Divider(height: 1),
            _sectionHeader('お知らせ'),
            _tile(
              icon: Icons.campaign_outlined,
              title: '運営からのお知らせ',
              subtitle: 'キャンペーン・メンテナンス情報など',
              value: _prefs.announcements,
              onChanged: _prefs.setAnnouncements,
            ),
            _tile(
              icon: Icons.mail_outline,
              title: 'メール通知',
              subtitle: '重要なお知らせをメールでも受け取る',
              value: _prefs.email,
              onChanged: _prefs.setEmail,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Text(
                '※ プッシュ通知を受け取るには、端末の設定で TSUNAGU の通知を'
                '許可してください。',
                style: TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppTheme.vermillion,
          ),
        ),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.vermillion,
      secondary: Icon(icon, color: AppTheme.textSecondary(context)),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }
}
