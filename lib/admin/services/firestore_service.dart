// Firestore data layer for TSUNAGU admin console.
//
// This service handles all reads/writes to Cloud Firestore. AdminService
// delegates to this class so that mock data can be replaced with real data
// progressively without breaking the UI.
//
// Collections:
//   users          - User profiles (synced from app sign-ups + seed data)
//   reports        - User reports
//   transactions   - Revenue / billing records
//   announcements  - Admin announcements
//   ai_flags       - AI moderation flags
//   data_sources   - Data source integration configs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/connection_category.dart';
import '../../models/subscription.dart';
import '../models/admin_models.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  late final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // Collection accessors
  // ============================================================
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _db.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _announcements =>
      _db.collection('announcements');
  CollectionReference<Map<String, dynamic>> get _aiFlags =>
      _db.collection('ai_flags');

  // ============================================================
  // Users
  // ============================================================

  /// Fetch all users from Firestore. Returns empty list if collection
  /// is empty or on error (caller falls back to mock data).
  Future<List<AdminUser>> fetchAllUsers({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _users;
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs
          .map((d) => _adminUserFromFirestore(d.id, d.data()))
          .whereType<AdminUser>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.fetchAllUsers error: $e');
      }
      return [];
    }
  }

  /// Stream-based user list (real-time updates).
  Stream<List<AdminUser>> watchUsers({int limit = 200}) {
    return _users.limit(limit).snapshots().map((snap) {
      return snap.docs
          .map((d) => _adminUserFromFirestore(d.id, d.data()))
          .whereType<AdminUser>()
          .toList();
    });
  }

  Future<void> upsertUser(AdminUser user) async {
    try {
      await _users.doc(user.id).set(_adminUserToFirestore(user));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.upsertUser error: $e');
      }
    }
  }

  Future<void> updateUserStatus(String userId, UserStatus status) async {
    try {
      await _users.doc(userId).update({
        'status': status.name,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.updateUserStatus error: $e');
      }
    }
  }

  // ============================================================
  // Reports
  // ============================================================

  Future<List<Report>> fetchAllReports({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _reports;
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs
          .map((d) => _reportFromFirestore(d.id, d.data()))
          .whereType<Report>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.fetchAllReports error: $e');
      }
      return [];
    }
  }

  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      await _reports.doc(reportId).update({
        'status': status.name,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.updateReportStatus error: $e');
      }
    }
  }

  // ============================================================
  // Transactions / Revenue
  // ============================================================

  Future<List<RevenueRecord>> fetchAllTransactions({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _transactions;
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs
          .map((d) => _transactionFromFirestore(d.id, d.data()))
          .whereType<RevenueRecord>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.fetchAllTransactions error: $e');
      }
      return [];
    }
  }

  // ============================================================
  // Announcements
  // ============================================================

  Future<void> publishAnnouncement(AdminAnnouncement ann) async {
    try {
      await _announcements.doc(ann.id).set({
        'title': ann.title,
        'body': ann.body,
        'published_at': Timestamp.fromDate(ann.publishedAt),
        'status': ann.status.name,
        'reached_users': ann.reachedUsers,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.publishAnnouncement error: $e');
      }
    }
  }

  // ============================================================
  // AI Moderation Flags
  // ============================================================

  Future<List<AiModerationFlag>> fetchAllAiFlags({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _aiFlags;
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs
          .map((d) => _aiFlagFromFirestore(d.id, d.data()))
          .whereType<AiModerationFlag>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.fetchAllAiFlags error: $e');
      }
      return [];
    }
  }

  Future<void> upsertAiFlag(AiModerationFlag flag) async {
    try {
      await _aiFlags.doc(flag.id).set(_aiFlagToFirestore(flag));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.upsertAiFlag error: $e');
      }
    }
  }

  // ============================================================
  // Connection check
  // ============================================================

  /// Ping Firestore by reading a tiny document. Returns true on success.
  Future<bool> isReachable() async {
    try {
      // Just attempt to read 1 doc from 'users'. If permission denied or
      // network error, return false.
      await _users.limit(1).get(const GetOptions(source: Source.server));
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FirestoreService.isReachable error: $e');
      }
      return false;
    }
  }

  // ============================================================
  // Serialization helpers
  // ============================================================

  AdminUser? _adminUserFromFirestore(String docId, Map<String, dynamic> d) {
    try {
      return AdminUser(
        id: docId,
        name: (d['name'] as String?) ?? 'Unknown',
        email: (d['email'] as String?) ?? '',
        age: (d['age'] as num?)?.toInt() ?? 0,
        prefecture: (d['prefecture'] as String?) ?? '',
        primaryCategory: _categoryFromString(d['primary_category'] as String?),
        joinedAt: _dateFrom(d['joined_at']) ?? DateTime.now(),
        lastActiveAt: _dateFrom(d['last_active_at']) ?? DateTime.now(),
        status: _userStatusFromString(d['status'] as String?),
        matchCount: (d['match_count'] as num?)?.toInt() ?? 0,
        reportCount: (d['report_count'] as num?)?.toInt() ?? 0,
        activePlan: _planTypeFromString(d['active_plan'] as String?),
        avatarUrl: (d['avatar_url'] as String?) ?? '',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to parse user $docId: $e');
      }
      return null;
    }
  }

  Map<String, dynamic> _adminUserToFirestore(AdminUser u) {
    return {
      'name': u.name,
      'email': u.email,
      'age': u.age,
      'prefecture': u.prefecture,
      'primary_category': u.primaryCategory.name,
      'joined_at': Timestamp.fromDate(u.joinedAt),
      'last_active_at': Timestamp.fromDate(u.lastActiveAt),
      'status': u.status.name,
      'match_count': u.matchCount,
      'report_count': u.reportCount,
      'active_plan': u.activePlan?.name,
      'avatar_url': u.avatarUrl,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Report? _reportFromFirestore(String docId, Map<String, dynamic> d) {
    try {
      return Report(
        id: docId,
        reporterId: (d['reporter_id'] as String?) ?? '',
        reporterName: (d['reporter_name'] as String?) ?? '',
        targetUserId: (d['target_user_id'] as String?) ?? '',
        targetUserName: (d['target_user_name'] as String?) ?? '',
        reason: _reportReasonFromString(d['reason'] as String?),
        description: (d['description'] as String?) ?? '',
        createdAt: _dateFrom(d['created_at']) ?? DateTime.now(),
        status: _reportStatusFromString(d['status'] as String?),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to parse report $docId: $e');
      }
      return null;
    }
  }

  RevenueRecord? _transactionFromFirestore(
      String docId, Map<String, dynamic> d) {
    try {
      return RevenueRecord(
        id: docId,
        date: _dateFrom(d['date']) ?? DateTime.now(),
        userId: (d['user_id'] as String?) ?? '',
        userName: (d['user_name'] as String?) ?? '',
        planType: _planTypeFromString(d['plan_type'] as String?) ??
            PlanType.allCategory,
        amountJpy: (d['amount_jpy'] as num?)?.toInt() ?? 0,
        paymentMethod:
            _paymentMethodFromString(d['payment_method'] as String?),
        status: _transactionStatusFromString(d['status'] as String?),
        selectedCategory:
            _categoryFromStringNullable(d['selected_category'] as String?),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to parse transaction $docId: $e');
      }
      return null;
    }
  }

  AiModerationFlag? _aiFlagFromFirestore(
      String docId, Map<String, dynamic> d) {
    try {
      return AiModerationFlag(
        id: docId,
        detectedAt: _dateFrom(d['detected_at']) ?? DateTime.now(),
        source: _aiSourceFromString(d['source'] as String?),
        category: _aiCategoryFromString(d['category'] as String?),
        severity: _aiSeverityFromString(d['severity'] as String?),
        confidence: (d['confidence'] as num?)?.toDouble() ?? 0.0,
        targetUserId: (d['target_user_id'] as String?) ?? '',
        targetUserName: (d['target_user_name'] as String?) ?? '',
        targetUserAvatar: (d['target_user_avatar'] as String?) ?? '',
        content: (d['content'] as String?) ?? '',
        matchedKeywords:
            (d['matched_keywords'] as List?)?.cast<String>() ?? const [],
        aiReasoning: (d['ai_reasoning'] as String?) ?? '',
        status: _aiStatusFromString(d['status'] as String?),
        appliedEnforcement:
            _aiEnforcementFromString(d['applied_enforcement'] as String?),
        reviewerNote: d['reviewer_note'] as String?,
        reviewedAt: _dateFrom(d['reviewed_at']),
        relatedReportId: d['related_report_id'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to parse AI flag $docId: $e');
      }
      return null;
    }
  }

  Map<String, dynamic> _aiFlagToFirestore(AiModerationFlag f) {
    return {
      'detected_at': Timestamp.fromDate(f.detectedAt),
      'source': f.source.name,
      'category': f.category.name,
      'severity': f.severity.name,
      'confidence': f.confidence,
      'target_user_id': f.targetUserId,
      'target_user_name': f.targetUserName,
      'target_user_avatar': f.targetUserAvatar,
      'content': f.content,
      'matched_keywords': f.matchedKeywords,
      'ai_reasoning': f.aiReasoning,
      'status': f.status.name,
      'applied_enforcement': f.appliedEnforcement?.name,
      'reviewer_note': f.reviewerNote,
      'reviewed_at':
          f.reviewedAt != null ? Timestamp.fromDate(f.reviewedAt!) : null,
      'related_report_id': f.relatedReportId,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // -- enum parsing helpers --

  DateTime? _dateFrom(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  ConnectionCategory _categoryFromString(String? s) {
    return ConnectionCategory.values.firstWhere(
      (c) => c.name == s,
      orElse: () => ConnectionCategory.friend,
    );
  }

  ConnectionCategory? _categoryFromStringNullable(String? s) {
    if (s == null) return null;
    try {
      return ConnectionCategory.values.firstWhere((c) => c.name == s);
    } catch (_) {
      return null;
    }
  }

  UserStatus _userStatusFromString(String? s) {
    return UserStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => UserStatus.active,
    );
  }

  PlanType? _planTypeFromString(String? s) {
    if (s == null) return null;
    try {
      return PlanType.values.firstWhere((e) => e.name == s);
    } catch (_) {
      return null;
    }
  }

  ReportReason _reportReasonFromString(String? s) {
    return ReportReason.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ReportReason.other,
    );
  }

  ReportStatus _reportStatusFromString(String? s) {
    return ReportStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ReportStatus.pending,
    );
  }

  PaymentMethod _paymentMethodFromString(String? s) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == s,
      orElse: () => PaymentMethod.applePay,
    );
  }

  TransactionStatus _transactionStatusFromString(String? s) {
    return TransactionStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => TransactionStatus.completed,
    );
  }

  AiFlagSource _aiSourceFromString(String? s) {
    return AiFlagSource.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AiFlagSource.message,
    );
  }

  AiFlagCategory _aiCategoryFromString(String? s) {
    return AiFlagCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AiFlagCategory.spamCommercial,
    );
  }

  AiFlagSeverity _aiSeverityFromString(String? s) {
    return AiFlagSeverity.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AiFlagSeverity.medium,
    );
  }

  AiFlagReviewStatus _aiStatusFromString(String? s) {
    return AiFlagReviewStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AiFlagReviewStatus.pending,
    );
  }

  AiFlagEnforcement? _aiEnforcementFromString(String? s) {
    if (s == null) return null;
    try {
      return AiFlagEnforcement.values.firstWhere((e) => e.name == s);
    } catch (_) {
      return null;
    }
  }
}
