import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/connection_category.dart';
import '../../models/subscription.dart';
import '../models/admin_models.dart';

/// 管理画面のデータと認証を扱うサービス（モック実装）
class AdminService extends ChangeNotifier {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  AdminAccount? _currentAdmin;
  final List<AdminUser> _users = [];
  final List<Report> _reports = [];
  final List<RevenueRecord> _revenues = [];
  final List<AdminAnnouncement> _announcements = [];
  final List<AiModerationFlag> _aiFlags = [];
  final List<DataSourceIntegration> _dataSources = [];
  bool _dataGenerated = false;

  // AI スキャナー状態
  Timer? _aiScannerTimer;
  DateTime _aiScannerLastRun = DateTime.now();
  int _aiScannerScannedToday = 0;
  bool _aiScannerIsRunning = false;
  int _aiFlagSeq = 0;

  // ===== 認証 =====

  AdminAccount? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _currentAdmin != null;

  /// モックログイン（admin@tsunagu.jp / admin1234）
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (email == 'admin@tsunagu.jp' && password == 'admin1234') {
      _currentAdmin = AdminAccount(
        id: 'admin_001',
        name: 'のりあつ',
        email: email,
        role: AdminRole.superAdmin,
        lastLoginAt: DateTime.now(),
      );
      _generateMockData();
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentAdmin = null;
    stopAiScanner();
    notifyListeners();
  }

  // ===== データアクセス =====

  List<AdminUser> get users => List.unmodifiable(_users);
  List<Report> get reports => List.unmodifiable(_reports);
  List<RevenueRecord> get revenues => List.unmodifiable(_revenues);
  List<AdminAnnouncement> get announcements =>
      List.unmodifiable(_announcements);

  /// 検索＆フィルタ
  List<AdminUser> searchUsers({
    String? query,
    UserStatus? status,
    ConnectionCategory? category,
  }) {
    return _users.where((u) {
      if (status != null && u.status != status) return false;
      if (category != null && u.primaryCategory != category) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!u.name.toLowerCase().contains(q) &&
            !u.email.toLowerCase().contains(q) &&
            !u.id.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ===== KPI =====

  DashboardKPI get kpi {
    if (!_dataGenerated) _generateMockData();
    final activeUsers =
        _users.where((u) => u.status == UserStatus.active).length;
    final monthlyRevenue = _revenues
        .where((r) =>
            r.status == TransactionStatus.completed &&
            r.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .fold(0, (sum, r) => sum + r.amountJpy);
    final mrr = _revenues
        .where((r) =>
            r.status == TransactionStatus.completed &&
            (r.planType == PlanType.allCategory ||
                r.planType == PlanType.singleCategory) &&
            r.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .fold(0, (sum, r) => sum + r.amountJpy);
    final activeSubs = _users
        .where((u) =>
            u.activePlan == PlanType.allCategory ||
            u.activePlan == PlanType.singleCategory ||
            u.activePlan == PlanType.freeTrial)
        .length;
    final paid = _users
        .where((u) =>
            u.activePlan == PlanType.allCategory ||
            u.activePlan == PlanType.singleCategory)
        .length;
    final conversion = activeUsers > 0 ? (paid / activeUsers * 100) : 0.0;
    final pending =
        _reports.where((r) => r.status == ReportStatus.pending).length;

    return DashboardKPI(
      totalUsers: _users.length,
      activeUsersMau: (activeUsers * 0.72).round(),
      activeUsersDau: (activeUsers * 0.24).round(),
      newUsersToday: 18,
      monthlyRecurringRevenue: mrr,
      totalRevenue30d: monthlyRevenue,
      churnRate: 4.8,
      totalMatches30d: 12_847,
      activeSubscriptions: activeSubs,
      activeBoosts: 47,
      conversionRate: conversion,
      pendingReports: pending,
    );
  }

  // ===== 時系列 =====

  /// 過去30日の売上推移
  List<TimeSeriesPoint> getRevenueTimeSeries() {
    final now = DateTime.now();
    final random = Random(42);
    return List.generate(30, (i) {
      final date = now.subtract(Duration(days: 29 - i));
      // 週末ピーク + 上昇トレンドの疑似データ
      final base = 80_000 + (i * 2_500);
      final weekend = (date.weekday == 6 || date.weekday == 7) ? 30_000 : 0;
      final noise = random.nextInt(40_000) - 20_000;
      return TimeSeriesPoint(
        date: date,
        value: (base + weekend + noise).toDouble().clamp(0, 999_999),
      );
    });
  }

  /// 過去30日の新規ユーザー
  List<TimeSeriesPoint> getNewUserTimeSeries() {
    final now = DateTime.now();
    final random = Random(7);
    return List.generate(30, (i) {
      final date = now.subtract(Duration(days: 29 - i));
      final base = 30 + (i * 0.8);
      final noise = random.nextInt(20) - 10;
      return TimeSeriesPoint(date: date, value: (base + noise).clamp(0, 200));
    });
  }

  // ===== 集計 =====

  List<PlanRevenueBreakdown> get planBreakdown {
    final byPlan = <PlanType, List<RevenueRecord>>{};
    for (final r in _revenues) {
      if (r.status != TransactionStatus.completed) continue;
      byPlan.putIfAbsent(r.planType, () => []).add(r);
    }
    return byPlan.entries.map((e) {
      return PlanRevenueBreakdown(
        planType: e.key,
        count: e.value.length,
        totalRevenue: e.value.fold(0, (sum, r) => sum + r.amountJpy),
      );
    }).toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  }

  List<CategoryDistribution> get categoryDistribution {
    final total = _users.length;
    final byCategory = <ConnectionCategory, int>{};
    for (final u in _users) {
      byCategory[u.primaryCategory] =
          (byCategory[u.primaryCategory] ?? 0) + 1;
    }
    return ConnectionCategory.values.map((cat) {
      final count = byCategory[cat] ?? 0;
      return CategoryDistribution(
        category: cat,
        userCount: count,
        percentage: total > 0 ? (count / total * 100) : 0,
      );
    }).toList()
      ..sort((a, b) => b.userCount.compareTo(a.userCount));
  }

  List<PrefectureDistribution> get topPrefectures {
    final byPref = <String, int>{};
    for (final u in _users) {
      byPref[u.prefecture] = (byPref[u.prefecture] ?? 0) + 1;
    }
    return byPref.entries
        .map((e) => PrefectureDistribution(prefecture: e.key, userCount: e.value))
        .toList()
      ..sort((a, b) => b.userCount.compareTo(a.userCount));
  }

  // ===== 操作 =====

  void suspendUser(String userId) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      final u = _users[idx];
      _users[idx] = AdminUser(
        id: u.id,
        name: u.name,
        email: u.email,
        age: u.age,
        prefecture: u.prefecture,
        primaryCategory: u.primaryCategory,
        joinedAt: u.joinedAt,
        lastActiveAt: u.lastActiveAt,
        status: UserStatus.suspended,
        matchCount: u.matchCount,
        reportCount: u.reportCount,
        activePlan: u.activePlan,
        avatarUrl: u.avatarUrl,
      );
      notifyListeners();
    }
  }

  void reactivateUser(String userId) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      final u = _users[idx];
      _users[idx] = AdminUser(
        id: u.id,
        name: u.name,
        email: u.email,
        age: u.age,
        prefecture: u.prefecture,
        primaryCategory: u.primaryCategory,
        joinedAt: u.joinedAt,
        lastActiveAt: u.lastActiveAt,
        status: UserStatus.active,
        matchCount: u.matchCount,
        reportCount: u.reportCount,
        activePlan: u.activePlan,
        avatarUrl: u.avatarUrl,
      );
      notifyListeners();
    }
  }

  void resolveReport(String reportId, ReportStatus newStatus) {
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx >= 0) {
      final r = _reports[idx];
      _reports[idx] = Report(
        id: r.id,
        reporterId: r.reporterId,
        reporterName: r.reporterName,
        targetUserId: r.targetUserId,
        targetUserName: r.targetUserName,
        reason: r.reason,
        description: r.description,
        createdAt: r.createdAt,
        status: newStatus,
      );
      notifyListeners();
    }
  }

