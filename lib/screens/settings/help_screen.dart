// HelpScreen — ヘルプ・サポート
// =====================================================
// よくある質問（FAQ）+ お問い合わせ導線（メール / 法的文書）。
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/legal_urls.dart';
import '../../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _supportEmail = 'support@tsunagu-ai.app';

  static const _faqs = <(String, String)>[
    (
      'マッチが成立する仕組みは?',
      'お互いに「いいね」を送り合うとマッチが成立し、メッセージのやり取りが'
          'できるようになります。',
    ),
    (
      'HIGHLIGHT とは何ですか?',
      'HIGHLIGHT を使うと一定時間あなたのプロフィールが優先的に表示され、'
          'より多くの人の目に留まりやすくなります。',
    ),
    (
      '表示される相手を絞り込みたい',
      '設定 > マッチング設定 から、カテゴリ・年齢・距離で表示する相手を'
          '絞り込めます。',
    ),
    (
      '退会（アカウント削除）したい',
      'プロフィール画面の最下部「アカウントを削除する」から手続きできます。'
          '削除すると復元はできません。',
    ),
    (
      '不審なユーザーを見つけた',
      'プロフィールやチャット画面のメニューから通報できます。運営が内容を'
          '確認し対応します。',
    ),
    (
      '料金はかかりますか?',
      '基本機能は無料です。一部のプレミアム機能や HIGHLIGHT は有料です。'
          '詳細は設定 > プラン・課金 をご確認ください。',
    ),
  ];

  Future<void> _contactEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=${Uri.encodeComponent('【TSUNAGU】お問い合わせ')}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メールアプリを開けませんでした: $_supportEmail')),
        );
      }
    }
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプ・サポート',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      ),
      body: ListView(
        children: [
          _sectionHeader('よくある質問'),
          ..._faqs.map((f) => _FaqTile(question: f.$1, answer: f.$2)),
          const Divider(height: 32),
          _sectionHeader('お問い合わせ'),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: AppTheme.vermillion),
            title: const Text('メールで問い合わせる'),
            subtitle: const Text(_supportEmail),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _contactEmail(context),
          ),
          const Divider(height: 32),
          _sectionHeader('規約・ポリシー'),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(LegalUrls.termsOfService),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(LegalUrls.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('特定商取引法に基づく表示'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(LegalUrls.tokushoho),
          ),
          const SizedBox(height: 40),
        ],
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
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      iconColor: AppTheme.vermillion,
      title: Text(question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(answer,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppTheme.textSecondary(context))),
        ),
      ],
    );
  }
}
