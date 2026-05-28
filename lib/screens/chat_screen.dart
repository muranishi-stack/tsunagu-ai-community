import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/connection_category.dart';
import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../services/chat_templates.dart';

class ChatScreen extends StatefulWidget {
  final Match match;
  const ChatScreen({super.key, required this.match});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Message> _messages;
  final TextEditingController _controller = TextEditingController();
  bool _showAISuggestions = false;
  late List<String> _aiSuggestions;

  @override
  void initState() {
    super.initState();
    _messages = SampleData.getMessages(widget.match.user.id);
    // カテゴリ別の最適化された会話の口火を取得
    _aiSuggestions = ChatTemplates.getOpeners(widget.match.user);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(Message(
        id: DateTime.now().toString(),
        senderId: 'me',
        text: text,
        timestamp: DateTime.now(),
        isMe: true,
      ));
      _controller.clear();
      _showAISuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppTheme.paleGrey),
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
              child: Image.network(
                widget.match.user.photos.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.paleGrey),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.match.user.name,
                style: const TextStyle(
                  color: AppTheme.black,
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
                color: isMe ? AppTheme.black : AppTheme.offWhite,
                borderRadius: BorderRadius.circular(2),
                border: isMe ? null : Border.all(color: AppTheme.paleGrey, width: 0.5),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppTheme.charcoal,
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
        color: AppTheme.offWhite,
        border: Border(top: BorderSide(color: AppTheme.paleGrey, width: 0.5)),
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
                                border: Border.all(color: AppTheme.paleGrey),
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
        border: Border(top: BorderSide(color: AppTheme.paleGrey, width: 0.5)),
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
                color: AppTheme.offWhite,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppTheme.paleGrey, width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'メッセージ...',
                  hintStyle: TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 13,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.black,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(Icons.arrow_upward,
                  color: AppTheme.gold, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
