import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/connection_category.dart';
import '../theme/app_theme.dart';
import '../services/chat_templates.dart';
import '../services/user_service.dart';
import '../services/subscription_service.dart';
import 'subscription_screen.dart';

class ChatScreen extends StatefulWidget {
  final Match match;
  const ChatScreen({super.key, required this.match});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showAISuggestions = false;
  late List<String> _aiSuggestions;
  final _svc = UserService();
  final _subscription = SubscriptionService();
  String _currentUid = '';
  List<Message> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUid = _svc.currentUid ?? '';
    _aiSuggestions = ChatTemplates.getOpeners(widget.match.user);
    _subscription.addListener(_onSubscriptionChanged);

    // 開いた瞬間に未読カウントをリセット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.match.matchId.isNotEmpty && _currentUid.isNotEmpty) {
        _svc.markChatRead(
          matchId: widget.match.matchId,
          currentUid: _currentUid,
        );
      }
    });
  }

  void _onSubscriptionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isSending) return;
    if (widget.match.matchId.isEmpty || _currentUid.isEmpty) return;

    // 無料プランチェック
    if (!_subscription.hasActivePremium) {
      _showPremiumRequiredDialog();
      return;
    }

    _controller.clear();
    setState(() {
      _showAISuggestions = false;
      _isSending = true;
    });
    try {
      await _svc.sendMessage(
        matchId: widget.match.matchId,
        senderUid: _currentUid,
        text: text,
        recipientUids: [widget.match.user.id],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        title: Row(
          children: [
            const Icon(Icons.lock, color: AppTheme.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'メッセージ交換はプレミアム限定',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '無料プランではスワイプはできますが、\nマッチ後のメッセージ交換にはプレミアムプランへの加入が必要です。\n\nプレミアムプランで、\n気になる相手と無制限に会話を楽しもう！',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              '閉じる',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vermillion,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
            child: const Text('プランを見る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface(context),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: widget.match.matchId.isEmpty || _currentUid.isEmpty
                  ? const Center(
                      child: Text(
                        'チャットを開けません',
                        style: TextStyle(color: AppTheme.grey),
                      ),
                    )
                  : StreamBuilder<List<Message>>(
                      stream: _svc.watchMessages(
                          widget.match.matchId, _currentUid),
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  AppTheme.vermillion),
                            ),
                          );
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('読込エラー: ${snap.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppTheme.grey)),
                            ),
                          );
                        }
                        _messages = snap.data ?? const [];
                        if (_messages.isEmpty) {
                          return _buildEmptyChatState();
                        }
                        return ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        );
                      },
                    ),
            ),
            if (_showAISuggestions) _buildAISuggestionPanel(),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 48, color: AppTheme.textTertiary(context)),
          const SizedBox(height: 16),
          Text(
            '${widget.match.user.name}さんとマッチしました！',
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '最初のメッセージを送ってみましょう',
            style: TextStyle(color: AppTheme.textTertiary(context), fontSize: 11),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface(context),
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppTheme.surfaceVariant(context)),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold, width: 0.5),
            ),
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: widget.match.user.photos.isNotEmpty
                  ? Image.network(
                      widget.match.user.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.surfaceVariant(context)),
                    )
                  : Container(color: AppTheme.surfaceVariant(context)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.match.user.name,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                widget.match.user.location,
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz, size: 20),
          onPressed: _showSafetyMenu,
        ),
      ],
    );
  }

  void _showSafetyMenu() {
    final partner = widget.match.user;
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
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('通報する'),
              subtitle: Text('${partner.name} を運営に通報します'),
              onTap: () {
                Navigator.pop(ctx);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('ブロックする'),
              subtitle: Text('${partner.name} を今後表示しません'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmBlock();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static const _reportReasons = <String>[
    'スパム・宣伝',
    '不適切なメッセージ',
    'なりすまし・偽プロフィール',
    'ハラスメント・嫌がらせ',
    '勧誘（ビジネス・宗教等）',
    'その他',
  ];

  void _showReportDialog() {
    final partner = widget.match.user;
    String? selectedReason;
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('通報する'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('理由を選択してください',
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                ..._reportReasons.map((r) => RadioListTile<String>(
                      value: r,
                      groupValue: selectedReason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.vermillion,
                      title: Text(r, style: const TextStyle(fontSize: 14)),
                      onChanged: (v) => setLocal(() => selectedReason = v),
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '詳細（任意）',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await _svc.submitReport(
                          targetUserId: partner.id,
                          targetUserName: partner.name,
                          reason: selectedReason!,
                          description: descCtrl.text.trim(),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('通報を受け付けました。ご協力ありがとうございます。')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('通報に失敗しました: $e')),
                          );
                        }
                      }
                    },
              child: const Text('通報する',
                  style: TextStyle(color: AppTheme.vermillion)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlock() async {
    final partner = widget.match.user;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${partner.name} をブロック'),
        content: const Text(
            'ブロックすると、相手は今後 DISCOVER やマッチに表示されなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ブロック',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.blockUser(partner.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${partner.name} をブロックしました')),
        );
        Navigator.of(context).pop(); // チャット画面を閉じる
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ブロックに失敗しました: $e')),
        );
      }
    }
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.vermillion
                    : AppTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(2),
                border: isMe
                    ? null
                    : Border.all(
                        color: AppTheme.border(context),
                        width: 0.5,
                      ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppTheme.textPrimary(context),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestionPanel() {
    final category = widget.match.user.primaryCategory;
    // 会話が進んでいるかでテンプレートを切り替え
    final myMessageCount = _messages.where((m) => m.isMe).length;
    final showFollowUps = myMessageCount >= 1;
    final suggestions = showFollowUps
        ? ChatTemplates.getFollowUps(category)
        : _aiSuggestions;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        border: Border(top: BorderSide(color: AppTheme.surfaceVariant(context), width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppTheme.vermillion, size: 12),
              const SizedBox(width: 8),
              const Text(
                'AI SUGGESTIONS',
                style: TextStyle(
                  color: AppTheme.vermillion,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(width: 10),
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.vermillion.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon,
                        size: 10, color: AppTheme.vermillion),
                    const SizedBox(width: 4),
                    Text(
                      category.label,
                      style: const TextStyle(
                        color: AppTheme.vermillion,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showAISuggestions = false),
                child: const Icon(Icons.close, size: 14, color: AppTheme.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            showFollowUps
                ? '会話を深めるための提案'
                : '${category.label}の繋がりに合わせた会話の口火',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.grey,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: suggestions
                    .map((suggestion) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => _sendMessage(suggestion),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                border: Border.all(color: AppTheme.surfaceVariant(context)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  color: AppTheme.charcoal,
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final isPremium = _subscription.hasActivePremium;

    // 無料プラン: メッセージ送信ロック表示
    if (!isPremium) {
      return _buildLockedInputField();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(
            top: BorderSide(color: AppTheme.border(context), width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showAISuggestions = !_showAISuggestions),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(
                    color: _showAISuggestions
                        ? AppTheme.gold
                        : AppTheme.border(context),
                    width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(Icons.auto_awesome,
                  color: _showAISuggestions
                      ? AppTheme.gold
                      : AppTheme.textTertiary(context),
                  size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                    color: AppTheme.border(context), width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'メッセージ...',
                  hintStyle: TextStyle(
                    color: AppTheme.textTertiary(context),
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : () => _sendMessage(_controller.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSending ? AppTheme.grey : AppTheme.vermillion,
                borderRadius: BorderRadius.circular(2),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.arrow_upward,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// 無料プラン向け: メッセージ入力欄をロックしてアップグレード誘導
  Widget _buildLockedInputField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(
            top: BorderSide(color: AppTheme.border(context), width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.vermillion.withValues(alpha: 0.08),
                  AppTheme.gold.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.vermillion.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppTheme.vermillion,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'メッセージ交換はプレミアム限定',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'プランに加入して会話を始めよう',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vermillion,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.workspace_premium, size: 20),
              label: const Text(
                'プレミアムプランを見る',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
