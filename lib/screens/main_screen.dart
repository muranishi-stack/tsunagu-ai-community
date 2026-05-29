import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'discover_screen.dart';
import 'action_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DiscoverScreen(),
    ActionScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          border: Border(
            top: BorderSide(color: AppTheme.border(context), width: 0.5),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _buildNavItem(0, Icons.search, Icons.search, 'さがす'),
                _buildNavItem(
                    1, Icons.bolt_outlined, Icons.bolt, 'アクション'),
                _buildNavItem(2, Icons.chat_bubble_outline, Icons.chat_bubble,
                    'マッチ'),
                _buildNavItem(
                    3, Icons.settings_outlined, Icons.settings, '設定'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    final activeColor = AppTheme.vermillion;
    final inactiveColor = AppTheme.textTertiary(context);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.3,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 12,
                height: 1,
                color: activeColor,
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