  void refundTransaction(String transactionId) {
    final idx = _revenues.indexWhere((r) => r.id == transactionId);
    if (idx >= 0) {
      final r = _revenues[idx];
      _revenues[idx] = RevenueRecord(
        id: r.id,
        date: r.date,
        userId: r.userId,
        userName: r.userName,
        planType: r.planType,
        amountJpy: r.amountJpy,
        paymentMethod: r.paymentMethod,
        status: TransactionStatus.refunded,
        selectedCategory: r.selectedCategory,
      );
      notifyListeners();
    }
  }

  void publishAnnouncement({
    required String title,
    required String body,
  }) {
    _announcements.insert(
      0,
      AdminAnnouncement(
        id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        publishedAt: DateTime.now(),
        status: AnnouncementStatus.published,
        reachedUsers: _users.where((u) => u.status == UserStatus.active).length,
      ),
    );
    notifyListeners();
  }

  // ===== アクティビティフィード =====

  /// ダッシュボードに表示するリアルタイム風アクティビティイベント
  List<ActivityEvent> get recentActivities {
    if (!_dataGenerated) _generateMockData();
    final events = <ActivityEvent>[];

    // 新規登録 (直近の登録ユーザー)
    final recentUsers = _users
        .where((u) => u.joinedAt
            .isAfter(DateTime.now().subtract(const Duration(hours: 12))))
        .toList()
      ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
    for (final u in recentUsers.take(8)) {
      events.add(ActivityEvent(
        type: ActivityType.userSignup,
        timestamp: u.joinedAt,
        title: '新規登録',
        description: '${u.name} さんが ${u.primaryCategory.label} カテゴリで登録',
        userId: u.id,
        userName: u.name,
      ));
    }

    // 直近の取引
    final recentRevenues = _revenues
        .where((r) =>
            r.status == TransactionStatus.completed &&
            r.date.isAfter(DateTime.now().subtract(const Duration(hours: 12))))
        .take(8)
        .toList();
    for (final r in recentRevenues) {
      String desc;
      switch (r.planType) {
        case PlanType.allCategory:
          desc = '全カテゴリ月額 (¥${r.amountJpy}) を購入';
          break;
        case PlanType.singleCategory:
          desc =
              '${r.selectedCategory?.label ?? "カテゴリ"}月額 (¥${r.amountJpy}) を購入';
          break;
        case PlanType.boost:
          desc = 'ブースト (¥${r.amountJpy}) を購入';
          break;
        case PlanType.freeTrial:
          desc = '無料体験を開始';
          break;
      }
      events.add(ActivityEvent(
        type: r.planType == PlanType.boost
            ? ActivityType.boostPurchase
            : ActivityType.subscription,
        timestamp: r.date,
        title: '課金',
        description: '${r.userName} さんが $desc',
        userId: r.userId,
        userName: r.userName,
      ));
    }

    // 通報
    for (final r in _reports.take(5)) {
      events.add(ActivityEvent(
        type: ActivityType.report,
        timestamp: r.createdAt,
        title: '新規通報',
        description: '${r.reporterName} → ${r.targetUserName} (${r.reason.label})',
        userId: r.targetUserId,
        userName: r.targetUserName,
      ));
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events.take(20).toList();
  }

  // ===== CSV エクスポート =====

  String revenuesToCsv() {
    final buf = StringBuffer();
    buf.writeln(
        'tx_id,date,user_id,user_name,plan_type,amount_jpy,payment_method,status,selected_category');
    for (final r in _revenues) {
      buf.writeln([
        r.id,
        r.date.toIso8601String(),
        r.userId,
        '"${r.userName}"',
        r.planType.name,
        r.amountJpy,
        r.paymentMethod.name,
        r.status.name,
        r.selectedCategory?.name ?? '',
      ].join(','));
    }
    return buf.toString();
  }

  String usersToCsv() {
    final buf = StringBuffer();
    buf.writeln(
        'user_id,name,email,age,prefecture,primary_category,joined_at,last_active_at,status,match_count,report_count,active_plan');
    for (final u in _users) {
      buf.writeln([
        u.id,
        '"${u.name}"',
        u.email,
        u.age,
        '"${u.prefecture}"',
        u.primaryCategory.name,
        u.joinedAt.toIso8601String(),
        u.lastActiveAt.toIso8601String(),
        u.status.name,
        u.matchCount,
        u.reportCount,
        u.activePlan?.name ?? '',
      ].join(','));
    }
    return buf.toString();
  }

  // ===== AI モデレーション =====

  /// AIフラグ全件 (検出時刻降順)
  List<AiModerationFlag> get aiFlags {
    final list = List<AiModerationFlag>.from(_aiFlags);
    list.sort((a, b) {
      // CRITICAL を最優先、次に検出時刻降順
      if (a.severity != b.severity) {
        return a.severity.index.compareTo(b.severity.index);
      }
      return b.detectedAt.compareTo(a.detectedAt);
    });
    return List.unmodifiable(list);
  }

  /// 統計
  AiScannerStats get aiScannerStats {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final flaggedToday =
        _aiFlags.where((f) => f.detectedAt.isAfter(start)).length;
    final critical = _aiFlags
        .where((f) =>
            f.severity == AiFlagSeverity.critical &&
            f.status != AiFlagReviewStatus.falsePositive &&
            f.status != AiFlagReviewStatus.confirmed)
        .length;
    final pending = _aiFlags
        .where((f) =>
            f.status == AiFlagReviewStatus.pending ||
            f.status == AiFlagReviewStatus.underReview)
        .length;
    return AiScannerStats(
      lastRunAt: _aiScannerLastRun,
      totalScannedToday: _aiScannerScannedToday,
      totalFlaggedToday: flaggedToday,
      criticalCount: critical,
      pendingReviewCount: pending,
      isRunning: _aiScannerIsRunning,
    );
  }

  /// AIスキャナーを起動 (定期巡回)
  void startAiScanner({Duration interval = const Duration(seconds: 30)}) {
    if (_aiScannerTimer != null) return;
    _aiScannerIsRunning = true;
    notifyListeners();
    // 起動直後に1回スキャン
    _runAiScan();
    _aiScannerTimer = Timer.periodic(interval, (_) => _runAiScan());
  }

  void stopAiScanner() {
    _aiScannerTimer?.cancel();
    _aiScannerTimer = null;
    _aiScannerIsRunning = false;
    notifyListeners();
  }

  /// 手動でスキャンを実行
  void triggerAiScanNow() {
    _runAiScan();
  }

  void _runAiScan() {
    final random = Random();
    _aiScannerLastRun = DateTime.now();
    // 1スキャンあたり 30-90 件をチェックしたと仮定
    final scanned = 30 + random.nextInt(60);
    _aiScannerScannedToday += scanned;
    // そのうち 0-3 件をフラグ立て
    final flagCount = random.nextInt(4);
    for (var i = 0; i < flagCount; i++) {
      _aiFlags.add(_generateRandomFlag(random));
    }
    notifyListeners();
  }

  /// 管理者がレビュー開始
  void startReviewAiFlag(String flagId) {
    final idx = _aiFlags.indexWhere((f) => f.id == flagId);
    if (idx < 0) return;
    _aiFlags[idx] =
        _aiFlags[idx].copyWith(status: AiFlagReviewStatus.underReview);
    notifyListeners();
  }

  /// 違反確定 → 制限実行
  /// (管理者がトリガーを引く。AIは自動制限しない)
  void confirmAiFlagViolation({
    required String flagId,
    required AiFlagEnforcement enforcement,
    String? reviewerNote,
  }) {
    final idx = _aiFlags.indexWhere((f) => f.id == flagId);
    if (idx < 0) return;
    final flag = _aiFlags[idx];
    _aiFlags[idx] = flag.copyWith(
      status: AiFlagReviewStatus.confirmed,
      appliedEnforcement: enforcement,
      reviewerNote: reviewerNote,
      reviewedAt: DateTime.now(),
    );

    // 実際の制限を実行
    switch (enforcement) {
      case AiFlagEnforcement.suspend:
        suspendUser(flag.targetUserId);
        break;
      case AiFlagEnforcement.none:
      case AiFlagEnforcement.warning:
      case AiFlagEnforcement.contentRemoval:
      case AiFlagEnforcement.feature48hLimit:
      case AiFlagEnforcement.policeReport:
        // 他は記録のみ (実環境ではメッセージ送信や制限フラグ設定)
        break;
    }
    notifyListeners();
  }

  /// 誤検知として却下
  void dismissAiFlagAsFalsePositive(String flagId, {String? note}) {
    final idx = _aiFlags.indexWhere((f) => f.id == flagId);
    if (idx < 0) return;
    _aiFlags[idx] = _aiFlags[idx].copyWith(
      status: AiFlagReviewStatus.falsePositive,
      reviewerNote: note,
      reviewedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // ===== データソース連携 =====

  List<DataSourceIntegration> get dataSources =>
      List.unmodifiable(_dataSources);

  /// 統計: 総取り込み件数
  int get totalImportedRecords =>
      _dataSources.fold(0, (sum, ds) => sum + ds.importedRecords);

  /// 連携状態を変更 (active <-> notConfigured)
  void toggleDataSource(DataSourceProvider provider, bool active) {
    final idx = _dataSources.indexWhere((d) => d.provider == provider);
    if (idx < 0) return;
    _dataSources[idx] = _dataSources[idx].copyWith(
      status:
          active ? DataSourceStatus.active : DataSourceStatus.notConfigured,
      lastSyncAt: active ? DateTime.now() : null,
    );
    notifyListeners();
  }

  /// 即時取り込み (シミュレーション)
  Future<int> runDataSourceSync(DataSourceProvider provider) async {
    final idx = _dataSources.indexWhere((d) => d.provider == provider);
    if (idx < 0) return 0;
    await Future.delayed(const Duration(milliseconds: 800));
    final random = Random();
    // プロバイダー別に妥当な件数
    int delta;
    switch (provider) {
      case DataSourceProvider.lineOfficial:
        delta = 50 + random.nextInt(150);
        break;
      case DataSourceProvider.yahooJapan:
        delta = 30 + random.nextInt(100);
        break;
      case DataSourceProvider.apple:
      case DataSourceProvider.google:
        delta = 20 + random.nextInt(60);
        break;
      case DataSourceProvider.connpass:
      case DataSourceProvider.doorkeeper:
        delta = 10 + random.nextInt(30);
        break;
      case DataSourceProvider.xJapan:
      case DataSourceProvider.facebook:
        delta = 5 + random.nextInt(20);
        break;
      case DataSourceProvider.syntheticSeed:
        delta = 100;
        break;
    }
    final old = _dataSources[idx];
    _dataSources[idx] = old.copyWith(
      status: DataSourceStatus.active,
      importedRecords: old.importedRecords + delta,
      lastSyncAt: DateTime.now(),
    );
    notifyListeners();
    return delta;
  }

  // ===== バルク操作 =====

  void bulkResolveReports(List<String> reportIds, ReportStatus status) {
    for (final id in reportIds) {
      final idx = _reports.indexWhere((r) => r.id == id);
      if (idx >= 0) {
        final r = _reports[idx];
        _reports[idx] = Report(
          id: r.id,
          reporterId: r.reporterId,
          reporterName: r.reporterName,
          targetUserId: r.targetUserId,
          targetUserName: r.targetUserName,
          reason: r.reason,
          description: r.description,
          createdAt: r.createdAt,
          status: status,
        );
      }
    }
    notifyListeners();
  }

  // ===== モックデータ生成 =====

  void _generateMockData() {
    if (_dataGenerated) return;
    _dataGenerated = true;

    final random = Random(2025);
    final firstNames = [
      'Hana', 'Aoi', 'Yuki', 'Rin', 'Mio', 'Sora', 'Nao', 'Ema',
      'Aki', 'Kana', 'Saki', 'Yui', 'Rio', 'Nana', 'Mei', 'Sara',
      'Ren', 'Sho', 'Kai', 'Taku', 'Yuto', 'Hiro', 'Riku', 'Daichi',
      'Tomo', 'Ko', 'Jin', 'Tatsu', 'Naoki', 'Yuma'
    ];
    final prefectures = [
      '東京都', '東京都', '東京都', '東京都', '神奈川県', '神奈川県',
      '埼玉県', '千葉県', '大阪府', '大阪府', '京都府', '兵庫県',
      '愛知県', '福岡県', '北海道'
    ];
    final domains = ['gmail.com', 'icloud.com', 'yahoo.co.jp', 'outlook.jp'];
    final statuses = [
      UserStatus.active, UserStatus.active, UserStatus.active,
      UserStatus.active, UserStatus.active, UserStatus.active,
      UserStatus.active, UserStatus.suspended, UserStatus.pendingVerification,
    ];
    final plans = [
      null, null, null, null,
      PlanType.allCategory, PlanType.allCategory,
      PlanType.singleCategory, PlanType.freeTrial,
    ];

    // 1247人のユーザー生成
    for (int i = 0; i < 1247; i++) {
      final name = firstNames[random.nextInt(firstNames.length)];
      final num = random.nextInt(9999);
      final daysAgo = random.nextInt(365);
      final lastActiveAgo = random.nextInt(30);
      _users.add(AdminUser(
        id: 'usr_${i.toString().padLeft(6, '0')}',
        name: '$name$num',
        email: '$name$num@${domains[random.nextInt(domains.length)]}',
        age: 20 + random.nextInt(25),
        prefecture: prefectures[random.nextInt(prefectures.length)],
        primaryCategory: ConnectionCategory
            .values[random.nextInt(ConnectionCategory.values.length)],
        joinedAt: DateTime.now().subtract(Duration(days: daysAgo)),
        lastActiveAt: DateTime.now().subtract(Duration(days: lastActiveAgo)),
        status: statuses[random.nextInt(statuses.length)],
        matchCount: random.nextInt(50),
        reportCount: random.nextDouble() < 0.05 ? random.nextInt(3) + 1 : 0,
        activePlan: plans[random.nextInt(plans.length)],
        avatarUrl: 'https://i.pravatar.cc/150?u=$i',
      ));
    }

    // 通報レコード（30件）
    final reportReasons = ReportReason.values;
    final reportStatuses = [
      ReportStatus.pending, ReportStatus.pending, ReportStatus.pending,
      ReportStatus.reviewing, ReportStatus.resolved, ReportStatus.dismissed,
    ];
    final descriptions = [
      '不適切な画像が掲載されていました',
      '勧誘のメッセージが繰り返し送られてきました',
      'プロフィール写真が他人の写真です',
      '年齢が実際と異なる可能性があります',
      '会話で侮辱的な言葉を受けました',
      'ビジネス勧誘の誘導があります',
      '連絡先を執拗に要求されました',
      'なりすましの疑いがあります',
    ];
    for (int i = 0; i < 30; i++) {
      final reporter = _users[random.nextInt(_users.length)];
      final target = _users[random.nextInt(_users.length)];
      _reports.add(Report(
        id: 'rpt_${i.toString().padLeft(4, '0')}',
        reporterId: reporter.id,
        reporterName: reporter.name,
        targetUserId: target.id,
        targetUserName: target.name,
        reason: reportReasons[random.nextInt(reportReasons.length)],
        description: descriptions[random.nextInt(descriptions.length)],
        createdAt: DateTime.now().subtract(Duration(hours: random.nextInt(720))),
        status: reportStatuses[random.nextInt(reportStatuses.length)],
      ));
    }
    _reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 売上レコード（過去90日、約500件）
    final txStatuses = [
      TransactionStatus.completed, TransactionStatus.completed,
      TransactionStatus.completed, TransactionStatus.completed,
      TransactionStatus.completed, TransactionStatus.completed,
      TransactionStatus.completed, TransactionStatus.refunded,
      TransactionStatus.failed,
    ];
    final paymentMethods = PaymentMethod.values;
    final plansForRevenue = [
      PlanType.allCategory, PlanType.allCategory, PlanType.allCategory,
      PlanType.singleCategory, PlanType.singleCategory,
      PlanType.boost, PlanType.boost, PlanType.boost, PlanType.boost,
      PlanType.freeTrial,
    ];

    for (int i = 0; i < 500; i++) {
      final user = _users[random.nextInt(_users.length)];
      final plan = plansForRevenue[random.nextInt(plansForRevenue.length)];
      int amount;
      switch (plan) {
        case PlanType.allCategory:
          amount = 4800;
          break;
        case PlanType.singleCategory:
          amount = 1980;
          break;
        case PlanType.boost:
          amount = 500;
          break;
        case PlanType.freeTrial:
          amount = 0;
          break;
      }
      _revenues.add(RevenueRecord(
        id: 'tx_${i.toString().padLeft(6, '0')}',
        date: DateTime.now()
            .subtract(Duration(hours: random.nextInt(90 * 24))),
        userId: user.id,
        userName: user.name,
        planType: plan,
        amountJpy: amount,
        paymentMethod: paymentMethods[random.nextInt(paymentMethods.length)],
        status: txStatuses[random.nextInt(txStatuses.length)],
        selectedCategory: plan == PlanType.singleCategory
            ? ConnectionCategory.values[
                random.nextInt(ConnectionCategory.values.length)]
            : null,
      ));
    }
    _revenues.sort((a, b) => b.date.compareTo(a.date));

    // お知らせ
    _announcements.addAll([
      AdminAnnouncement(
        id: 'ann_001',
        title: '春のキャンペーン開始のお知らせ',
        body: '4月限定で全プラン20%OFFのキャンペーンを実施します。',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        status: AnnouncementStatus.published,
        reachedUsers: 892,
      ),
      AdminAnnouncement(
        id: 'ann_002',
        title: 'メンテナンスのお知らせ',
        body: '4月15日 午前2:00〜4:00 サーバーメンテナンスを実施します。',
        publishedAt: DateTime.now().subtract(const Duration(days: 10)),
        status: AnnouncementStatus.published,
        reachedUsers: 1158,
      ),
    ]);

    // AI フラグの初期データ
    _seedAiFlags(random);

    // データソース連携の初期定義
    _seedDataSources();
  }

  // ===== AI フラグの初期データ生成 =====

  void _seedAiFlags(Random random) {
    final samples = <_FlagSeed>[
      _FlagSeed(
        category: AiFlagCategory.moneyRequest,
        severity: AiFlagSeverity.critical,
        source: AiFlagSource.message,
        content:
            '実は今、生活費が足りなくて困っています。少しだけお金を貸してもらえませんか？すぐに返します。',
        keywords: ['お金を貸して', '生活費が足りなくて'],
        reasoning:
            '金銭の貸借を直接要求している文脈を検出。マッチング直後の早期金銭要求パターン（信頼関係構築前）に該当。詐欺リスクが高い。',
        confidence: 0.94,
      ),
      _FlagSeed(
        category: AiFlagCategory.contactExchange,
        severity: AiFlagSeverity.medium,
        source: AiFlagSource.message,
        content:
            'よかったら LINE 交換しませんか？ID は abc_user_jp1234 です。気軽に連絡ください！',
        keywords: ['LINE 交換', 'abc_user_jp1234'],
        reasoning:
            '外部連絡手段（LINE ID）の直接的な交換誘導を検出。マッチ後 3 メッセージ以内での早期誘導のため、業者・トラブル誘発のリスクあり。',
        confidence: 0.88,
      ),
      _FlagSeed(
        category: AiFlagCategory.selfHarm,
        severity: AiFlagSeverity.critical,
        source: AiFlagSource.profile,
        content:
            'もう疲れました。誰かに会えなかったら本当に終わりにしようと思っています。',
        keywords: ['終わりに', '本当に終わり'],
        reasoning:
            '自傷・自殺念慮を示唆する表現を検出。事件性および本人の安全リスクが極めて高い。即時のケア対応（よりそいホットライン等の案内）と人的判断が必要。',
        confidence: 0.91,
      ),
      _FlagSeed(
        category: AiFlagCategory.impersonation,
        severity: AiFlagSeverity.high,
        source: AiFlagSource.photo,
        content:
            'プロフィール写真3枚のうち2枚が、別アカウント (user_8821) と同一画像 (画像ハッシュ一致)',
        keywords: ['画像ハッシュ一致', 'user_8821'],
        reasoning:
            '他ユーザーのプロフィール画像と完全一致 (perceptual hash 距離 = 0)。なりすましの可能性が高い。本人確認の再実施を推奨。',
        confidence: 0.96,
      ),
      _FlagSeed(
        category: AiFlagCategory.spamCommercial,
        severity: AiFlagSeverity.high,
        source: AiFlagSource.message,
        content:
            '初心者でも月30万円稼げる副業の案内中！LINEで詳細をお伝えします。興味あれば返信ください。',
        keywords: ['月30万円', '副業の案内', '稼げる'],
        reasoning:
            '不労収入を謳う典型的な投資勧誘・MLM 系スパムパターンを検出。同一文面が直近 24h で 8 件発信されており、業者の疑いが極めて強い。',
        confidence: 0.97,
      ),
      _FlagSeed(
        category: AiFlagCategory.harassment,
        severity: AiFlagSeverity.high,
        source: AiFlagSource.message,
        content:
            '返事しないとか何様だよ。お前みたいなのは誰にも相手にされないだろ。',
        keywords: ['何様', '誰にも相手にされない'],
        reasoning:
            '相手を侮辱・威圧する暴言を検出。明確なハラスメントに該当。被害者保護のため警告以上の処置を推奨。',
        confidence: 0.89,
      ),
      _FlagSeed(
        category: AiFlagCategory.minorRisk,
        severity: AiFlagSeverity.critical,
        source: AiFlagSource.profile,
        content:
            'プロフィールで「実は今17歳の高2です♪ 年上の方とお話したいです」と記載されている',
        keywords: ['17歳', '高2'],
        reasoning:
            '登録年齢 (22歳) と自己申告内容に矛盾。本人が未成年と自己申告している記述を検出。即時の本人確認と当該プロフィール非公開化を強く推奨。',
        confidence: 0.93,
      ),
      _FlagSeed(
        category: AiFlagCategory.illegalSubstance,
        severity: AiFlagSeverity.critical,
        source: AiFlagSource.message,
        content:
            '気分上がる白いやつ、安く譲りますよ。クスリ系興味ありませんか？',
        keywords: ['白いやつ', 'クスリ'],
        reasoning:
            '違法薬物の隠語パターン（白いやつ等）と取引示唆を同時に検出。麻薬及び向精神薬取締法の抵触可能性あり。警察相談を検討。',
        confidence: 0.92,
      ),
      _FlagSeed(
        category: AiFlagCategory.sexualContent,
        severity: AiFlagSeverity.medium,
        source: AiFlagSource.message,
        content: '今夜会えませんか？大人な時間を一緒に過ごしましょう。',
        keywords: ['大人な時間', '今夜'],
        reasoning:
            '性的な誘いを含む表現を検出。コンセンサスの確認が取れていない一方的誘発パターン。本人への注意喚起を推奨。',
        confidence: 0.78,
      ),
      _FlagSeed(
        category: AiFlagCategory.hateSpeech,
        severity: AiFlagSeverity.high,
        source: AiFlagSource.profile,
        content:
            '〇〇県民は本当に最低。あんなところの出身者とは絶対関わりたくない。',
        keywords: ['〇〇県民', '最低'],
        reasoning:
            '特定の出身地・属性に対する差別表現を検出。コミュニティガイドライン違反。プロフィール削除と警告を推奨。',
        confidence: 0.85,
      ),
      _FlagSeed(
        category: AiFlagCategory.moneyRequest,
        severity: AiFlagSeverity.high,
        source: AiFlagSource.message,
        content:
            '今度会う前に、入金確認の意味で 5000円だけ振り込んでもらえる？',
        keywords: ['振り込んで', '入金確認'],
        reasoning:
            '会う前の振込要求は典型的な「振り込め系」詐欺パターン。同様パターンの発信履歴あり (3件)。',
        confidence: 0.91,
      ),
      _FlagSeed(
        category: AiFlagCategory.contactExchange,
        severity: AiFlagSeverity.low,
        source: AiFlagSource.username,
        content: '表示名: "サクラ★公式LINEあり💖"',
        keywords: ['公式LINEあり'],
        reasoning:
            '表示名に外部誘導文言（LINE誘導）を含む。マッチング前から外部誘導を意図している可能性。',
        confidence: 0.72,
      ),
    ];

    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      _aiFlagSeq++;
      // 既存ユーザーから target を選ぶ
      final target = _users.isNotEmpty
          ? _users[random.nextInt(_users.length)]
          : null;
      final hoursAgo = random.nextInt(48);
      final minutesAgo = random.nextInt(60);
      _aiFlags.add(AiModerationFlag(
        id: 'AIF-${_aiFlagSeq.toString().padLeft(5, '0')}',
        detectedAt: DateTime.now()
            .subtract(Duration(hours: hoursAgo, minutes: minutesAgo)),
        source: s.source,
        category: s.category,
        severity: s.severity,
        confidence: s.confidence,
        targetUserId: target?.id ?? 'usr_unknown',
        targetUserName: target?.name ?? 'Unknown User',
        targetUserAvatar: target?.avatarUrl ??
            'https://i.pravatar.cc/100?u=$_aiFlagSeq',
        content: s.content,
        matchedKeywords: s.keywords,
        aiReasoning: s.reasoning,
        status: i == 1
            ? AiFlagReviewStatus.underReview
            : (i == 5
                ? AiFlagReviewStatus.confirmed
                : AiFlagReviewStatus.pending),
        appliedEnforcement:
            i == 5 ? AiFlagEnforcement.warning : null,
        reviewedAt: i == 5
            ? DateTime.now().subtract(const Duration(hours: 2))
            : null,
      ));
    }

    // 初期スキャン件数
    _aiScannerScannedToday = 1284;
  }

  /// 巡回で見つかったランダムな新規フラグ
  AiModerationFlag _generateRandomFlag(Random random) {
    final samples = [
      _FlagSeed(
        category: AiFlagCategory.contactExchange,
        severity: AiFlagSeverity.medium,
        source: AiFlagSource.message,
        content: 'こっちのカカオで連絡しませんか？ID教えますね。',
        keywords: ['カカオ', 'ID教え'],
        reasoning: '外部メッセージアプリへの誘導を検出。',
        confidence: 0.81,
      ),
      _FlagSeed(
        category: AiFlagCategory.moneyRequest,
        severity: AiFlagSeverity.high,
        source: AiFlagSource.message,
        content: '稼げる投資の話あるけど興味ある？',
        keywords: ['稼げる投資'],
        reasoning: '投資勧誘の典型パターンを検出。',
        confidence: 0.86,
      ),
      _FlagSeed(
        category: AiFlagCategory.harassment,
        severity: AiFlagSeverity.medium,
        source: AiFlagSource.message,
        content: 'なんで既読無視するの？最悪。',
        keywords: ['既読無視', '最悪'],
        reasoning: '攻撃的な言動を検出。',
        confidence: 0.74,
      ),
      _FlagSeed(
        category: AiFlagCategory.spamCommercial,
        severity: AiFlagSeverity.medium,
        source: AiFlagSource.profile,
        content: 'プロフィール: 副業に興味ある方DMお願いします',
        keywords: ['副業', 'DM'],
        reasoning: '営業目的のプロフィール記載を検出。',
        confidence: 0.79,
      ),
    ];
    final s = samples[random.nextInt(samples.length)];
    _aiFlagSeq++;
    final target = _users.isNotEmpty
        ? _users[random.nextInt(_users.length)]
        : null;
    return AiModerationFlag(
      id: 'AIF-${_aiFlagSeq.toString().padLeft(5, '0')}',
      detectedAt: DateTime.now(),
      source: s.source,
      category: s.category,
      severity: s.severity,
      confidence: s.confidence,
      targetUserId: target?.id ?? 'usr_unknown',
      targetUserName: target?.name ?? 'Unknown',
      targetUserAvatar:
          target?.avatarUrl ?? 'https://i.pravatar.cc/100?u=$_aiFlagSeq',
      content: s.content,
      matchedKeywords: s.keywords,
      aiReasoning: s.reasoning,
      status: AiFlagReviewStatus.pending,
    );
  }

  // ===== データソース連携の初期データ =====

  void _seedDataSources() {
    _dataSources.addAll([
      const DataSourceIntegration(
        provider: DataSourceProvider.lineOfficial,
        status: DataSourceStatus.notConfigured,
        purpose:
            'LINE公式アカウントを開設し、友だち追加経由でTSUNAGUへ誘導。LINEプロフィール（表示名・アイコン）を初期プロフに自動セット。',
        legalNote:
            'LINE公式アカウント利用規約・API規約に準拠。プロフィール情報の取得は本人の同意（OAuth）必須。個人情報保護法（個情法）に基づく利用目的明示が必要。',
        howToSetup:
            'LINE Developers コンソールでチャネル作成 → Messaging APIを有効化 → Webhook URL設定 → LINEログイン用チャネルでOIDCを有効化。',
        importedRecords: 0,
      ),
      const DataSourceIntegration(
        provider: DataSourceProvider.yahooJapan,
        status: DataSourceStatus.notConfigured,
        purpose:
            '国内最大級のID基盤Yahoo! JAPAN IDで認証。日本のユーザーに馴染みのあるログイン手段を提供。',
        legalNote:
            'YConnect（OIDC）ガイドラインに準拠。年齢情報・性別情報の取得には個別同意が必要。',
        howToSetup:
            'Yahoo! デベロッパーネットワークでアプリ登録 → クライアントID/シークレット取得 → リダイレクトURL登録。',
        importedRecords: 0,
      ),
      const DataSourceIntegration(
        provider: DataSourceProvider.apple,
        status: DataSourceStatus.configured,
        purpose:
            'iOSユーザー向け必須認証。App Store審査ガイドライン4.8項により他SNS認証を提供する場合は実装必須。',
        legalNote:
            'Sign in with Apple のブランドガイドラインに準拠。Hide My Email対応が必要。',
        howToSetup:
            'Apple Developer Programに登録 → Service IDを作成 → Domain & Subdomain 登録 → Keyを発行。',
        importedRecords: 0,
      ),
      const DataSourceIntegration(
        provider: DataSourceProvider.google,
        status: DataSourceStatus.configured,
        purpose: 'Androidユーザー向け必須認証。Googleアカウント連携。',
        legalNote:
            'Google API利用規約・ブランドガイドラインに準拠。スコープは email/profile に限定推奨。',
        howToSetup:
            'Google Cloud Consoleでプロジェクト作成 → OAuth 2.0 クライアントID発行 → 承認済みリダイレクトURI設定。',
        importedRecords: 0,
      ),
      const DataSourceIntegration(
        provider: DataSourceProvider.connpass,
        status: DataSourceStatus.notConfigured,
        purpose:
            'IT・ビジネス系イベント情報を「学び」「仕事」「趣味」カテゴリのシードとして表示。イベント参加者向けの「現地マッチング」企画も可能。',
        legalNote:
            'Connpass API利用規約に従う（公開API、商用利用要相談）。取得データの再配布は不可。',
        howToSetup:
            'Connpass APIエンドポイント (https://connpass.com/api/v1/event/) に対しキーワード・地域でクエリ。レート制限 1秒1回。',
        importedRecords: 0,
      ),
      const DataSourceIntegration(
        provider: DataSourceProvider.doorkeeper,
        status: DataSourceStatus.notConfigured,
        purpose:
            '勉強会・コミュニティイベント情報の取り込み。趣味・学びカテゴリの初期コンテンツに。',
        legalNote: 'Doorkeeper Public API利用規約に準拠。',
        howToSetup:
            'Doorkeeperでアカウント登録 → API Tokenを取得 → /api/v1/events エンドポイントから取得。',
        importedRecords: 0,
      ),
      const DataSourceIntegration(
        provider: DataSourceProvider.facebook,
        status: DataSourceStatus.notConfigured,
        purpose:
            'Facebookログイン経由でプロフィール情報初期化。友人グラフから「友達」カテゴリの初期シードに利用可能。',
        legalNote:
            'Meta Platform Terms 準拠。Advanced Access には App Review が必要 (約4-8週間)。',
        howToSetup:
            'Meta for Developers でアプリ作成 → Facebook Login プロダクト追加 → 必要権限申請。',
        importedRecords: 0,
      ),
      const DataSourceIntegration(
        provider: DataSourceProvider.xJapan,
        status: DataSourceStatus.notConfigured,
        purpose:
            'X (旧Twitter)アカウントでログイン。プロフィール、興味タグの初期化。',
        legalNote:
            'X API v2 (Basic/Pro有料プラン)。月間ツイート取得制限あり。商用利用は要審査。',
        howToSetup:
            'Developer Portalで Project + App作成 → OAuth 2.0 設定 → 月額\$100〜のプランが必要。',
        importedRecords: 0,
      ),
      const DataSourceIntegration(
        provider: DataSourceProvider.syntheticSeed,
        status: DataSourceStatus.active,
        purpose:
            'ローンチ前の管理画面検証・社内デモ用に合成ユーザーを生成。本番環境では使用しない。',
        legalNote:
            '生成データは架空のものであり、実在の人物とは無関係である旨を明示する必要あり。',
        howToSetup: '管理画面の「シードデータ生成」ボタンで実行。',
        importedRecords: 1247,
        lastSyncAt: null,
      ),
    ]);
  }
}

/// 内部用: フラグ生成のシード情報
class _FlagSeed {
  final AiFlagCategory category;
  final AiFlagSeverity severity;
  final AiFlagSource source;
  final String content;
  final List<String> keywords;
  final String reasoning;
  final double confidence;
  const _FlagSeed({
    required this.category,
    required this.severity,
    required this.source,
    required this.content,
    required this.keywords,
    required this.reasoning,
    required this.confidence,
  });
}
