import '../../models/connection_category.dart';
import '../../models/subscription.dart';

/// 管理画面に表示するユーザーレコード
class AdminUser {
  final String id;
  final String name;
  final String email;
  final int age;
  final String prefecture;
  final ConnectionCategory primaryCategory;
  final DateTime joinedAt;
  final DateTime lastActiveAt;
  final UserStatus status;
  final int matchCount;
  final int reportCount;
  final PlanType? activePlan;
  final String avatarUrl;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    required this.prefecture,
    required this.primaryCategory,
    required this.joinedAt,
    required this.lastActiveAt,
    required this.status,
    required this.matchCount,
    required this.reportCount,
    this.activePlan,
    required this.avatarUrl,
  });
}

enum UserStatus { active, suspended, deleted, pendingVerification }

extension UserStatusX on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.active:
        return 'ACTIVE';
      case UserStatus.suspended:
        return 'SUSPENDED';
      case UserStatus.deleted:
        return 'DELETED';
      case UserStatus.pendingVerification:
        return 'PENDING';
    }
  }

  String get labelJa {
    switch (this) {
      case UserStatus.active:
        return 'アクティブ';
      case UserStatus.suspended:
        return '凍結';
      case UserStatus.deleted:
        return '削除済';
      case UserStatus.pendingVerification:
        return '認証待ち';
    }
  }
}

/// 通報レコード
class Report {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetUserId;
  final String targetUserName;
  final ReportReason reason;
  final String description;
  final DateTime createdAt;
  final ReportStatus status;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetUserId,
    required this.targetUserName,
    required this.reason,
    required this.description,
    required this.createdAt,
    required this.status,
  });
}

enum ReportReason {
  inappropriate,
  spam,
  harassment,
  fake,
  underage,
  other,
}

extension ReportReasonX on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.inappropriate:
        return '不適切なコンテンツ';
      case ReportReason.spam:
        return 'スパム/勧誘';
      case ReportReason.harassment:
        return 'ハラスメント';
      case ReportReason.fake:
        return 'なりすまし';
      case ReportReason.underage:
        return '年齢詐称の疑い';
      case ReportReason.other:
        return 'その他';
    }
  }
}

enum ReportStatus { pending, reviewing, resolved, dismissed }

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.pending:
        return '未対応';
      case ReportStatus.reviewing:
        return '確認中';
      case ReportStatus.resolved:
        return '対応済';
      case ReportStatus.dismissed:
        return '却下';
    }
  }
}

/// 売上レコード
class RevenueRecord {
  final String id;
  final DateTime date;
  final String userId;
  final String userName;
  final PlanType planType;
  final int amountJpy;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final ConnectionCategory? selectedCategory;

  const RevenueRecord({
    required this.id,
    required this.date,
    required this.userId,
    required this.userName,
    required this.planType,
    required this.amountJpy,
    required this.paymentMethod,
    required this.status,
    this.selectedCategory,
  });
}

enum TransactionStatus { completed, refunded, failed, pending }

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.completed:
        return '完了';
      case TransactionStatus.refunded:
        return '返金済';
      case TransactionStatus.failed:
        return '失敗';
      case TransactionStatus.pending:
        return '保留中';
    }
  }
}

/// ダッシュボード用KPI
class DashboardKPI {
  final int totalUsers;
  final int activeUsersMau;
  final int activeUsersDau;
  final int newUsersToday;
  final int monthlyRecurringRevenue;
  final int totalRevenue30d;
  final double churnRate;        // %
  final int totalMatches30d;
  final int activeSubscriptions;
  final int activeBoosts;
  final double conversionRate;   // 無料→有料 %
  final int pendingReports;

  const DashboardKPI({
    required this.totalUsers,
    required this.activeUsersMau,
    required this.activeUsersDau,
    required this.newUsersToday,
    required this.monthlyRecurringRevenue,
    required this.totalRevenue30d,
    required this.churnRate,
    required this.totalMatches30d,
    required this.activeSubscriptions,
    required this.activeBoosts,
    required this.conversionRate,
    required this.pendingReports,
  });
}

/// 時系列データポイント（折れ線グラフ用）
class TimeSeriesPoint {
  final DateTime date;
  final double value;
  const TimeSeriesPoint({required this.date, required this.value});
}

/// プラン別売上集計
class PlanRevenueBreakdown {
  final PlanType planType;
  final int count;
  final int totalRevenue;
  const PlanRevenueBreakdown({
    required this.planType,
    required this.count,
    required this.totalRevenue,
  });
}

/// カテゴリ別ユーザー分布
class CategoryDistribution {
  final ConnectionCategory category;
  final int userCount;
  final double percentage;
  const CategoryDistribution({
    required this.category,
    required this.userCount,
    required this.percentage,
  });
}

