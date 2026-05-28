// LoginScreen — メール/パスワードログイン
// =====================================================
// Phase 1.5 - TSUNAGU
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _primary = Color(0xFFE63946);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      await UserService().signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      // AuthGate が自動的に次の画面に遷移する
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMsg = _mapAuthError(e));
    } catch (e) {
      setState(() => _errorMsg = 'ログインに失敗しました: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'メールアドレスを入力してから「パスワードを忘れた」を押してください');
      return;
    }
    try {
      await UserService().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードリセット用のメールを送信しました')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMsg = _mapAuthError(e));
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'このメールアドレスのアカウントが見つかりません';
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが間違っています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'このアカウントは利用停止されています';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく待ってから再度お試しください';
      case 'network-request-failed':
        return 'ネットワークエラー。接続を確認してください';
      default:
        return 'エラー: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TSUNAGU musubi-knot ロゴ
                    Center(
                      child: Image.asset(
                        'assets/icons/tsunagu_icon.png',
                        width: 96,
                        height: 96,
                        errorBuilder: (_, __, ___) => Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'T',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'TSUNAGU',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'おかえりなさい',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // メールアドレス
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'メールアドレス',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'メールアドレスを入力してください';
                        }
                        if (!v.contains('@')) return 'メールアドレスの形式が正しくありません';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // パスワード
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'パスワード',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'パスワードを入力してください';
                        }
                        if (v.length < 6) return 'パスワードは6文字以上で入力してください';
                        return null;
                      },
                    ),

                    // エラーメッセージ
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: TextStyle(
                                    color: Colors.red.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text('パスワードを忘れた？',
                            style: TextStyle(color: _primary)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ログインボタン
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'ログイン',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('アカウントをお持ちでない方は ',
                            style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpScreen(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '新規登録',
                            style: TextStyle(
                                color: _primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
