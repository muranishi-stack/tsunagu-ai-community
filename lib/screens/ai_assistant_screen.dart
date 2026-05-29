import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  /// 起動時に自動送信する初期プロンプト（任意）。
  /// プロフィール画面の AI 機能ショートカットから文脈を渡すのに使う。
  final String? initialPrompt;

  const AIAssistantScreen({super.key, this.initialPrompt});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_AIMessage> _messages = [
    _AIMessage(
      text: 'こんにちは。AI恋愛アシスタントです。\n\nプロフィール最適化、メッセージ作成、相性診断など、お手伝いできることがあれば何でもお聞きください。',
      isAI: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt;
    if (prompt != null && prompt.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendMessage(prompt));
    }
  }

  final List<String> _suggestions = [
    'プロフィールを改善したい',
    '最初のメッセージのコツは?',
    '相性の良い相手の特徴',
    '会話が続くトピック',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_AIMessage(text: text, isAI: false));
      _controller.clear();
    });

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_AIMessage(
          text: _generateAIResponse(text),
          isAI: true,
        ));
      });
    });
  }

  String _generateAIResponse(String input) {
    if (input.contains('プロフィール')) {
      return 'プロフィール改善のポイントをご提案します:\n\n• 自然な笑顔の写真を1枚目に\n• 趣味は3〜5個に絞る\n• 自己紹介は具体的なエピソードを\n• 価値観が伝わる言葉を選ぶ\n\nあなたの現在のプロフィールを分析しますか?';
    } else if (input.contains('メッセージ')) {
      return '最初のメッセージは、相手のプロフィールから共通点を見つけて、それについて質問する形が効果的です。\n\n例:「○○がお好きなんですね。私もよく行きます。おすすめのお店はありますか?」';
    } else if (input.contains('相性')) {
      return 'AI分析による相性の良い相手の特徴:\n\n• 価値観の重なりが70%以上\n• ライフスタイルが補完的\n• コミュニケーションスタイルが一致\n• 趣味に共通項が2つ以上\n\n現在のマッチを分析しますか?';
    } else if (input.contains('会話') || input.contains('トピック')) {
      return '会話が盛り上がる話題:\n\n• 最近行った場所、食べた美味しいもの\n• 共通の趣味についての発見や体験\n• 休日の過ごし方や好きな時間\n• 旅行で行きたい場所\n\n相手の興味を引き出す質問が大切です。';
    }
    return 'なるほど、それについてもう少し詳しく教えていただけますか?\n\nより具体的なアドバイスができるよう、状況をお聞かせください。';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 14),
                const SizedBox(width: 8),
                const Text(
                  'AI ASSISTANT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 3.0,
                    color: AppTheme.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
            _buildSuggestions(),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_AIMessage message) {
    final isAI = message.isAI;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.black,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppTheme.gold, size: 14),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isAI ? AppTheme.offWhite : AppTheme.black,
                borderRadius: BorderRadius.circular(2),
                border: isAI
                    ? Border.all(color: AppTheme.paleGrey)
                    : null,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isAI ? AppTheme.charcoal : Colors.white,
                  fontSize: 13,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_messages.length > 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(height: 1, width: 16, color: AppTheme.gold),
              const SizedBox(width: 12),
              const Text(
                'SUGGESTIONS',
                style: TextStyle(
                  color: AppTheme.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () => _sendMessage(s),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.paleGrey),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: AppTheme.paleGrey, width: 0.5)),
      ),
      child: Row(
        children: [
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
                  hintText: 'AIに相談する...',
                  hintStyle: TextStyle(
                    color: AppTheme.lightGrey,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.black,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(Icons.arrow_upward,
                  color: AppTheme.gold, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIMessage {
  final String text;
  final bool isAI;
  _AIMessage({required this.text, required this.isAI});
}