/// 都道府県別ユーザー分布
class PrefectureDistribution {
  final String prefecture;
  final int userCount;
  const PrefectureDistribution({
    required this.prefecture,
    required this.userCount,
  });
}

/// お知らせ通知
class AdminAnnouncement {
  final String id;
  final String title;
  final String body;
  final DateTime publishedAt;
  final AnnouncementStatus status;
  final int reachedUsers;

  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    required this.status,
    required this.reachedUsers,
  });
}

enum AnnouncementStatus { draft, scheduled, published }

extension AnnouncementStatusX on AnnouncementStatus {
  String get label {
    switch (this) {
      case AnnouncementStatus.draft:
        return '下書き';
      case AnnouncementStatus.scheduled:
        return '配信予約';
      case AnnouncementStatus.published:
        return '配信済';
    }
  }
}

/// 管理者アカウント
class AdminAccount {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final DateTime lastLoginAt;

  const AdminAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.lastLoginAt,
  });
}

enum AdminRole { superAdmin, moderator, support, viewer }

extension AdminRoleX on AdminRole {
  String get label {
    switch (this) {
      case AdminRole.superAdmin:
        return 'SUPER ADMIN';
      case AdminRole.moderator:
        return 'MODERATOR';
      case AdminRole.support:
        return 'SUPPORT';
      case AdminRole.viewer:
        return 'VIEWER';
    }
  }
}

/// リアルタイムアクティビティフィード用のイベント
enum ActivityType { userSignup, subscription, boostPurchase, report, match }

class ActivityEvent {
  final ActivityType type;
  final DateTime timestamp;
  final String title;
  final String description;
  final String userId;
  final String userName;

  const ActivityEvent({
    required this.type,
    required this.timestamp,
    required this.title,
    required this.description,
    required this.userId,
    required this.userName,
  });
}

// ============================================================================
// AI モデレーション
// ============================================================================

/// 検出ソース (どこから検出されたか)
enum AiFlagSource {
  message, // チャットメッセージ
  profile, // プロフィール文章
  photo, // 写真メタデータ
  username, // 表示名
}

extension AiFlagSourceX on AiFlagSource {
  String get label {
    switch (this) {
      case AiFlagSource.message:
        return 'メッセージ';
      case AiFlagSource.profile:
        return 'プロフィール';
      case AiFlagSource.photo:
        return '写真';
      case AiFlagSource.username:
        return '表示名';
    }
  }

  String get englishLabel {
    switch (this) {
      case AiFlagSource.message:
        return 'MESSAGE';
      case AiFlagSource.profile:
        return 'PROFILE';
      case AiFlagSource.photo:
        return 'PHOTO';
      case AiFlagSource.username:
        return 'USERNAME';
    }
  }
}

/// 違反カテゴリ
enum AiFlagCategory {
  impersonation, // なりすまし
  moneyRequest, // 金銭要求・詐欺
  contactExchange, // 連絡先交換誘導
  harassment, // ハラスメント・誹謗中傷
  minorRisk, // 未成年関連リスク
  illegalSubstance, // 違法薬物・暴力
  spamCommercial, // 業者・スパム
  selfHarm, // 自殺・自傷リスク
  sexualContent, // 性的コンテンツ
  hateSpeech, // ヘイトスピーチ
}

extension AiFlagCategoryX on AiFlagCategory {
  String get label {
    switch (this) {
      case AiFlagCategory.impersonation:
        return 'なりすまし';
      case AiFlagCategory.moneyRequest:
        return '金銭要求・詐欺';
      case AiFlagCategory.contactExchange:
        return '連絡先交換誘導';
      case AiFlagCategory.harassment:
        return 'ハラスメント';
      case AiFlagCategory.minorRisk:
        return '未成年関連リスク';
      case AiFlagCategory.illegalSubstance:
        return '違法薬物・暴力';
      case AiFlagCategory.spamCommercial:
        return '業者・スパム';
      case AiFlagCategory.selfHarm:
        return '自殺・自傷リスク';
      case AiFlagCategory.sexualContent:
        return '性的コンテンツ';
      case AiFlagCategory.hateSpeech:
        return 'ヘイトスピーチ';
    }
  }

  String get code {
    switch (this) {
      case AiFlagCategory.impersonation:
        return 'IMPERSONATION';
      case AiFlagCategory.moneyRequest:
        return 'MONEY_REQUEST';
      case AiFlagCategory.contactExchange:
        return 'CONTACT_EXCHANGE';
      case AiFlagCategory.harassment:
        return 'HARASSMENT';
      case AiFlagCategory.minorRisk:
        return 'MINOR_RISK';
      case AiFlagCategory.illegalSubstance:
        return 'ILLEGAL_SUBSTANCE';
      case AiFlagCategory.spamCommercial:
        return 'SPAM_COMMERCIAL';
      case AiFlagCategory.selfHarm:
        return 'SELF_HARM';
      case AiFlagCategory.sexualContent:
        return 'SEXUAL_CONTENT';
      case AiFlagCategory.hateSpeech:
        return 'HATE_SPEECH';
    }
  }
}

