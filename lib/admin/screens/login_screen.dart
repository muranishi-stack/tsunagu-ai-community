import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tsunagu_logo.dart';

/// 管理者ログイン画面
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@tsunagu.jp');
  final _passwordCtrl = TextEditingController(text: 'admin1234');
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AdminService().login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/admin/dashboard', (_) => false);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'メールアドレスまたはパスワードが正しくありません';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          // 背景装飾: 大きなロゴの淡い影
          Positioned(
            right: -120,
            bottom: -120,
            child: Opacity(
              opacity: 0.04,
              child: TsunaguLogo(size: 520),
            ),
          ),
          // メインカード
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 440,
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ロゴ (本物の結びマーク)
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.vermillionPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const TsunaguLogo(size: 64),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'TSUNAGU',
                        style: TextStyle(
                          color: AppTheme.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'ADMIN CONSOLE',
                        style: TextStyle(
                          color: AppTheme.vermillion,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                Container(
                  height: 1,
                  color: AppTheme.paleGrey,
                ),
                const SizedBox(height: 32),
                // メール
                const Text(
                  'EMAIL',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide:
                          const BorderSide(color: AppTheme.paleGrey, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide:
                          const BorderSide(color: AppTheme.paleGrey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(
                          color: AppTheme.vermillion, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // パスワード
                const Text(
                  'PASSWORD',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordCtrl,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppTheme.grey,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide:
                          const BorderSide(color: AppTheme.paleGrey, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide:
                          const BorderSide(color: AppTheme.paleGrey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2),
                      borderSide: const BorderSide(
                          color: AppTheme.vermillion, width: 1.5),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.vermillionPale,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                          color: AppTheme.vermillion.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AppTheme.vermillion),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.vermillion,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                // ログインボタン
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.lightGrey,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SIGN IN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // ヒント
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEMO CREDENTIALS',
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'admin@tsunagu.jp / admin1234',
                        style: TextStyle(
                          color: AppTheme.charcoal,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '© 2025 TSUNAGU. All rights reserved.',
                    style: TextStyle(
                      color: AppTheme.lightGrey,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
