import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/tsunagu_logo.dart';
import '../widgets/category_edit_sheet.dart';
import '../widgets/subscription_status_card.dart';
import '../models/connection_category.dart';
import '../services/user_preferences.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _prefs = UserPreferences();

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text(
          'PROFILE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: AppTheme.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildProfileHeader(),
              const SizedBox(height: 24),
              const SubscriptionStatusCard(),
              const SizedBox(height: 24),
              _buildCategoryCard(context),
              const SizedBox(height: 24),
              _buildAIStats(),
              const SizedBox(height: 32),
              _buildMenuSection('ACCOUNT', [
                _MenuItem(Icons.person_outline, 'プロフィール編集', onTap: () {}),
                _MenuItem(Icons.category_outlined, 'カテゴリ・目的を変更',
                    onTap: () => CategoryEditSheet.show(context),
                    isAccent: true),
                _MenuItem(Icons.workspace_premium_outlined, 'プラン・課金',
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SubscriptionScreen()),
                        ),
                    isAccent: true),
                _MenuItem(Icons.photo_camera_outlined, '写真を管理', onTap: () {}),
                _MenuItem(Icons.tune, 'マッチング設定', onTap: () {}),
              ]),
              _buildMenuSection('AI FEATURES', [
                _MenuItem(Icons.auto_awesome, 'AIプロフィール最適化',
                    isAccent: true, onTap: () {}),
                _MenuItem(Icons.psychology_outlined, '相性診断履歴',
                    onTap: () {}),
                _MenuItem(Icons.lightbulb_outline, 'メッセージアドバイス',
                    onTap: () {}),
              ]),
              _buildMenuSection('PREFERENCES', [
                _MenuItem(Icons.notifications_none, '通知設定', onTap: () {}),
                _MenuItem(Icons.lock_outline, 'プライバシー', onTap: () {}),
                _MenuItem(Icons.help_outline, 'ヘルプ・サポート', onTap: () {}),
              ]),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.paleGrey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text(
                      'LOG OUT',
                      style: TextStyle(
                        color: AppTheme.grey,
                        letterSpacing: 3.0,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'TSUNAGU · v1.0.0',
                  style: TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 10,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.vermillion, width: 1.5),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Container(
                color: AppTheme.offWhite,
                alignment: Alignment.center,
                child: const TsunaguLogo(size: 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _prefs.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              letterSpacing: 2.0,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: 24, color: AppTheme.vermillion),
          const SizedBox(height: 8),
          Text(
            '${_prefs.occupation} · ${_prefs.prefecture}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.black, width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child: const Text(
              'EDIT PROFILE',
              style: TextStyle(
                color: AppTheme.black,
                fontSize: 11,
                letterSpacing: 2.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 12),
              const SizedBox(width: 8),
              Text(
                'AI PROFILE SCORE',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '78',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 42,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatRow('Matches', '12'),
                  const SizedBox(height: 4),
                  _buildStatRow('Likes', '47'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: AppTheme.paleGrey),
          const SizedBox(height: 12),
          const Text(
            'プロフィールを充実させると、より多様な繋がりに出会えます。',
            style: TextStyle(
              color: AppTheme.charcoal,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Container(height: 1, width: 16, color: AppTheme.gold),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 18,
                        color: item.isAccent
                            ? AppTheme.vermillion
                            : AppTheme.darkGrey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: item.isAccent
                                ? AppTheme.vermillion
                                : AppTheme.charcoal,
                            fontSize: 13,
                            letterSpacing: 0.5,
                            fontWeight: item.isAccent
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppTheme.lightGrey),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// 自分のカテゴリ設定カード
  Widget _buildCategoryCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border.all(color: AppTheme.paleGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_outlined,
                  color: AppTheme.vermillion, size: 12),
              const SizedBox(width: 8),
              const Text(
                'MY CONNECTION',
                style: TextStyle(
                  color: AppTheme.vermillion,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => CategoryEditSheet.show(context),
                child: const Text(
                  '編集',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.vermillion,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Primary
          Row(
            children: [
              const Text(
                '主な目的',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.grey,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.vermillion,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_prefs.primaryCategory.activeIcon,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _prefs.primaryCategory.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Open to
          const Text(
            '受け入れ可能',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _prefs.openTo.map((cat) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.vermillion.withValues(alpha: 0.08),
                  border:
                      Border.all(color: AppTheme.vermillion, width: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 11, color: AppTheme.vermillion),
                    const SizedBox(width: 4),
                    Text(
                      cat.label,
                      style: const TextStyle(
                        color: AppTheme.vermillion,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final bool isAccent;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label,
      {this.isAccent = false, required this.onTap});
}
