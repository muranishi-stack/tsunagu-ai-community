import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/connection_category.dart';
import '../theme/app_theme.dart';
import '../widgets/tsunagu_logo.dart';
import '../widgets/location_filter_sheet.dart';
import '../services/user_preferences.dart';
import '../services/ai_matching_service.dart';
import '../services/user_service.dart';
import '../utils/distance_util.dart';
import '../services/super_like_service.dart';
import '../services/subscription_service.dart';
import 'profile_detail_screen.dart';
import 'subscription_screen.dart';

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

  // Phase 1.11.9: Listener ベースのドラッグ状態 (iOS Safari 対応)
  Offset? _pointerStartPos;
  Offset _pointerAccumDelta = Offset.zero;

  late AnimationController _animController;
  Animation<Offset>? _animation;
  final _prefs = UserPreferences();
  final _userSvc = UserService();
  final _superLike = SuperLikeService();
  final _subscription = SubscriptionService();

  /// Rewind用スワイプ履歴スタック（最新が末尾）
  /// 各エントリ: { profile, isLike, isSuperLike, insertIndex }
  final List<_SwipeHistoryEntry> _swipeHistory = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _prefs.addListener(_onPrefsChanged);
    _superLike.addListener(_onSuperLikeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfilesFromFirestore();
    });
  }

  void _onSuperLikeChanged() {
    if (mounted) setState(() {});
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

    // 0. スワイプ済みユーザーを除外 (Phase 1.11.9)
    filtered = filtered.where((p) => !_swipedUids.contains(p.id)).toList();

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

    // 2.3 年齢フィルター
    // Phase 1.11.9: ユーザーが明示的にカスタマイズした場合のみ適用する。
    // 初期表示で年齢±5に勝手に絞られて 0人になるケースを防ぐ。
    if (_prefs.hasActiveAgeFilter) {
      filtered = filtered
          .where((p) =>
              p.age >= _prefs.filterMinAge && p.age <= _prefs.filterMaxAge)
          .toList();
    }

    // 2.5 距離フィルター (Choice B: lat/lng 未保存ユーザーは完全非表示)
    final maxKm = _prefs.filterMaxDistanceKm;
    if (maxKm != null &&
        _prefs.myLatitude != null &&
        _prefs.myLongitude != null) {
      filtered = filtered.where((p) {
        // 相手の lat/lng が未保存 → 非表示 (Choice B)
        if (p.latitude == null || p.longitude == null) return false;
        final km = DistanceUtil.calculateKm(
          _prefs.myLatitude!,
          _prefs.myLongitude!,
          p.latitude!,
          p.longitude!,
        );
        return km <= maxKm;
      }).toList();
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

  /// カード上に表示する距離ラベル ("2.3km" など)。
  /// 自分または相手の lat/lng が未設定の場合は null を返す（バッジ非表示）。
  String? _distanceLabelFor(UserProfile profile) {
    final myLat = _prefs.myLatitude;
    final myLng = _prefs.myLongitude;
    if (myLat == null || myLng == null) return null;
    if (profile.latitude == null || profile.longitude == null) return null;
    final km = DistanceUtil.calculateKm(
      myLat,
      myLng,
      profile.latitude!,
      profile.longitude!,
    );
    return DistanceUtil.formatKm(km);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    _superLike.removeListener(_onSuperLikeChanged);
    _animController.dispose();
    super.dispose();
  }

  void _swipeCard(bool isLike, Size size, {bool isSuperLike = false}) {
    final endX = isLike ? size.width * 1.5 : -size.width * 1.5;
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, _dragOffset.dy),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _animation!.addListener(() {
      if (!mounted) return;
      setState(() {
        _dragOffset = _animation!.value;
        _dragAngle = (_dragOffset.dx / size.width) * 0.4;
      });
    });

    // Phase 1.11.9: iOS Safari + CanvasKit で .then() コールバックが
    // 発火しない問題を回避するため AnimationStatusListener を使用。
    // 完了処理を同期的に登録し、アニメ完了 = カード進行を保証する。
    late final AnimationStatusListener statusListener;
    statusListener = (AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _animController.removeStatusListener(statusListener);
        _onSwipeAnimationComplete(isLike, isSuperLike);
      }
    };
    _animController.addStatusListener(statusListener);
    _animController.forward(from: 0);
  }

  /// _swipeCard のアニメーション完了時のハンドラ
  /// Phase 1.11.9: Future.then から分離して iOS Safari 互換性を確保
  void _onSwipeAnimationComplete(bool isLike, bool isSuperLike) {
    if (!mounted) return;

    // どのプロフィールがスワイプされたか確定
    UserProfile? swipedProfile;
    int? swipedIdx;
    if (_profiles.isNotEmpty) {
      swipedIdx = _currentIndex % _profiles.length;
      swipedProfile = _profiles[swipedIdx];
    }

    // UI を先に進める (Firestore は非同期で記録)
    setState(() {
      if (swipedProfile != null && swipedIdx != null) {
        _swipeHistory.add(_SwipeHistoryEntry(
          profile: swipedProfile,
          isLike: isLike,
          isSuperLike: isSuperLike,
          insertIndex: swipedIdx,
        ));
        if (_swipeHistory.length > 10) {
          _swipeHistory.removeAt(0);
        }
        _swipedUids.add(swipedProfile.id);

        // List 参照を置き換えて確実に再描画
        final newProfiles = List<UserProfile>.from(_profiles);
        newProfiles.removeAt(swipedIdx);
        _profiles = newProfiles;
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

    // Firestore 書き込みは非同期で実行
    if (swipedProfile != null) {
      final myUid = _userSvc.currentUid;
      if (myUid != null) {
        _userSvc.recordSwipe(
          fromUid: myUid,
          toUid: swipedProfile.id,
          liked: isLike,
          isSuperLike: isSuperLike,
        ).then((matchedId) {
          if (isLike && mounted) {
            _showMatchAnimation(
              matchedId: matchedId,
              isSuperLike: isSuperLike,
            );
          }
        }).catchError((e) {
          debugPrint('recordSwipe error: $e');
        });
      }
    }
  }

  /// Rewind: 直前のスワイプを取り消す（プレミアム限定機能）
  Future<void> _handleRewind() async {
    // 履歴がなければ何もしない
    if (_swipeHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('巻き戻すスワイプがありません'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // プレミアム限定
    if (!_subscription.hasActivePremium) {
      _showPremiumGate(
        title: 'Rewindはプレミアム機能',
        message: '直前のスワイプを取り消すには\nプレミアムプランへの加入が必要です。',
      );
      return;
    }

    final last = _swipeHistory.removeLast();
    final myUid = _userSvc.currentUid;
    if (myUid != null) {
      try {
        await _userSvc.undoSwipe(fromUid: myUid, toUid: last.profile.id);
        _swipedUids.remove(last.profile.id);
      } catch (e) {
        debugPrint('undoSwipe error: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      // プロフィールを元の位置に戻す
      final insertAt = last.insertIndex.clamp(0, _profiles.length);
      _profiles.insert(insertAt, last.profile);
      _currentIndex = insertAt;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.vermillion,
        content: Row(
          children: [
            const Icon(Icons.replay, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${last.profile.name}さんへのスワイプを取り消しました',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// SuperLike送信処理
  Future<void> _handleSuperLike(Size size) async {
    if (_profiles.isEmpty) return;
    if (_isDragging) return;

    // 残数チェック
    if (!_superLike.canSend) {
      _showSuperLikeExhaustedDialog();
      return;
    }

    // 残数消費
    final consumed = await _superLike.consumeSuperLike();
    if (!consumed) return;

    // SuperLike送信（Likeとして扱い、isSuperLike=trueでマーク）
    setState(() {
      _dragOffset = Offset(0, -50);
    });
    _swipeCard(true, size, isSuperLike: true);
  }

  void _showSuperLikeExhaustedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: AppTheme.vermillion),
            SizedBox(width: 8),
            Text('SUPER ATTACK 残数 0'),
          ],
        ),
        content: Text(
          '今月のSUPER ATTACK送信回数（5回）を使い切りました。\n来月1日にリセットされます。',
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showPremiumGate({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: AppTheme.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: AppTheme.textPrimary(context)),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vermillion,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
            child: const Text('プランを見る'),
          ),
        ],
      ),
    );
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

  void _showMatchAnimation({String? matchedId, bool isSuperLike = false}) {
    // 相互Like成立時 (matchedId != null) は強制的に表示
    final isMutualMatch = matchedId != null;

    // SuperLikeはLike送信時に必ずフィードバック表示
    if (isSuperLike) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.vermillion,
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isMutualMatch
                      ? 'SUPER ATTACK で COMPLETE!! 🎉'
                      : 'SUPER ATTACK 送信完了 - 相手に目立って通知されます',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '残${_superLike.remaining}/${SuperLikeService.monthlyQuota}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          duration: Duration(seconds: isMutualMatch ? 3 : 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(24),
        ),
      );
      return;
    }

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
                  ? 'COMPLETE!! - お互いATTACKしました'
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

  /// ATTACK/SKIPボタンの共通ハンドラ (Phase 1.11.2 互換)
  void _handleActionButton(bool isLike) {
    if (_profiles.isEmpty) return;
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
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // カテゴリタブのみ独立した行で全幅をスクロール
            // BOOSTボタンはAppBarのactionsに移動して1行レイアウトを実現
            _buildCategoryTabs(),
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
                                    KeyedSubtree(
                                      key: ValueKey('bg_${_profiles[(_currentIndex + 1) % _profiles.length].id}'),
                                      child: _buildCard(
                                        _profiles[(_currentIndex + 1) %
                                            _profiles.length],
                                        scale: 0.95,
                                        isBackground: true,
                                      ),
                                    ),
                                  KeyedSubtree(
                                    key: ValueKey('fg_${_profiles[_currentIndex % _profiles.length].id}'),
                                    child: _buildSwipeableCard(
                                        _profiles[
                                            _currentIndex % _profiles.length],
                                        size),
                                  ),
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
            color: AppTheme.textTertiary(context),
          ),
          const SizedBox(height: 16),
          Text(
            '該当する人が見つかりません',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).dividerColor, width: 0.5),
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
                  color: isSelected
                      ? AppTheme.vermillion
                      : AppTheme.border(context),
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
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondary(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary(context),
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
        // HIGHLIGHTボタンはCONNECTIONS画面に移設済み
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSwipeableCard(UserProfile profile, Size size) {
    // Phase 1.11.9: iOS Safari でドラッグジェスチャーを確実に拾うため
    // Listener (Pointer) ベースのドラッグ実装に切り替え。
    // GestureDetector の Pan は iOS Safari + CanvasKit で拾えない場合があるが、
    // Listener の onPointerMove は確実に動作する。
    return Transform.translate(
      offset: _dragOffset,
      child: Transform.rotate(
        angle: _dragAngle,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            _pointerStartPos = event.position;
            _pointerAccumDelta = Offset.zero;
            _isDragging = false;
          },
          onPointerMove: (event) {
            if (_pointerStartPos == null) return;
            final delta = event.position - _pointerStartPos!;
            _pointerAccumDelta = delta;
            // 8px 以上動いたらドラッグ確定
            if (!_isDragging && delta.distance > 8) {
              setState(() {
                _isDragging = true;
              });
            }
            if (_isDragging) {
              setState(() {
                _dragOffset = delta;
                _dragAngle = (delta.dx / size.width) * 0.4;
              });
            }
          },
          onPointerUp: (event) {
            final startPos = _pointerStartPos;
            final accumDelta = _pointerAccumDelta;
            _pointerStartPos = null;
            if (startPos == null) return;

            if (_isDragging) {
              // ドラッグ完了処理
              final dx = accumDelta.dx;
              final threshold = size.width * 0.3;
              if (dx.abs() > threshold) {
                _swipeCard(dx > 0, size);
              } else {
                _resetCard();
              }
              // _isDragging のリセットは _swipeCard/_resetCard 内で行う
            } else {
              // 動いていない = タップ扱い
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileDetailScreen(profile: profile),
                ),
              );
            }
          },
          onPointerCancel: (event) {
            _pointerStartPos = null;
            if (_isDragging) {
              _resetCard();
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
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                    alpha: AppTheme.isDark(context) ? 0.4 : 0.08),
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
                  key: ValueKey('img_${profile.id}'),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppTheme.surfaceVariant(context),
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
                    color: AppTheme.surfaceVariant(context),
                    child: Icon(Icons.person_outline,
                        size: 80, color: AppTheme.textTertiary(context)),
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
                // 距離は名前横（A案）に表示するため、右上バッジは削除
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
                          Flexible(
                            child: Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w200,
                                letterSpacing: 1.5,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                          // 距離表示 (A案: 名前横併記)
                          if (_distanceLabelFor(profile) != null) ...[
                            const SizedBox(width: 14),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place,
                                    size: 14,
                                    color: Colors.white
                                        .withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _distanceLabelFor(profile)!,
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.95),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                          'ATTACK',
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
                          'SKIP',
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
    final size = MediaQuery.of(context).size;
    final superLikeRemaining = _superLike.remaining;
    final isPremium = _subscription.hasActivePremium;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind: プレミアム限定（無料時は鍵バッジ）
          _buildActionButton(
            icon: Icons.replay,
            iconColor: AppTheme.gold,
            size: 48,
            iconSize: 22,
            onTap: _handleRewind,
            lockBadge: !isPremium,
          ),
          // SKIP
          _buildActionButton(
            icon: Icons.close,
            iconColor: AppTheme.charcoal,
            size: 64,
            iconSize: 28,
            onTap: () => _handleActionButton(false),
          ),
          // SuperLike: 月5回制限（残数バッジ表示）
          _buildActionButton(
            icon: Icons.auto_awesome,
            iconColor: AppTheme.vermillion,
            size: 48,
            iconSize: 22,
            onTap: () => _handleSuperLike(size),
            counterBadge: superLikeRemaining,
            counterColor: superLikeRemaining > 0
                ? AppTheme.vermillion
                : Colors.grey,
          ),
          // ATTACK
          _buildActionButton(
            icon: Icons.favorite,
            iconColor: AppTheme.vermillion,
            size: 64,
            iconSize: 28,
            onTap: () => _handleActionButton(true),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
    int? counterBadge,
    Color? counterColor,
    bool lockBadge = false,
  }) {
    // Phase 1.11.9: ヒットテスト問題を解決するため Material + InkWell に変更
    // Stack(clipBehavior: Clip.none) + Positioned バッジが GestureDetector の
    // ヒットテストを阻害していた問題を修正
    return SizedBox(
      width: size + 12, // バッジ分の余裕を含む明示的サイズ
      height: size + 12,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // メインボタン本体（Material + InkWell で確実なタップ処理）
          Material(
            color: AppTheme.surface(context),
            shape: CircleBorder(
              side: BorderSide(
                color: iconColor.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            elevation: AppTheme.isDark(context) ? 4 : 2,
            shadowColor: Colors.black.withValues(
              alpha: AppTheme.isDark(context) ? 0.4 : 0.2,
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(icon, size: iconSize, color: iconColor),
              ),
            ),
          ),
          // SuperLike残数バッジ（IgnorePointer でタップを透過）
          if (counterBadge != null)
            Positioned(
              top: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: counterColor ?? AppTheme.vermillion,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.surface(context),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '$counterBadge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          // Rewind鍵バッジ（プレミアム限定表示、IgnorePointer でタップを透過）
          if (lockBadge)
            Positioned(
              top: 2,
              right: 2,
              child: IgnorePointer(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.surface(context),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rewind用のスワイプ履歴エントリ
class _SwipeHistoryEntry {
  final UserProfile profile;
  final bool isLike;
  final bool isSuperLike;
  final int insertIndex;
  _SwipeHistoryEntry({
    required this.profile,
    required this.isLike,
    required this.isSuperLike,
    required this.insertIndex,
  });
}
