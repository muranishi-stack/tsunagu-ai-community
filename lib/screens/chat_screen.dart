import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/connection_category.dart';
import '../theme/app_theme.dart';
import '../services/chat_templates.dart';
import '../services/user_service.dart';

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
  String _currentUid = '';
  List<Message> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUid = _svc.currentUid ?? '';
    _aiSuggestions = ChatTemplates.getOpeners(widget.match.user);

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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isSending) return;
    if (widget.match.matchId.isEmpty || _currentUid.isEmpty) return;

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
    super.dispose();
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
          onPressed: () {},
        ),
      ],
    );
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: AppTheme.surfaceVariant(context), width: 0.5)),
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
                    color: _showAISuggestions ? AppTheme.gold : AppTheme.paleGrey,
                    width: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(Icons.auto_awesome,
                  color: _showAISuggestions ? AppTheme.gold : AppTheme.grey,
                  size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppTheme.surfaceVariant(context), width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 13),
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
                color: _isSending ? AppTheme.grey : AppTheme.black,
                borderRadius: BorderRadius.circular(2),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppTheme.gold),
                      ),
                    )
                  : const Icon(Icons.arrow_upward,
                      color: AppTheme.gold, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
