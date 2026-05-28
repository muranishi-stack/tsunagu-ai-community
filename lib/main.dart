import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'services/super_like_service.dart';
import 'services/line_auth_service.dart';
import 'screens/auth/auth_gate.dart';
import 'admin/screens/login_screen.dart';
import 'admin/screens/dashboard_screen.dart';
import 'admin/screens/users_screen.dart';
import 'admin/screens/revenue_screen.dart';
import 'admin/screens/boosts_screen.dart';
import 'admin/screens/reports_screen.dart';
import 'admin/screens/analytics_screen.dart';
import 'admin/screens/announcements_screen.dart';
import 'admin/screens/settings_screen.dart';
import 'admin/screens/ai_moderation_screen.dart';
import 'admin/screens/data_sources_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use hash-based URL strategy so routes like /#/admin/login work everywhere
  // without requiring server-side SPA fallback configuration.
  setUrlStrategy(const HashUrlStrategy());

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('✅ Firebase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Firebase initialization error: $e');
    }
  }

  // Initialize ThemeService (load saved theme mode)
  await ThemeService().init();

  // Initialize SuperLikeService (load monthly quota)
  await SuperLikeService().initialize();

  // Handle LINE OAuth redirect callback if present in URL
  // （?code=...&state=... が付いていれば Cloud Function に投げて Firebase Auth にサインイン）
  if (kIsWeb) {
    try {
      final handled = await LineAuthService.instance.handleRedirectIfPresent();
      if (handled && kDebugMode) {
        debugPrint('✅ LINE login redirect handled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ LINE redirect handling failed: $e');
      }
      // エラーは UI 側で改めて表示する必要があるが、起動はブロックしない
    }
  }

  runApp(const TsunaguApp());
}

class TsunaguApp extends StatelessWidget {
  const TsunaguApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'TSUNAGU',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: const AuthGate(),
          routes: _adminRoutes,
        );
      },
    );
  }

  Map<String, WidgetBuilder> get _adminRoutes => {
        '/admin/login': (_) => const AdminLoginScreen(),
        '/admin/dashboard': (_) => const AdminDashboardScreen(),
        '/admin/users': (_) => const AdminUsersScreen(),
        '/admin/revenue': (_) => const AdminRevenueScreen(),
        '/admin/boosts': (_) => const AdminBoostsScreen(),
        '/admin/reports': (_) => const AdminReportsScreen(),
        '/admin/ai-moderation': (_) => const AdminAiModerationScreen(),
        '/admin/analytics': (_) => const AdminAnalyticsScreen(),
        '/admin/announcements': (_) => const AdminAnnouncementsScreen(),
        '/admin/data-sources': (_) => const AdminDataSourcesScreen(),
        '/admin/settings': (_) => const AdminSettingsScreen(),
      };
}
