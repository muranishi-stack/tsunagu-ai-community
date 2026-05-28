import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
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

void main() {
  // Use hash-based URL strategy so routes like /#/admin/login work everywhere
  // without requiring server-side SPA fallback configuration.
  setUrlStrategy(const HashUrlStrategy());
  runApp(const TsunaguApp());
}

class TsunaguApp extends StatelessWidget {
  const TsunaguApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TSUNAGU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      routes: {
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
      },
    );
  }
}
