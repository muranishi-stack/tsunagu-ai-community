/// プロフィール選択肢の定数 & enum 定義
///
/// 「タップ選択式プロフィール編集」のための選択肢を全てここに集約。
/// AI マッチング判定にも利用されるため、enum 名と Firestore 保存値は固定。
///
/// Phase 1.11 - TSUNAGU
library;

// ═══════════════════════════════════════════════════════════════════════════
// 1. 飲酒
// ═══════════════════════════════════════════════════════════════════════════
enum DrinkingHabit {
  often, // よく飲む
  sometimes, // たまに
  no, // 飲まない
  unspecified;

  String get label {
    switch (this) {
      case DrinkingHabit.often:
        return 'よく飲む';
      case DrinkingHabit.sometimes:
        return 'たまに';
      case DrinkingHabit.no:
        return '飲まない';
      case DrinkingHabit.unspecified:
        return '未設定';
    }
  }

  static DrinkingHabit fromString(String? s) {
    return DrinkingHabit.values.firstWhere(
      (e) => e.name == s,
      orElse: () => DrinkingHabit.unspecified,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. 喫煙
// ═══════════════════════════════════════════════════════════════════════════
enum SmokingHabit {
  yes, // 吸う
  electronic, // 電子タバコ
  no, // 吸わない
  unspecified;

  String get label {
    switch (this) {
      case SmokingHabit.yes:
        return '吸う';
      case SmokingHabit.electronic:
        return '電子タバコ';
      case SmokingHabit.no:
        return '吸わない';
      case SmokingHabit.unspecified:
        return '未設定';
    }
  }

  static SmokingHabit fromString(String? s) {
    return SmokingHabit.values.firstWhere(
      (e) => e.name == s,
      orElse: () => SmokingHabit.unspecified,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. 休日の過ごし方スタイル
// ═══════════════════════════════════════════════════════════════════════════
enum HolidayStyle {
  indoor, // インドア派
  outdoor, // アウトドア派
  both, // 両方
  unspecified;

  String get label {
    switch (this) {
      case HolidayStyle.indoor:
        return 'インドア派';
      case HolidayStyle.outdoor:
        return 'アウトドア派';
      case HolidayStyle.both:
        return '両方';
      case HolidayStyle.unspecified:
        return '未設定';
    }
  }

  static HolidayStyle fromString(String? s) {
    return HolidayStyle.values.firstWhere(
      (e) => e.name == s,
      orElse: () => HolidayStyle.unspecified,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. 休日のアクティビティ（複数選択 / String リストとして保存）
// ═══════════════════════════════════════════════════════════════════════════
class HolidayActivities {
  HolidayActivities._();

  /// すべての選択肢
  static const List<String> all = [
    'カフェ',
    'ジム',
    '旅行',
    '映画',
    '料理',
    '読書',
    'ゲーム',
    'スポーツ観戦',
    'ライブ',
    '美術館',
    'ショッピング',
    'ドライブ',
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. MBTI (16タイプ)
// ═══════════════════════════════════════════════════════════════════════════
class MbtiTypes {
  MbtiTypes._();

  static const List<String> all = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP', // 分析家
    'INFJ', 'INFP', 'ENFJ', 'ENFP', // 外交官
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ', // 番人
    'ISTP', 'ISFP', 'ESTP', 'ESFP', // 探検家
  ];

  static const Map<String, String> labelMap = {
    'INTJ': '建築家',
    'INTP': '論理学者',
    'ENTJ': '指揮官',
    'ENTP': '討論者',
    'INFJ': '提唱者',
    'INFP': '仲介者',
    'ENFJ': '主人公',
    'ENFP': '広報運動家',
    'ISTJ': '管理者',
    'ISFJ': '擁護者',
    'ESTJ': '幹部',
    'ESFJ': '領事官',
    'ISTP': '巨匠',
    'ISFP': '冒険家',
    'ESTP': '起業家',
    'ESFP': 'エンターテイナー',
  };

  static String labelFor(String? type) {
    if (type == null || type.isEmpty) return '未設定';
    return '$type (${labelMap[type] ?? ''})';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. 話せる言語（複数選択）
// ═══════════════════════════════════════════════════════════════════════════
class Languages {
  Languages._();

  static const List<String> all = [
    '日本語',
    '英語',
    '中国語',
    '韓国語',
    'スペイン語',
    'フランス語',
    'ドイツ語',
    'イタリア語',
    'ロシア語',
    'ポルトガル語',
    'タイ語',
    'ベトナム語',
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. 子供の希望
// ═══════════════════════════════════════════════════════════════════════════
enum ChildrenPlan {
  want, // 欲しい
  either, // どちらでも
  notWant, // 欲しくない
  undecided, // 未定
  unspecified;

  String get label {
    switch (this) {
      case ChildrenPlan.want:
        return '欲しい';
      case ChildrenPlan.either:
        return 'どちらでも';
      case ChildrenPlan.notWant:
        return '欲しくない';
      case ChildrenPlan.undecided:
        return '未定';
      case ChildrenPlan.unspecified:
        return '未設定';
    }
  }

  static ChildrenPlan fromString(String? s) {
    return ChildrenPlan.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ChildrenPlan.unspecified,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 8. 結婚観
// ═══════════════════════════════════════════════════════════════════════════
enum MarriageView {
  asap, // すぐにでも
  someday, // いずれは
  notInterested, // 興味なし
  undecided, // 未定
  unspecified;

  String get label {
    switch (this) {
      case MarriageView.asap:
        return 'すぐにでも';
      case MarriageView.someday:
        return 'いずれは';
      case MarriageView.notInterested:
        return '興味なし';
      case MarriageView.undecided:
        return '未定';
      case MarriageView.unspecified:
        return '未設定';
    }
  }

  static MarriageView fromString(String? s) {
    return MarriageView.values.firstWhere(
      (e) => e.name == s,
      orElse: () => MarriageView.unspecified,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 9. 職業カテゴリ
// ═══════════════════════════════════════════════════════════════════════════
class JobCategories {
  JobCategories._();

  static const List<String> all = [
    'IT',
    '金融',
    '医療',
    '教育',
    'サービス業',
    '公務員',
    '経営者',
    'クリエイティブ',
    '営業',
    '製造業',
    '建設業',
    '小売',
    '学生',
    'その他',
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// 10. 学歴
// ═══════════════════════════════════════════════════════════════════════════
enum EducationLevel {
  graduate, // 大学院卒
  university, // 大学卒
  juniorCollege, // 短大・専門卒
  highSchool, // 高卒
  other, // その他
  unspecified;

  String get label {
    switch (this) {
      case EducationLevel.graduate:
        return '大学院卒';
      case EducationLevel.university:
        return '大学卒';
      case EducationLevel.juniorCollege:
        return '短大・専門卒';
      case EducationLevel.highSchool:
        return '高卒';
      case EducationLevel.other:
        return 'その他';
      case EducationLevel.unspecified:
        return '未設定';
    }
  }

  static EducationLevel fromString(String? s) {
    return EducationLevel.values.firstWhere(
      (e) => e.name == s,
      orElse: () => EducationLevel.unspecified,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 11. 身長 (cm) - スライダー用ヘルパー
// ═══════════════════════════════════════════════════════════════════════════
class HeightOptions {
  HeightOptions._();

  static const int min = 140;
  static const int max = 200;
  static const int step = 1;

  /// "165cm" のような表示
  static String labelFor(int? cm) {
    if (cm == null) return '未設定';
    return '${cm}cm';
  }
}