/// 重大度 (CRITICAL は事件性の高いもの)
enum AiFlagSeverity {
  critical, // 即時対応必須 (事件性)
  high, // 重大違反
  medium, // 注意
  low, // 軽微
}

extension AiFlagSeverityX on AiFlagSeverity {
  String get label {
    switch (this) {
      case AiFlagSeverity.critical:
        return 'CRITICAL';
      case AiFlagSeverity.high:
        return 'HIGH';
      case AiFlagSeverity.medium:
        return 'MEDIUM';
      case AiFlagSeverity.low:
        return 'LOW';
    }
  }

  String get labelJa {
    switch (this) {
      case AiFlagSeverity.critical:
        return '緊急 (事件性)';
      case AiFlagSeverity.high:
        return '重大';
      case AiFlagSeverity.medium:
        return '中程度';
      case AiFlagSeverity.low:
        return '軽微';
    }
  }
}

/// 管理者対応ステータス
enum AiFlagReviewStatus {
  pending, // 未対応 (AIが検出したばかり)
  underReview, // 管理者がレビュー中
  confirmed, // 違反確定 (制限実行済)
  falsePositive, // 誤検知として却下
}

extension AiFlagReviewStatusX on AiFlagReviewStatus {
  String get label {
    switch (this) {
      case AiFlagReviewStatus.pending:
        return 'PENDING';
      case AiFlagReviewStatus.underReview:
        return 'REVIEWING';
      case AiFlagReviewStatus.confirmed:
        return 'CONFIRMED';
      case AiFlagReviewStatus.falsePositive:
        return 'FALSE POSITIVE';
    }
  }

  String get labelJa {
    switch (this) {
      case AiFlagReviewStatus.pending:
        return '未確認';
      case AiFlagReviewStatus.underReview:
        return 'レビュー中';
      case AiFlagReviewStatus.confirmed:
        return '違反確定';
      case AiFlagReviewStatus.falsePositive:
        return '誤検知';
    }
  }
}

/// 管理者が選択できる制限アクション
enum AiFlagEnforcement {
  none, // 制限なし
  warning, // 警告通知
  contentRemoval, // 当該コンテンツ削除
  feature48hLimit, // 48時間機能制限
  suspend, // アカウント凍結
  policeReport, // 警察相談 (CRITICAL用)
}

extension AiFlagEnforcementX on AiFlagEnforcement {
  String get label {
    switch (this) {
      case AiFlagEnforcement.none:
        return '制限なし';
      case AiFlagEnforcement.warning:
        return '警告通知を送信';
      case AiFlagEnforcement.contentRemoval:
        return 'コンテンツ削除';
      case AiFlagEnforcement.feature48hLimit:
        return '48時間機能制限';
      case AiFlagEnforcement.suspend:
        return 'アカウント凍結';
      case AiFlagEnforcement.policeReport:
        return '警察相談・通報';
    }
  }
}

/// AIが検出したフラグ
class AiModerationFlag {
  final String id;
  final DateTime detectedAt;
  final AiFlagSource source;
  final AiFlagCategory category;
  final AiFlagSeverity severity;
  final double confidence; // 0.0 ~ 1.0
  final String targetUserId;
  final String targetUserName;
  final String targetUserAvatar;
  final String content; // 検出された対象テキスト/メタ情報
  final List<String> matchedKeywords; // ハイライト対象
  final String aiReasoning; // AIの判定理由
  final AiFlagReviewStatus status;
  final AiFlagEnforcement? appliedEnforcement;
  final String? reviewerNote;
  final DateTime? reviewedAt;
  final String? relatedReportId; // 既存通報との紐付け

  const AiModerationFlag({
    required this.id,
    required this.detectedAt,
    required this.source,
    required this.category,
    required this.severity,
    required this.confidence,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserAvatar,
    required this.content,
    required this.matchedKeywords,
    required this.aiReasoning,
    required this.status,
    this.appliedEnforcement,
    this.reviewerNote,
    this.reviewedAt,
    this.relatedReportId,
  });

  AiModerationFlag copyWith({
    AiFlagReviewStatus? status,
    AiFlagEnforcement? appliedEnforcement,
    String? reviewerNote,
    DateTime? reviewedAt,
  }) {
    return AiModerationFlag(
      id: id,
      detectedAt: detectedAt,
      source: source,
      category: category,
      severity: severity,
      confidence: confidence,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserAvatar: targetUserAvatar,
      content: content,
      matchedKeywords: matchedKeywords,
      aiReasoning: aiReasoning,
      status: status ?? this.status,
      appliedEnforcement: appliedEnforcement ?? this.appliedEnforcement,
      reviewerNote: reviewerNote ?? this.reviewerNote,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      relatedReportId: relatedReportId,
    );
  }
}

