import 'package:cloud_firestore/cloud_firestore.dart';
import 'connection_category.dart';

/// 性別
enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  String get label {
    switch (this) {
      case Gender.male:
        return '男性';
      case Gender.female:
        return '女性';
      case Gender.other:
        return 'その他';
      case Gender.preferNotToSay:
        return '回答しない';
    }
  }

  static Gender fromString(String? s) {
    return Gender.values.firstWhere(
      (g) => g.name == s,
      orElse: () => Gender.preferNotToSay,
    );
  }
}

class UserProfile {
  // ============ 必須項目 ============
  /// Firebase Auth の UID（または既存のシード ID）
  final String id;

  /// ニックネーム（3-20 文字、絵文字 NG）
  final String name;

  /// 生年月日から計算される年齢
  final int age;

  /// 生年月日（DOB から年齢を算出）
  final DateTime? dateOfBirth;

  /// 都道府県（GPS から自動取得 or 手動選択）
  final String prefecture;

  /// 性別
  final Gender gender;

  // ============ 任意項目 ============
  /// 大まかな地域（例: 渋谷、新宿）
  final String location;

  /// 職業
  final String occupation;

  /// 自己紹介
  final String bio;

  /// 趣味・興味
  final List<String> interests;

  /// プロフィール写真（最低 1 枚、最大 6 枚）
  final List<String> photos;

  /// AI マッチスコア（クライアント側で計算）
  final int aiMatchScore;

  /// AI 洞察コメント
  final String aiInsight;

  /// 学歴
  final String education;

  /// 身長
  final String height;

  /// 対応可能なコネクションカテゴリ
  final List<ConnectionCategory> openTo;

  /// メインカテゴリ
  final ConnectionCategory primaryCategory;

  /// 主要沿線（任意）
  final String? trainLine;

  // ============ システム項目 ============
  /// シードデータフラグ（true = 開発用ダミー）
  final bool isSeedData;

  /// メールアドレス
  final String email;

  /// 作成日時
  final DateTime? createdAt;

  /// 最終更新日時
  final DateTime? updatedAt;

  /// 最終アクティブ日時
  final DateTime? lastActiveAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    this.dateOfBirth,
    required this.prefecture,
    this.gender = Gender.preferNotToSay,
    this.location = '',
    this.occupation = '',
    this.bio = '',
    this.interests = const [],
    required this.photos,
    this.aiMatchScore = 80,
    this.aiInsight = '',
    this.education = '',
    this.height = '',
    this.openTo = const [],
    required this.primaryCategory,
    this.trainLine,
    this.isSeedData = false,
    this.email = '',
    this.createdAt,
    this.updatedAt,
    this.lastActiveAt,
  });

  /// 生年月日から年齢計算
  static int calculateAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Firestore document → UserProfile
  factory UserProfile.fromFirestore(String docId, Map<String, dynamic> data) {
    final dobTimestamp = data['date_of_birth'];
    DateTime? dob;
    if (dobTimestamp is Timestamp) {
      dob = dobTimestamp.toDate();
    } else if (dobTimestamp is String) {
      dob = DateTime.tryParse(dobTimestamp);
    }

    int age = (data['age'] as num?)?.toInt() ?? 0;
    if (dob != null && age == 0) {
      age = calculateAge(dob);
    }

    final photosRaw = data['photos'];
    final photos = (photosRaw is List)
        ? photosRaw.map((p) => p.toString()).toList()
        : <String>[];

    final interestsRaw = data['interests'];
    final interests = (interestsRaw is List)
        ? interestsRaw.map((i) => i.toString()).toList()
        : <String>[];

    final openToRaw = data['open_to'];
    final openTo = (openToRaw is List)
        ? openToRaw
            .map((c) => ConnectionCategory.values.firstWhere(
                  (cat) => cat.name == c.toString(),
                  orElse: () => ConnectionCategory.friend,
                ))
            .toList()
        : <ConnectionCategory>[];

    final primaryCat = ConnectionCategory.values.firstWhere(
      (c) => c.name == data['primary_category'],
      orElse: () => ConnectionCategory.friend,
    );

    DateTime? toDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return UserProfile(
      id: docId,
      name: (data['name'] as String?) ?? 'No Name',
      age: age,
      dateOfBirth: dob,
      prefecture: (data['prefecture'] as String?) ?? '',
      gender: Gender.fromString(data['gender'] as String?),
      location: (data['location'] as String?) ?? '',
      occupation: (data['occupation'] as String?) ?? '',
      bio: (data['bio'] as String?) ?? '',
      interests: interests,
      photos: photos,
      aiMatchScore: (data['ai_match_score'] as num?)?.toInt() ?? 80,
      aiInsight: (data['ai_insight'] as String?) ?? '',
      education: (data['education'] as String?) ?? '',
      height: (data['height'] as String?) ?? '',
      openTo: openTo,
      primaryCategory: primaryCat,
      trainLine: data['train_line'] as String?,
      isSeedData: (data['is_seed_data'] as bool?) ?? false,
      email: (data['email'] as String?) ?? '',
      createdAt: toDt(data['created_at']),
      updatedAt: toDt(data['updated_at']),
      lastActiveAt: toDt(data['last_active_at']),
    );
  }

  /// UserProfile → Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      if (dateOfBirth != null) 'date_of_birth': Timestamp.fromDate(dateOfBirth!),
      'prefecture': prefecture,
      'gender': gender.name,
      'location': location,
      'occupation': occupation,
      'bio': bio,
      'interests': interests,
      'photos': photos,
      'ai_match_score': aiMatchScore,
      'ai_insight': aiInsight,
      'education': education,
      'height': height,
      'open_to': openTo.map((c) => c.name).toList(),
      'primary_category': primaryCategory.name,
      if (trainLine != null) 'train_line': trainLine,
      'is_seed_data': isSeedData,
      'email': email,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!)
      else
        'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'last_active_at': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    DateTime? dateOfBirth,
    String? prefecture,
    Gender? gender,
    String? location,
    String? occupation,
    String? bio,
    List<String>? interests,
    List<String>? photos,
    int? aiMatchScore,
    String? aiInsight,
    String? education,
    String? height,
    List<ConnectionCategory>? openTo,
    ConnectionCategory? primaryCategory,
    String? trainLine,
    bool? isSeedData,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      prefecture: prefecture ?? this.prefecture,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      occupation: occupation ?? this.occupation,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      photos: photos ?? this.photos,
      aiMatchScore: aiMatchScore ?? this.aiMatchScore,
      aiInsight: aiInsight ?? this.aiInsight,
      education: education ?? this.education,
      height: height ?? this.height,
      openTo: openTo ?? this.openTo,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      trainLine: trainLine ?? this.trainLine,
      isSeedData: isSeedData ?? this.isSeedData,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

class Match {
  final UserProfile user;
  final DateTime matchedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool hasUnread;
  final String matchId;

  Match({
    required this.user,
    required this.matchedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.hasUnread = false,
    this.matchId = '',
  });
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  factory Message.fromFirestore(
    String docId,
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    DateTime? ts;
    final raw = data['timestamp'];
    if (raw is Timestamp) ts = raw.toDate();
    if (raw is DateTime) ts = raw;
    return Message(
      id: docId,
      senderId: (data['sender_id'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      timestamp: ts ?? DateTime.now(),
      isMe: data['sender_id'] == currentUserId,
    );
  }
}
