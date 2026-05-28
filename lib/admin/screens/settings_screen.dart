import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

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

    final admin = service.currentAdmin!;

    return AdminLayout(
      currentRoute: '/admin/settings',
      title: 'SETTINGS',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '設定',
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 22,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 32),

            // プロフィール
            const SectionHeader(label: 'YOUR PROFILE'),
            const SizedBox(height: 16),
            _AdminProfileCard(admin: admin),
            const SizedBox(height: 32),

            // アプリ設定
            const SectionHeader(label: 'APPLICATION'),
            const SizedBox(height: 16),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.attach_money_outlined,
                  label: 'プラン料金設定',
                  description: '全カテゴリ ¥4,800 / 単カテゴリ ¥1,980 / ブースト ¥500',
                  onTap: () => _showInfo(context, 'プラン料金は次回リリースで編集可能になります'),
                ),
                _SettingsTile(
                  icon: Icons.policy_outlined,
                  label: 'モデレーションポリシー',
                  description: '自動BAN閾値・通報レビュー基準',
                  onTap: () => _showInfo(context, 'ポリシー設定は次回リリースで利用可能になります'),
                ),
                _SettingsTile(
                  icon: Icons.security_outlined,
                  label: 'プライバシー・セキュリティ',
                  description: 'データ保持・暗号化設定',
                  onTap: () => _showInfo(context, 'セキュリティ設定は次回リリースで利用可能になります'),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: '通知設定',
                  description: 'アラート受信・配信タイミング',
                  onTap: () => _showInfo(context, '通知設定は次回リリースで利用可能になります'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 管理者
            const SectionHeader(label: 'ADMIN ACCESS'),
            const SizedBox(height: 16),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  label: '管理者の追加・削除',
                  description: 'SUPER ADMIN / MODERATOR / SUPPORT / VIEWER',
                  onTap: () => _showInfo(context, 'マルチアドミン機能は次回リリースで利用可能になります'),
                ),
                _SettingsTile(
                  icon: Icons.history_outlined,
                  label: '監査ログ',
                  description: '管理者操作の履歴を確認',
                  onTap: () => _showInfo(context, '監査ログ機能は次回リリースで利用可能になります'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // システム情報
            const SectionHeader(label: 'SYSTEM'),
            const SizedBox(height: 16),
            _SystemInfoCard(),
            const SizedBox(height: 32),

            // ログアウト
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, size: 16),
                label: const Text(
                  'SIGN OUT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.vermillion,
                  side: const BorderSide(color: AppTheme.vermillion),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  service.logout();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/admin/login', (_) => false);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AdminProfileCard extends StatelessWidget {
  final AdminAccount admin;
  const _AdminProfileCard({required this.admin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.vermillion,
            child: Text(
              admin.name.isNotEmpty ? admin.name.substring(0, 1) : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name,
                  style: const TextStyle(
                    color: AppTheme.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  admin.email,
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.vermillion,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        admin.role.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Last login: ${_formatDateTime(admin.lastLoginAt)}',
                      style: const TextStyle(
                        color: AppTheme.lightGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.black,
              side: const BorderSide(color: AppTheme.paleGrey),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('プロフィール編集は次回リリースで利用可能になります'),
                  backgroundColor: AppTheme.black,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'EDIT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: children
            .asMap()
            .entries
            .expand((entry) => [
                  entry.value,
                  if (entry.key < children.length - 1)
                    const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppTheme.paleGrey),
                ])
            .toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.offWhite,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(icon, color: AppTheme.charcoal, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
            const Icon(Icons.chevron_right,
                color: AppTheme.lightGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SystemInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'SYSTEM HEALTHY',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('VERSION', 'TSUNAGU Admin v1.0.0'),
          _infoRow('BUILD', '2025.01.${DateTime.now().day}'),
          _infoRow('REGION', 'asia-northeast1 (Tokyo)'),
          _infoRow('ENVIRONMENT', 'PRODUCTION'),
          _infoRow('UPTIME', '99.97%'),
          _infoRow('LAST DEPLOY',
              '${DateTime.now().subtract(const Duration(days: 2)).month}/${DateTime.now().subtract(const Duration(days: 2)).day}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
