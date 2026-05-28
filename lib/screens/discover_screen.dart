import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/connection_category.dart';
import '../theme/app_theme.dart';
import '../widgets/tsunagu_logo.dart';
import '../widgets/location_filter_sheet.dart';
import '../widgets/boost_button.dart';
import '../services/user_preferences.dart';
import '../services/ai_matching_service.dart';
import '../services/user_service.dart';
import 'profile_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with TickerProviderStateMixin {
  List<UserProfile> _allProfiles = [];
  List<UserProfile> _profiles = [];
  Map<String, int> _aiScores = {}; // userId -> 再計算スコア
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isDragging = false;
  ConnectionCategory? _selectedCategory; // null = ALL
  bool _loading = true;
  String? _loadError;
  Set<String> _swipedUids = {};

  late AnimationController _animController;
  Animation<Offset>? _animation;
  final _prefs = UserPreferences();
  final _userSvc = UserService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _prefs.addListener(_onPrefsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilesFromFirestore();
    });
  }

  void _onPrefsChanged() {
    if (mounted) _applyFilters();
  }

  /// Firestoreからユーザー一覧を取得 (release modeでis_seed_data除外)
  Future<void> _loadProfilesFromFirestore() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final currentUid = _userSvc.currentUid;
      if (currentUid == null) {
        throw Exception('ログインが必要です');
      }
      // 既にスワイプ済みのユーザーは除外
      _swipedUids = await _userSvc.getSwipedUids(currentUid);
      final users = await _userSvc.discoverUsers(
        currentUid: currentUid,
        excludeUids: _swipedUids,
        limit: 100,
      );
      setState(() {
        _allProfiles = users;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _loadError = 'ユーザー読込エラー: $e';
        _loading = false;
      });
    }
  }

  /// カテゴリ・地域フィルター＋AIスコアリングを適用
  void _applyFilters() {
    List<UserProfile> filtered = List.from(_allProfiles);

    // 1. カテゴリフィルター
    final category = _selectedCategory;
    if (category != null) {
      filtered = filtered
          .where((p) =>
              p.primaryCategory == category || p.openTo.contains(category))
          .toList();
    }

    // 2. 地域フィルター
    if (_prefs.filterPrefecture != null) {
      filtered = filtered
          .where((p) => p.prefecture == _prefs.filterPrefecture)
          .toList();
    }
    if (_prefs.filterTrainLine != null) {
      filtered = filtered
          .where((p) => p.trainLine == _prefs.filterTrainLine)
          .toList();
    }

    // 3. AIスコアリング・並べ替え
    final desired = category ?? _prefs.primaryCategory;
    final ranked = AIMatchingService.rankProfiles(
      profiles: filtered,
      desiredCategory: desired,
      self: _prefs.myProfile,
    );

    setState(() {
      _profiles = ranked.map((r) => r.profile).toList();
      _aiScores = {for (final r in ranked) r.profile.id: r.score};
      _currentIndex = 0;
      _dragOffset = Offset.zero;
      _dragAngle = 0;
    });
  }

  void _selectCategory(ConnectionCategory? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  Future<void> _openLocationFilter() async {
    await LocationFilterSheet.show(context);
    // SheetがUserPreferencesを直接更新→listenerが_applyFilters呼出
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta;
      _dragAngle = (_dragOffset.dx / size.width) * 0.4;
    });
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    final dx = _dragOffset.dx;
    final threshold = size.width * 0.3;

    if (dx.abs() > threshold) {
      _swipeCard(dx > 0, size);
    } else {
      _resetCard();
    }
  }

  void _swipeCard(bool isLike, Size size) {
    final endX = isLike ? size.width * 1.5 : -size.width * 1.5;
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, _dragOffset.dy),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _animation!.addListener(() {
      setState(() {
        _dragOffset = _animation!.value;
        _dragAngle = (_dragOffset.dx / size.width) * 0.4;
      });
    });

    _animController.forward(from: 0).then((_) async {
      // Firestoreにスワイプ記録 + 相互Like判定
      String? matchedId;
      if (_profiles.isNotEmpty) {
        final swipedUser = _profiles[_currentIndex % _profiles.length];
        final myUid = _userSvc.currentUid;
        if (myUid != null) {
          try {
            matchedId = await _userSvc.recordSwipe(
              fromUid: myUid,
              toUid: swipedUser.id,
              liked: isLike,
            );
            _swipedUids.add(swipedUser.id);
          } catch (e) {
            // 記録失敗してもUIは進める
            debugPrint('recordSwipe error: $e');
          }
        }
      }
      if (!mounted) return;
      setState(() {
        if (isLike) {
          _showMatchAnimation(matchedId: matchedId);
        }
        // スワイプ済みリストから削除
        if (_profiles.isNotEmpty) {
          _profiles.removeAt(_currentIndex % _profiles.length);
          if (_profiles.isEmpty) {
            _currentIndex = 0;
          } else {
            _currentIndex %= _profiles.length;
          }
        }
        _dragOffset = Offset.zero;
        _dragAngle = 0;
        _isDragging = false;
      });
    });
  }

  void _resetCard() {
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    ));

    _animation!.addListener(() {
      setState(() {
        _dragOffset = _animation!.value;
        _dragAngle = (_dragOffset.dx / 400) * 0.4;
      });
    });

    _animController.forward(from: 0).then((_) {
      setState(() {
        _isDragging = false;
      });
    });
  }

  void _showMatchAnimation({String? matchedId}) {
    // 相互Like成立時 (matchedId != null) は強制的に表示
    final isMutualMatch = matchedId != null;
    if (_profiles.isEmpty && !isMutualMatch) return;

    final showAnim = isMutualMatch ||
        (_profiles.isNotEmpty &&
            _profiles[_currentIndex % _profiles.length].aiMatchScore >= 90);
    if (!showAnim) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.black,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppTheme.vermillion, size: 20),
            const SizedBox(width: 12),
            Text(
              isMutualMatch
                  ? 'マッチ成立！ - お互いLikeしました'
                  : 'TSUNAGU - 繋がりました',
              style: const TextStyle(
                color: AppTheme.vermillion,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                fontSize: 13,
              ),
            ),
          ],
        ),
        duration: Duration(seconds: isMutualMatch ? 3 : 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
      ),
    );
  }

  void _handleActionButton(bool isLike) {
    final size = MediaQuery.of(context).size;
    setState(() {
      _dragOffset = Offset(isLike ? 50 : -50, 0);
    });
    _swipeCard(isLike, size);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildCategoryTabs()),
                Padding(
                  padding: const EdgeInsets.only(right: 16, left: 4),
                  child: const BoostButton(),
                ),
              ],
            ),
            if (_prefs.hasActiveLocationFilter) _buildFilterBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.vermillion),
                        ),
                      )
                    : _loadError != null
                        ? _buildErrorState()
                        : _profiles.isEmpty
                            ? _buildEmptyState()
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_profiles.length > 1)
                                    _buildCard(
                                      _profiles[(_currentIndex + 1) %
                                          _profiles.length],
                                      scale: 0.95,
                                      isBackground: true,
                                    ),
                                  _buildSwipeableCard(
                                      _profiles[
                                          _currentIndex % _profiles.length],
                                      size),
                                ],
                              ),
              ),
            ),
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBanner() {
    final parts = <String>[];
    if (_prefs.filterPrefecture != null) parts.add(_prefs.filterPrefecture!);
    if (_prefs.filterTrainLine != null) parts.add(_prefs.filterTrainLine!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppTheme.vermillion.withValues(alpha: 0.06),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              size: 12, color: AppTheme.vermillion),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(' / '),
              style: const TextStyle(
                color: AppTheme.vermillion,
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _prefs.clearFilters();
            },
            child: const Icon(Icons.close,
                size: 14, color: AppTheme.vermillion),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedCategory?.icon ?? Icons.search,
            size: 48,
            color: AppTheme.lightGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            '該当する人が見つかりません',
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _selectCategory(null),
            child: const Text(
              'すべて表示',
              style: TextStyle(
                color: AppTheme.vermillion,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadProfilesFromFirestore,
            icon: const Icon(Icons.refresh, color: AppTheme.vermillion),
            label: const Text(
              '再読込',
              style: TextStyle(
                color: AppTheme.vermillion,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            _loadError ?? '読込エラー',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadProfilesFromFirestore,
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vermillion,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [null, ...ConnectionCategory.values];
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.paleGrey, width: 0.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final label = cat?.label ?? 'すべて';
          final icon = cat?.icon ?? Icons.apps;

          return GestureDetector(
            onTap: () => _selectCategory(cat),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.vermillion : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.vermillion : AppTheme.paleGrey,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : AppTheme.darkGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.darkGrey,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final hasFilter = _prefs.hasActiveLocationFilter;
    return AppBar(
      backgroundColor: AppTheme.white,
      elevation: 0,
      title: const TsunaguBrand(fontSize: 16, iconSize: 24),
      leading: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: _openLocationFilter,
          ),
          if (hasFilter)
            const Positioned(
              right: 12,
              top: 12,
              child: CircleAvatar(
                radius: 3,
                backgroundColor: AppTheme.vermillion,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSwipeableCard(UserProfile profile, Size size) {
    return Transform.translate(
      offset: _dragOffset,
      child: Transform.rotate(
        angle: _dragAngle,
        child: GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(details, size),
          onPanEnd: (details) => _onPanEnd(details, size),
          onTap: () {
            if (!_isDragging) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileDetailScreen(profile: profile),
                ),
              );
            }
          },
          child: _buildCard(profile),
        ),
      ),
    );
  }

  Widget _buildCard(UserProfile profile,
      {double scale = 1.0, bool isBackground = false}) {
    final opacity = isBackground ? 0.6 : 1.0;
    final showLikeIndicator = _dragOffset.dx > 50 && !isBackground;
    final showPassIndicator = _dragOffset.dx < -50 && !isBackground;

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                Image.network(
                  profile.photos.first,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppTheme.paleGrey,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 1,
                            color: AppTheme.gold,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) => Container(
                    color: AppTheme.paleGrey,
                    child: const Icon(Icons.person_outline,
                        size: 80, color: AppTheme.lightGrey),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
                // Primary category badge (top left)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.vermillion,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(profile.primaryCategory.icon,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          profile.primaryCategory.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // AI Match badge (top right) - 再計算スコアを使用
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          'AI ${_aiScores[profile.id] ?? profile.aiMatchScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Profile info (bottom)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${profile.age}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 2,
                        width: 32,
                        color: AppTheme.vermillion,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${profile.occupation} · ${profile.location}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (profile.trainLine != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.train,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              profile.trainLine!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Open-to chips
                      Wrap(
                        spacing: 6,
                        children: profile.openTo.take(3).map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              cat.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // Like/Pass indicators
                if (showLikeIndicator)
                  Positioned(
                    top: 60,
                    left: 24,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.gold, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIKE',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showPassIndicator)
                  Positioned(
                    top: 60,
                    right: 24,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PASS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.refresh,
            size: 48,
            iconSize: 18,
            onTap: () {},
            isAccent: false,
          ),
          _buildActionButton(
            icon: Icons.close,
            size: 64,
            iconSize: 26,
            onTap: () => _handleActionButton(false),
            isAccent: false,
          ),
          _buildActionButton(
            icon: Icons.auto_awesome,
            size: 48,
            iconSize: 18,
            onTap: () {},
            isAccent: true,
          ),
          _buildActionButton(
            icon: Icons.favorite_outline,
            size: 64,
            iconSize: 26,
            onTap: () => _handleActionButton(true),
            isAccent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
    required bool isAccent,
  }) {
    final color = isAccent ? AppTheme.gold : AppTheme.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.white,
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}
