// AuthGate — アプリ起動時の認証ルーティング
// =====================================================
// 1. 未ログイン → LoginScreen
// 2. ログイン済 + プロフィール未作成 → OnboardingScreen
// 3. ログイン済 + プロフィール有 → MainScreen
//
// プロフィール作成時はFirestoreのドキュメントを購読するため、
// users/{uid}が出現した瞬間に自動的にMainScreenへ遷移する。
//
// Phase 1.5 - TSUNAGU
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/location_service.dart';
import '../../services/user_preferences.dart';
import '../../services/user_service.dart';
import '../main_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

/// アプリ起動毎に GPS を1回サイレント更新するためのフラグ
/// （同セッション内で何度も AuthGate が再ビルドされても1回だけ実行する）
bool _gpsAutoUpdateAttempted = false;

/// 起動時GPS自動更新 (バックグラウンド・サイレント)
/// - 既に位置情報許可済みのユーザーのみ実行
/// - 失敗しても UI を妨げない
Future<void> _attemptStartupLocationUpdate() async {
  if (_gpsAutoUpdateAttempted) return;
  _gpsAutoUpdateAttempted = true;

  try {
    final result = await LocationService().tryDetectSilently();
    if (result == null) return;
    await UserService().updateUserLocation(
      latitude: result.latitude,
      longitude: result.longitude,
      prefecture: result.prefecture,
    );
    // メモリ上のフィルタ用座標も更新
    UserPreferences().setMyLocation(result.latitude, result.longitude);
  } catch (_) {
    // バックグラウンド更新失敗は静かに無視
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: UserService().authStateChanges,
      builder: (context, authSnap) {
        // 認証状態取得中
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = authSnap.data;

        // 未ログイン
        if (user == null) {
          return const LoginScreen();
        }

        // ログイン済 → users/{uid} を購読してリアルタイム遷移
        // プロフィール作成が完了した瞬間に自動でMainScreenに切り替わる
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, docSnap) {
            // 接続待ち
            if (docSnap.connectionState == ConnectionState.waiting &&
                !docSnap.hasData) {
              return const _SplashScreen();
            }

            // ドキュメントが存在しない or 必須フィールド (name + photos) 未入力
            // → オンボーディング画面
            final exists = docSnap.data?.exists ?? false;
            if (!exists) {
              return const OnboardingScreen();
            }

            final data = docSnap.data?.data();
            final name = (data?['name'] as String?) ?? '';
            final photos = (data?['photos'] as List?) ?? const [];
            final profileComplete = name.isNotEmpty && photos.isNotEmpty;

            if (!profileComplete) {
              return const OnboardingScreen();
            }

            // 最終アクティブ時刻を更新 (非同期、結果は待たない)
            UserService().touchLastActive();

            // 年齢フィルターの初期化 (自分の年齢 ±5 歳)
            final myAge = (data?['age'] as num?)?.toInt() ?? 30;
            UserPreferences().initAgeFilterFromMyAge(myAge);

            // 起動時GPS自動更新 (Choice B: 毎回起動時) — 非同期・サイレント
            _attemptStartupLocationUpdate();

            return const MainScreen();
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE63946); // TSUNAGU vermillion red

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TSUNAGU musubi-knot ロゴ
            Image.asset(
              'assets/icons/tsunagu_icon.png',
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'TSUNAGU',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'つなぐ — 5つのカテゴリで、新しい出会い',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ],
        ),
      ),
    );
  }
}
