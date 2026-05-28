/// LINE Login service for TSUNAGU
///
/// フロー:
///   1. ユーザーが「LINE でログイン」ボタンを押す
///   2. login_screen.dart で startLogin() を呼ぶ
///      - state を生成して SharedPreferences に保存
///      - LINE 認可URL に同タブで遷移（Web）
///   3. LINE 認証完了後、callback URL（= 同じ Web アプリ）にリダイレクト
///      - URL に ?code=...&state=... が付く
///   4. main.dart 起動時に handleRedirectIfPresent() を呼ぶ
///      - URL から code/state を取り出し、Cloud Function `lineAuth` に POST
///      - 返却された Custom Token で Firebase Auth に signInWithCustomToken
///      - URL をクリーンアップ
///
/// 注意:
///   - Cloud Function URL は ${LINE_AUTH_FUNCTION_URL} を実環境に合わせて更新
///   - Channel ID は公開しても問題なし。Secret はサーバー側のみ。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Webプラットフォーム専用 import（dart:html は Web 以外でビルドエラーになるため条件付き）
import 'line_auth_web_stub.dart'
    if (dart.library.html) 'line_auth_web.dart' as web_helper;

class LineAuthService {
  LineAuthService._();
  static final LineAuthService instance = LineAuthService._();

  // ===== 設定値（公開情報のみ） =====
  static const String channelId = '2010225529';

  /// Cloud Function URL（asia-northeast1）
  /// プロジェクト ID: tsunagu-ai-community
  static const String cloudFunctionUrl =
      'https://asia-northeast1-tsunagu-ai-community.cloudfunctions.net/lineAuth';

  /// LINE Developers Console に登録するコールバック URL は
  /// 現在のアプリの origin（例: https://5060-xxx.sandbox.novita.ai/）と一致させる必要がある。
  /// このメソッドで動的に取得することで、プレビュー URL の変更にも追従できる。

  static const String _kStateKey = 'line_oauth_state';

  // 進行中フラグ（UI 側で参照）
  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);

  /// ランダムな state 文字列を生成（CSRF 対策）
  String _generateState() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// LINE 認証画面に遷移してログインを開始
  Future<void> startLogin() async {
    final state = _generateState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStateKey, state);

    final redirectUri = _currentRedirectUri();

    final authUrl = Uri.https('access.line.me', '/oauth2/v2.1/authorize', {
      'response_type': 'code',
      'client_id': channelId,
      'redirect_uri': redirectUri,
      'state': state,
      'scope': 'profile openid',
      'bot_prompt': 'normal',
    });

    if (kDebugMode) {
      debugPrint('[LineAuth] Authorize URL: $authUrl');
      debugPrint('[LineAuth] Redirect URI: $redirectUri');
    }

    if (kIsWeb) {
      // 同タブで遷移（リダイレクトフロー）
      web_helper.redirectTo(authUrl.toString());
    } else {
      // Mobile: 外部ブラウザで開く
      final ok = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        throw Exception('LINE 認証画面を開けませんでした');
      }
    }
  }

  /// 現在のリダイレクトURIを動的に決定
  /// Web: window.location.origin/ を使い、プレビュー URL の変更に追従
  /// 例: https://5060-xxx.sandbox.novita.ai/
  /// この値を LINE Console の「Callback URL」に **完全一致** で登録する必要がある。
  String _currentRedirectUri() {
    if (kIsWeb) {
      return web_helper.currentOrigin();
    }
    // Mobile 用は後で Deep Link を設定（今は Web 優先）
    return 'https://5060-iy1vrfuqc7ohomd9wcegs-ad490db5.sandbox.novita.ai/';
  }

  /// アプリ起動時に URL に ?code=... があれば交換処理を実行
  /// 戻り値: 認証成功なら true, パラメータが無ければ false
  Future<bool> handleRedirectIfPresent() async {
    if (!kIsWeb) return false;

    final params = web_helper.readQueryParams();
    final code = params['code'];
    final state = params['state'];
    final lineError = params['error'];

    if (lineError != null) {
      // ユーザーがキャンセル等
      web_helper.clearQueryParams();
      throw Exception('LINE 認証がキャンセルされました ($lineError)');
    }
    if (code == null || state == null) return false;

    // state 検証
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getString(_kStateKey);
    if (savedState == null || savedState != state) {
      web_helper.clearQueryParams();
      throw Exception('セキュリティエラー: state が一致しません');
    }
    await prefs.remove(_kStateKey);

    isProcessing.value = true;
    try {
      await _exchangeCodeAndSignIn(
        code: code,
        redirectUri: _currentRedirectUri(),
      );
      return true;
    } finally {
      isProcessing.value = false;
      // URL から code/state を消してリロード時の二重実行を防ぐ
      web_helper.clearQueryParams();
    }
  }

  Future<void> _exchangeCodeAndSignIn({
    required String code,
    required String redirectUri,
  }) async {
    if (kDebugMode) {
      debugPrint('[LineAuth] Exchanging code with Cloud Function...');
    }

    final resp = await http.post(
      Uri.parse(cloudFunctionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'redirectUri': redirectUri,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'LINE ログインに失敗しました (HTTP ${resp.statusCode}): ${resp.body}',
      );
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final customToken = data['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw Exception('Custom Token が取得できませんでした');
    }

    await FirebaseAuth.instance.signInWithCustomToken(customToken);

    if (kDebugMode) {
      debugPrint('[LineAuth] Firebase sign-in success: ${data['firebaseUid']}');
    }
  }
}
