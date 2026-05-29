// AiProfileService — Gemini プロフィール最適化（Cloud Functions 経由）
// =====================================================
// Cloud Function `optimizeProfile` を呼ぶ。API キーは Functions 側の
// Secret Manager に保管され、クライアントには出ない。
// 呼び出しには Firebase ID トークンを Authorization ヘッダで送る。
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AiProfileSuggestion {
  final String improvedBio;
  final List<String> tips;
  final List<String> suggestedInterests;

  const AiProfileSuggestion({
    required this.improvedBio,
    required this.tips,
    required this.suggestedInterests,
  });
}

class AiProfileService {
  static const _endpoint =
      'https://asia-northeast1-tsunagu-ai-community.cloudfunctions.net/optimizeProfile';

  /// プロフィールを Gemini で最適化する。
  /// 失敗時は Exception を投げる（呼び出し側で表示）。
  Future<AiProfileSuggestion> optimize({
    required String name,
    required int age,
    required String occupation,
    required String bio,
    required List<String> interests,
    required String primaryCategory,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('ログインが必要です');
    }
    final idToken = await user.getIdToken();

    final resp = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'name': name,
            'age': age,
            'occupation': occupation,
            'bio': bio,
            'interests': interests,
            'primaryCategory': primaryCategory,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      String msg = 'AI最適化に失敗しました (${resp.statusCode})';
      try {
        final err = jsonDecode(resp.body);
        if (err is Map && err['error'] != null) msg = err['error'].toString();
      } catch (_) {}
      throw Exception(msg);
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return AiProfileSuggestion(
      improvedBio: (data['improvedBio'] as String?) ?? '',
      tips: ((data['tips'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      suggestedInterests: ((data['suggestedInterests'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