/// AIスキャナーの統計
class AiScannerStats {
  final DateTime lastRunAt;
  final int totalScannedToday;
  final int totalFlaggedToday;
  final int criticalCount;
  final int pendingReviewCount;
  final bool isRunning;

  const AiScannerStats({
    required this.lastRunAt,
    required this.totalScannedToday,
    required this.totalFlaggedToday,
    required this.criticalCount,
    required this.pendingReviewCount,
    required this.isRunning,
  });
}

// ============================================================================
// データソース連携
// ============================================================================

enum DataSourceProvider {
  lineOfficial, // LINE 公式アカウント
  yahooJapan, // Yahoo! JAPAN ID
  apple, // Apple ID
  google, // Google サインイン
  connpass, // Connpass (イベント)
  doorkeeper, // Doorkeeper (イベント)
  xJapan, // X (旧Twitter)
  facebook, // Facebook
  syntheticSeed, // シードデータ生成 (内部)
}

extension DataSourceProviderX on DataSourceProvider {
  String get displayName {
    switch (this) {
      case DataSourceProvider.lineOfficial:
        return 'LINE 公式アカウント';
      case DataSourceProvider.yahooJapan:
        return 'Yahoo! JAPAN ID';
      case DataSourceProvider.apple:
        return 'Apple ID';
      case DataSourceProvider.google:
        return 'Google サインイン';
      case DataSourceProvider.connpass:
        return 'Connpass';
      case DataSourceProvider.doorkeeper:
        return 'Doorkeeper';
      case DataSourceProvider.xJapan:
        return 'X (旧Twitter)';
      case DataSourceProvider.facebook:
        return 'Facebook';
      case DataSourceProvider.syntheticSeed:
        return 'シードデータ生成';
    }
  }

  String get category {
    switch (this) {
      case DataSourceProvider.apple:
      case DataSourceProvider.google:
      case DataSourceProvider.yahooJapan:
      case DataSourceProvider.lineOfficial:
        return '認証・ID';
      case DataSourceProvider.connpass:
      case DataSourceProvider.doorkeeper:
        return 'イベント・シード';
      case DataSourceProvider.xJapan:
      case DataSourceProvider.facebook:
        return 'ソーシャル';
      case DataSourceProvider.syntheticSeed:
        return '内部ツール';
    }
  }

  /// 推奨度: 0=非推奨 ～ 3=最重要
  int get recommendationLevel {
    switch (this) {
      case DataSourceProvider.lineOfficial:
        return 3;
      case DataSourceProvider.apple:
      case DataSourceProvider.google:
        return 3;
      case DataSourceProvider.yahooJapan:
        return 3;
      case DataSourceProvider.connpass:
        return 2;
      case DataSourceProvider.doorkeeper:
        return 2;
      case DataSourceProvider.facebook:
        return 1;
      case DataSourceProvider.xJapan:
        return 1;
      case DataSourceProvider.syntheticSeed:
        return 2;
    }
  }
}

enum DataSourceStatus {
  active, // 連携中
  configured, // 設定済 (未起動)
  notConfigured, // 未設定
  error, // エラー
}

extension DataSourceStatusX on DataSourceStatus {
  String get label {
    switch (this) {
      case DataSourceStatus.active:
        return 'ACTIVE';
      case DataSourceStatus.configured:
        return 'CONFIGURED';
      case DataSourceStatus.notConfigured:
        return 'NOT SET';
      case DataSourceStatus.error:
        return 'ERROR';
    }
  }
}

class DataSourceIntegration {
  final DataSourceProvider provider;
  final DataSourceStatus status;
  final String purpose; // このサービスを使う目的
  final String legalNote; // 法的・規約上の注意点
  final String howToSetup; // 設定方法の概要
  final int importedRecords; // 取り込み済レコード数
  final DateTime? lastSyncAt;

  const DataSourceIntegration({
    required this.provider,
    required this.status,
    required this.purpose,
    required this.legalNote,
    required this.howToSetup,
    required this.importedRecords,
    this.lastSyncAt,
  });

  DataSourceIntegration copyWith({
    DataSourceStatus? status,
    int? importedRecords,
    DateTime? lastSyncAt,
  }) {
    return DataSourceIntegration(
      provider: provider,
      status: status ?? this.status,
      purpose: purpose,
      legalNote: legalNote,
      howToSetup: howToSetup,
      importedRecords: importedRecords ?? this.importedRecords,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}
