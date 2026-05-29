import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/admin_layout.dart';
import '../models/admin_models.dart';
import '../../theme/app_theme.dart';
import '../../models/connection_category.dart';
import '../../models/subscription.dart';
import '../../widgets/tsunagu_logo.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  UserStatus? _filterStatus;
  ConnectionCategory? _filterCategory;
  String _query = '';
  AdminUser? _selectedUser;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
        final users = service.searchUsers(
          query: _query,
          status: _filterStatus,
          category: _filterCategory,
        );

        // 選択中のユーザーが更新された場合の同期
        AdminUser? syncedSelectedUser;
        if (_selectedUser != null) {
          try {
            syncedSelectedUser =
                service.users.firstWhere((u) => u.id == _selectedUser!.id);
          } catch (_) {
            syncedSelectedUser = _selectedUser;
          }
        }

        return AdminLayout(
          currentRoute: '/admin/users',
          title: 'USER MANAGEMENT',
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル + サマリー
                    Row(
                      children: [
                        const Text(
                          'ユーザー一覧',
                          style: TextStyle(
                            color: AppTheme.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '${formatNumber(users.length)} / ${formatNumber(service.users.length)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 検索 & フィルタ
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
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 280,
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v),
                              decoration: InputDecoration(
                                hintText: 'ID / 名前 / メールで検索',
                                hintStyle: const TextStyle(
                                    color: AppTheme.lightGrey, fontSize: 13),
                                prefixIcon: const Icon(Icons.search,
                                    size: 18, color: AppTheme.grey),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(2),
                                  borderSide: const BorderSide(
                                      color: AppTheme.paleGrey, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(2),
                                  borderSide: const BorderSide(
                                      color: AppTheme.paleGrey, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(2),
                                  borderSide: const BorderSide(
                                      color: AppTheme.vermillion, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          _FilterDropdown<UserStatus?>(
                            label: 'ステータス',
                            value: _filterStatus,
                            items: [
                              const _DropdownEntry(value: null, label: 'すべて'),
                              ...UserStatus.values.map((s) =>
                                  _DropdownEntry(value: s, label: s.labelJa)),
                            ],
                            onChanged: (v) =>
                                setState(() => _filterStatus = v),
                          ),
                          _FilterDropdown<ConnectionCategory?>(
                            label: 'カテゴリ',
                            value: _filterCategory,
                            items: [
                              const _DropdownEntry(value: null, label: 'すべて'),
                              ...ConnectionCategory.values.map((c) =>
                                  _DropdownEntry(value: c, label: c.label)),
                            ],
                            onChanged: (v) =>
                                setState(() => _filterCategory = v),
                          ),
                          if (_query.isNotEmpty ||
                              _filterStatus != null ||
                              _filterCategory != null)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchCtrl.clear();
                                  _query = '';
                                  _filterStatus = null;
                                  _filterCategory = null;
                                });
                              },
                              icon: const Icon(Icons.clear,
                                  size: 14, color: AppTheme.grey),
                              label: const Text(
                                'クリア',
                                style: TextStyle(
                                    color: AppTheme.grey, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // テーブル
                    Container(
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
                      child: _UserTable(
                        users: users.take(50).toList(),
                        selectedId: syncedSelectedUser?.id,
                        onSelect: (u) => setState(() => _selectedUser = u),
                      ),
                    ),
                    if (users.length > 50) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '先頭50件を表示中（全${formatNumber(users.length)}件）',
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // サイドパネル
              if (syncedSelectedUser != null)
                _UserSidePanel(
                  key: ValueKey(syncedSelectedUser.id),
                  user: syncedSelectedUser,
                  onClose: () => setState(() => _selectedUser = null),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DropdownEntry<T> {
  final T value;
  final String label;
  const _DropdownEntry({required this.value, required this.label});
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<_DropdownEntry<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
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
              fontWeight: FontWeight.w500,
            ),
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

class _UserTable extends StatelessWidget {
  final List<AdminUser> users;
  final String? selectedId;
  final ValueChanged<AdminUser> onSelect;
  const _UserTable({
    required this.users,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 320),
        child: DataTable(
          columnSpacing: 32,
          horizontalMargin: 24,
          headingRowHeight: 44,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          showCheckboxColumn: false,
          headingTextStyle: const TextStyle(
            color: AppTheme.grey,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
          columns: const [
            DataColumn(label: Text('USER')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('PLAN')),
            DataColumn(label: Text('MATCHES'), numeric: true),
            DataColumn(label: Text('REPORTS'), numeric: true),
            DataColumn(label: Text('LAST ACTIVE')),
            DataColumn(label: Text('')),
          ],
          rows: users.map((u) => _buildRow(context, u)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, AdminUser u) {
    final isSelected = u.id == selectedId;
    return DataRow(
      selected: isSelected,
      onSelectChanged: (_) => onSelect(u),
      color: WidgetStateProperty.resolveWith<Color?>(
        (states) {
          if (isSelected) return AppTheme.vermillionPale.withValues(alpha: 0.5);
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.offWhite;
          }
          return null;
        },
      ),
      cells: [
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.paleGrey,
              backgroundImage: NetworkImage(u.avatarUrl),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  u.name,
                  style: const TextStyle(
                    color: AppTheme.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${u.id} · ${u.age}歳 · ${u.prefecture}',
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        )),
        DataCell(_StatusBadge(status: u.status)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(u.primaryCategory.icon,
                size: 14, color: AppTheme.vermillion),
            const SizedBox(width: 6),
            Text(
              u.primaryCategory.label,
              style: const TextStyle(
                color: AppTheme.charcoal,
                fontSize: 12,
              ),
            ),
          ],
        )),
        DataCell(_PlanBadge(plan: u.activePlan)),
        DataCell(Text(
          formatNumber(u.matchCount),
          style: const TextStyle(color: AppTheme.charcoal, fontSize: 12),
        )),
        DataCell(Text(
          u.reportCount.toString(),
          style: TextStyle(
            color: u.reportCount > 0 ? AppTheme.vermillion : AppTheme.grey,
            fontSize: 12,
            fontWeight: u.reportCount > 0 ? FontWeight.w600 : FontWeight.w400,
          ),
        )),
        DataCell(Text(
          _formatLastActive(u.lastActiveAt),
          style: const TextStyle(color: AppTheme.grey, fontSize: 11),
        )),
        DataCell(
          IconButton(
            icon: Icon(
              isSelected ? Icons.arrow_back : Icons.arrow_forward,
              size: 16,
              color: isSelected ? AppTheme.vermillion : AppTheme.charcoal,
            ),
            tooltip: isSelected ? '閉じる' : '詳細を表示',
            onPressed: () => onSelect(u),
          ),
        ),
      ],
    );
  }

  String _formatLastActive(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}分前';
    if (d.inHours < 24) return '${d.inHours}時間前';
    if (d.inDays < 30) return '${d.inDays}日前';
    return '${(d.inDays / 30).floor()}ヶ月前';
  }
}

// ============================================================================
// サイドパネル
// ============================================================================

class _UserSidePanel extends StatefulWidget {
  final AdminUser user;
  final VoidCallback onClose;
  const _UserSidePanel({
    super.key,
    required this.user,
    required this.onClose,
  });

  @override
  State<_UserSidePanel> createState() => _UserSidePanelState();
}

class _UserSidePanelState extends State<_UserSidePanel>
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final panelWidth = width >= 1100
        ? 440.0
        : width >= 900
            ? 400.0
            : width * 0.92;

    return Positioned.fill(
      child: Stack(
        children: [
          // 背景 (タップで閉じる)
          FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _animatedClose,
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
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
                  child: _PanelContent(
                    user: widget.user,
                    onClose: _animatedClose,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onClose;
  const _PanelContent({required this.user, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー (黒背景 + ロゴ装飾)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.black, AppTheme.charcoal],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -30,
                child: Opacity(
                  opacity: 0.06,
                  child: TsunaguLogo(size: 200, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.vermillion,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'USER DETAIL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.white),
                          tooltip: '閉じる',
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.paleGrey,
                            backgroundImage: NetworkImage(user.avatarUrl),
                            onBackgroundImageError: (_, __) {},
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _StatusBadge(status: user.status),
                                  const SizedBox(width: 6),
                                  _PlanBadge(plan: user.activePlan),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 詳細スクロール
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 統計ミニカード
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'MATCHES',
                        value: formatNumber(user.matchCount),
                        icon: Icons.favorite_outline,
                        color: AppTheme.vermillion,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                        label: 'REPORTS',
                        value: user.reportCount.toString(),
                        icon: Icons.flag_outlined,
                        color: user.reportCount > 0
                            ? AppTheme.vermillion
                            : AppTheme.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionLabel('PROFILE'),
                const SizedBox(height: 8),
                _detailRow('USER ID', user.id, monospace: true),
                _detailRow('年齢', '${user.age}歳'),
                _detailRow('都道府県', user.prefecture),
                _detailRow('カテゴリ', user.primaryCategory.label,
                    icon: user.primaryCategory.icon),
                _detailRow('プラン', _planLabel(user.activePlan)),
                const SizedBox(height: 20),
                const _SectionLabel('ACTIVITY'),
                const SizedBox(height: 8),
                _detailRow('登録日', _formatDate(user.joinedAt)),
                _detailRow('最終ログイン', _formatLastActive(user.lastActiveAt)),
                const SizedBox(height: 24),
                const _SectionLabel('ACTIONS'),
                const SizedBox(height: 12),
                _buildActionButtons(context),
                const SizedBox(height: 24),
                const _SectionLabel('DANGER ZONE'),
                const SizedBox(height: 12),
                _buildDangerActions(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.mail_outline,
          color: AppTheme.charcoal,
          title: '通知メッセージを送信',
          subtitle: '個別のお知らせをこのユーザーに送ります',
          onTap: () => _showSendNotification(context),
        ),
        _ActionTile(
          icon: Icons.chat_bubble_outline,
          color: AppTheme.charcoal,
          title: 'チャット履歴を表示',
          subtitle: 'このユーザーの直近マッチ会話を確認',
          onTap: () => _showChatHistory(context),
        ),
        _ActionTile(
          icon: Icons.logout,
          color: Colors.orange,
          title: '強制ログアウト',
          subtitle: 'このユーザーの全セッションを終了',
          onTap: () => _confirmForceLogout(context),
        ),
      ],
    );
  }

  Widget _buildDangerActions(BuildContext context) {
    if (user.status == UserStatus.active) {
      return _ActionTile(
        icon: Icons.block,
        color: AppTheme.vermillion,
        title: 'アカウントを凍結',
        subtitle: 'このユーザーはサービスを利用できなくなります',
        onTap: () => _confirmSuspend(context),
      );
    } else if (user.status == UserStatus.suspended) {
      return _ActionTile(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        title: '凍結を解除',
        subtitle: 'このユーザーが再びサービスを利用できます',
        onTap: () {
          AdminService().reactivateUser(user.id);
          _showSnack(context, '${user.name} の凍結を解除しました');
        },
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.paleGrey,
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: AppTheme.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'このステータスでは追加アクションはありません',
                style: TextStyle(color: AppTheme.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _confirmSuspend(BuildContext context) {
    _confirmAction(
      context,
      title: 'アカウントを凍結しますか？',
      body: '${user.name} のアカウントを凍結します。\nこのユーザーはサービスを利用できなくなります。',
      confirmLabel: '凍結する',
      isDanger: true,
      onConfirm: () {
        AdminService().suspendUser(user.id);
        _showSnack(context, '${user.name} を凍結しました');
      },
    );
  }

  void _confirmForceLogout(BuildContext context) {
    _confirmAction(
      context,
      title: '強制ログアウトしますか？',
      body: '${user.name} の全デバイスのセッションを終了します。\n次回アクセス時に再ログインが必要になります。',
      confirmLabel: 'ログアウト実行',
      isDanger: false,
      onConfirm: () {
        _showSnack(context, '${user.name} を全デバイスからログアウトしました');
      },
    );
  }

  void _showSendNotification(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          '${user.name} に通知を送信',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '本文',
                  border: OutlineInputBorder(),
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
              backgroundColor: AppTheme.vermillion,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack(context, '${user.name} に通知を送信しました');
            },
            child: const Text('送信',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  void _showChatHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: SizedBox(
          width: 520,
          height: 480,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.black,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${user.name} のチャット履歴',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final isMine = i % 2 == 0;
                    final messages = [
                      'こんにちは、はじめまして！',
                      'プロフィール拝見しました。趣味が合いそうですね。',
                      'お忙しい中、メッセージありがとうございます！',
                      '週末にお時間ありますか？',
                      'もちろんです。土曜の午後はいかがでしょう？',
                      '了解です。詳細は後ほどお伝えしますね。',
                    ];
                    return Align(
                      alignment: isMine
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMine
                                ? AppTheme.paleGrey
                                : AppTheme.vermillionPale,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            messages[i],
                            style: TextStyle(
                              color: isMine
                                  ? AppTheme.charcoal
                                  : AppTheme.vermillionDark,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppTheme.paleGrey, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 12, color: AppTheme.grey),
                    const SizedBox(width: 6),
                    Text(
                      '※ デモデータ - 実環境ではエンドツーエンド暗号化が適用されます',
                      style: TextStyle(
                          color: AppTheme.grey.withValues(alpha: 0.8),
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool monospace = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: AppTheme.vermillion),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: AppTheme.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: monospace ? 'monospace' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _planLabel(PlanType? p) {
    if (p == null) return '無料ユーザー';
    switch (p) {
      case PlanType.allCategory:
        return '全カテゴリ月額';
      case PlanType.singleCategory:
        return '単カテゴリ月額';
      case PlanType.boost:
        return 'HIGHLIGHT中';
      case PlanType.freeTrial:
        return '無料体験中';
    }
  }

  String _formatLastActive(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}分前';
    if (d.inHours < 24) return '${d.inHours}時間前';
    if (d.inDays < 30) return '${d.inDays}日前';
    return '${(d.inDays / 30).floor()}ヶ月前';
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          color: AppTheme.vermillion,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.paleGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
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
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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

class _StatusBadge extends StatelessWidget {
  final UserStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case UserStatus.active:
        color = Colors.green;
        break;
      case UserStatus.suspended:
        color = AppTheme.vermillion;
        break;
      case UserStatus.deleted:
        color = AppTheme.grey;
        break;
      case UserStatus.pendingVerification:
        color = Colors.orange;
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
        status.labelJa,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final PlanType? plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return const Text(
        'FREE',
        style: TextStyle(
          color: AppTheme.lightGrey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
        ),
      );
    }
    final isPremium = plan == PlanType.allCategory;
    final label = _planShortLabel(plan!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPremium ? AppTheme.black : AppTheme.vermillionPale,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPremium ? Colors.white : AppTheme.vermillion,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _planShortLabel(PlanType p) {
    switch (p) {
      case PlanType.allCategory:
        return 'PREMIUM';
      case PlanType.singleCategory:
        return 'SINGLE';
      case PlanType.boost:
        return 'HIGHLIGHT';
      case PlanType.freeTrial:
        return 'TRIAL';
    }
  }
}

void _confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required VoidCallback onConfirm,
  bool isDanger = false,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      title: Text(title,
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      content: Text(body, style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child:
              const Text('キャンセル', style: TextStyle(color: AppTheme.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDanger ? AppTheme.vermillion : AppTheme.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2)),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(confirmLabel,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5)),
        ),
      ],
    ),
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.black,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
