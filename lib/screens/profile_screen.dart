import 'package:flutter/material.dart';
import '../data/app_version.dart';
import '../theme/app_theme.dart';
import '../widgets/tsunagu_logo.dart';
import '../widgets/category_edit_sheet.dart';
import '../widgets/subscription_status_card.dart';
import '../models/connection_category.dart';
import '../models/user_profile.dart';
import '../services/user_preferences.dart';
import '../services/user_service.dart';
import '../services/theme_service.dart';
import 'subscription_screen.dart';
import 'profile_edit_screen.dart';
import 'photo_manager_screen.dart';
import 'ai_assistant_screen.dart';
import 'settings/matching_settings_screen.dart';
import 'settings/notification_settings_screen.dart';
import 'settings/help_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _prefs = UserPreferences();
  final _svc = UserService();
  UserProfile? _profile;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefsChanged);
    ThemeService().addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    ThemeService().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ログアウト',
                style: TextStyle(color: AppTheme.vermillion)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _signingOut = true);
    try {
      await _svc.signOut();
      // AuthGateが自動的にLoginScreenに遷移する
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログアウトに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  // ─── Theme picker ────────────────────────────────────────────────
  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  IconData _themeIcon() {
    switch (ThemeService().themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('テーマを選択',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            _themeOption(ctx, ThemeMode.light, Icons.light_mode_outlined,
                'ライトモード', '明るいテーマ'),
            _themeOption(ctx, ThemeMode.dark, Icons.dark_mode_outlined,
                'ダークモード', '目に優しい暗いテーマ'),
            _themeOption(ctx, ThemeMode.system,
                Icons.brightness_auto_outlined, 'システム連動', '端末の設定に従う'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _themeOption(BuildContext ctx, ThemeMode mode, IconData icon,
      String title, String desc) {
    final service = ThemeService();
    final selected = service.themeMode == mode;
    return ListTile(
      leading: Icon(icon,
          color: selected ? AppTheme.vermillion : null),
      title: Text(title,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppTheme.vermillion : null)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      trailing: selected
          ? const Icon(Icons.check, color: AppTheme.vermillion)
          : null,
      onTap: () async {
        await service.setThemeMode(mode);
        if (ctx.mounted) Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'PROFILE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 20),
            tooltip: '通知設定',
            onPressed: () => _push(const NotificationSettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: _svc.watchCurrentUserProfile(),
          builder: (context, snap) {
            _profile = snap.data;
            return SingleChildScrollView(
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
                _MenuItem(Icons.person_outline, 'プロフィール編集',
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen()),
                        )),
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
                _MenuItem(Icons.photo_camera_outlined, '写真を管理',
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PhotoManagerScreen()),
                        )),
                _MenuItem(Icons.tune, 'マッチング設定',
                    onTap: () => _push(const MatchingSettingsScreen())),
              ]),
              _buildMenuSection('AI FEATURES', [
                _MenuItem(Icons.auto_awesome, 'AIプロフィール最適化',
                    isAccent: true,
                    onTap: () => _push(const AIAssistantScreen(
                        initialPrompt: 'プロフィールを改善したい'))),
                _MenuItem(Icons.psychology_outlined, '相性診断履歴',
                    onTap: () => _push(const AIAssistantScreen(
                        initialPrompt: '相性の良い相手の特徴を教えて'))),
                _MenuItem(Icons.lightbulb_outline, 'メッセージアドバイス',
                    onTap: () => _push(const AIAssistantScreen(
                        initialPrompt: '最初のメッセージのコツは?'))),
              ]),
              _buildMenuSection('PREFERENCES', [
                _MenuItem(
                  _themeIcon(),
                  'テーマ (${ThemeService().currentLabel})',
                  onTap: () => _showThemePicker(context),
                ),
                _MenuItem(Icons.notifications_none, '通知設定',
                    onTap: () => _push(const NotificationSettingsScreen())),
                _MenuItem(Icons.help_outline, 'ヘルプ・サポート',
                    onTap: () => _push(const HelpScreen())),
              ]),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _signingOut ? null : _confirmLogout,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: _signingOut
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  AppTheme.textSecondary(context)),
                            ),
                          )
                        : Text(
                            'LOG OUT',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              letterSpacing: 3.0,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'TSUNAGU · ${AppVersion.fullLabel}',
                  style: const TextStyle(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // Firestore側のプロフィールを優先、無ければ_prefsをフォールバック
    final name = _profile?.name ?? _prefs.name;
    final occupation =
        (_profile?.occupation.isNotEmpty ?? false)
            ? _profile!.occupation
            : _prefs.occupation;
    final prefecture =
        (_profile?.prefecture.isNotEmpty ?? false)
            ? _profile!.prefecture
            : _prefs.prefecture;
    final photoUrl = (_profile?.photos.isNotEmpty ?? false)
        ? _profile!.photos.first
        : null;
    final age = _profile?.age;

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
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.surfaceVariant(context),
                        alignment: Alignment.center,
                        child: const TsunaguLogo(size: 48),
                      ),
                    )
                  : Container(
                      color: AppTheme.surfaceVariant(context),
                      alignment: Alignment.center,
                      child: const TsunaguLogo(size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            age != null ? '$name · $age' : name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              letterSpacing: 2.0,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: 24, color: AppTheme.vermillion),
          const SizedBox(height: 8),
          Text(
            occupation.isNotEmpty
                ? '$occupation · $prefecture'
                : prefecture,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: AppTheme.textPrimary(context), width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child: Text(
              'EDIT PROFILE',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
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
        color: AppTheme.surfaceVariant(context),
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
                  _buildStatRow('いいね', '47'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: AppTheme.border(context)),
          const SizedBox(height: 12),
          Text(
            'プロフィールを充実させると、より多様な繋がりに出会えます。',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
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
          style: TextStyle(
            color: AppTheme.textTertiary(context),
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
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
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
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
                            : AppTheme.textSecondary(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: item.isAccent
                                ? AppTheme.vermillion
                                : AppTheme.textPrimary(context),
                            fontSize: 13,
                            letterSpacing: 0.5,
                            fontWeight: item.isAccent
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppTheme.textTertiary(context)),
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
        color: AppTheme.surface(context),
        border: Border.all(color: AppTheme.border(context), width: 0.5),
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
