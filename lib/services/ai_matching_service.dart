import '../models/connection_category.dart';
import '../models/user_profile.dart';

/// AIマッチングスコアリングサービス
///
/// カテゴリ別の重み付けで相性スコアを再計算する。
/// - 恋愛: 年齢・地域・趣味の共通性を重視
/// - 仕事: 職業/学歴/興味の重なりを重視
/// - 学び: 興味分野の重なりを最重視
/// - 趣味: 興味の重なりを最重視
/// - 友達: バランス型
class AIMatchingService {
  /// 自分のプロフィール（仮想）を基準に、相手のスコアを返す（0〜100）
  static int calculateScore({
    required UserProfile other,
    required ConnectionCategory desiredCategory,
    required MyProfile self,
  }) {
    // 1. カテゴリ親和性（30点満点）
    final categoryScore = _categoryAffinity(other, desiredCategory);

    // 2. 興味の重なり（重み可変）
    final interestScore = _interestOverlap(self.interests, other.interests);

    // 3. 年齢近接性（年齢が近いほど高い）
    final ageScore = _ageProximity(self.age, other.age);

    // 4. 地域近接性（同じ都道府県/沿線でボーナス）
    final locationScore = _locationProximity(
      selfPrefecture: self.prefecture,
      selfLine: self.trainLine,
      otherPrefecture: other.prefecture,
      otherLine: other.trainLine,
    );

    // 5. ベースAIスコア（既存のaiMatchScore）
    final baseScore = other.aiMatchScore.toDouble();

    // カテゴリに応じた重み付け
    final weights = _weightsFor(desiredCategory);

    final weighted = (categoryScore * weights.category) +
        (interestScore * weights.interest) +
        (ageScore * weights.age) +
        (locationScore * weights.location) +
        (baseScore * weights.base);

    return weighted.clamp(0, 100).round();
  }

  /// カテゴリ親和性スコア（0〜100）
  static double _categoryAffinity(
      UserProfile other, ConnectionCategory desired) {
    if (other.primaryCategory == desired) {
      return 100.0; // 完全一致：相手の主目的が一致
    }
    if (other.openTo.contains(desired)) {
      return 70.0; // 受け入れ可能：相手はopenTo
    }
    return 30.0; // 不一致だが他要素で挽回可能
  }

  /// 興味の重なりスコア（0〜100）
  static double _interestOverlap(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 50.0;
    final overlap = a.where((i) => b.contains(i)).length;
    final maxPossible = a.length < b.length ? a.length : b.length;
    if (maxPossible == 0) return 50.0;
    final ratio = overlap / maxPossible;
    // 重なり率を0〜100に変換、最低50を保証（一切なくても極端な低スコアにしない）
    return 50.0 + (ratio * 50.0);
  }

  /// 年齢近接性スコア（0〜100）
  /// 差が0で100、10歳差で20、15歳以上で0
  static double _ageProximity(int a, int b) {
    final diff = (a - b).abs();
    if (diff == 0) return 100.0;
    if (diff >= 15) return 20.0;
    return (100.0 - (diff * 6.0)).clamp(20.0, 100.0);
  }

  /// 地域近接性スコア（0〜100）
  static double _locationProximity({
    required String selfPrefecture,
    String? selfLine,
    required String otherPrefecture,
    String? otherLine,
  }) {
    if (selfPrefecture == otherPrefecture) {
      if (selfLine != null && otherLine != null && selfLine == otherLine) {
        return 100.0; // 同沿線
      }
      return 80.0; // 同都道府県
    }
    // 同地方判定（簡易：関東圏グループ）
    const kanto = {
      '東京都', '神奈川県', '埼玉県', '千葉県', '茨城県', '栃木県', '群馬県'
    };
    const kansai = {'大阪府', '京都府', '兵庫県', '奈良県', '滋賀県', '和歌山県'};
    if ((kanto.contains(selfPrefecture) && kanto.contains(otherPrefecture)) ||
        (kansai.contains(selfPrefecture) && kansai.contains(otherPrefecture))) {
      return 60.0;
    }
    return 40.0;
  }

  /// カテゴリ別重み付け（合計1.0）
  static _Weights _weightsFor(ConnectionCategory category) {
    switch (category) {
      case ConnectionCategory.romance:
        return const _Weights(
            category: 0.20,
            interest: 0.20,
            age: 0.20,
            location: 0.20,
            base: 0.20);
      case ConnectionCategory.business:
        return const _Weights(
            category: 0.30,
            interest: 0.30,
            age: 0.10,
            location: 0.10,
            base: 0.20);
      case ConnectionCategory.learning:
        return const _Weights(
            category: 0.25,
            interest: 0.40,
            age: 0.05,
            location: 0.10,
            base: 0.20);
      case ConnectionCategory.hobby:
        return const _Weights(
            category: 0.25,
            interest: 0.40,
            age: 0.10,
            location: 0.15,
            base: 0.10);
      case ConnectionCategory.friend:
        return const _Weights(
            category: 0.20,
            interest: 0.30,
            age: 0.15,
            location: 0.20,
            base: 0.15);
    }
  }

  /// プロフィール一覧をAIスコアで並べ替え
  static List<ScoredProfile> rankProfiles({
    required List<UserProfile> profiles,
    required ConnectionCategory desiredCategory,
    required MyProfile self,
  }) {
    final scored = profiles.map((p) {
      final score = calculateScore(
        other: p,
        desiredCategory: desiredCategory,
        self: self,
      );
      return ScoredProfile(profile: p, score: score);
    }).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }
}

/// AIスコア付きプロフィール
class ScoredProfile {
  final UserProfile profile;
  final int score;
  const ScoredProfile({required this.profile, required this.score});
}

class _Weights {
  final double category;
  final double interest;
  final double age;
  final double location;
  final double base;
  const _Weights({
    required this.category,
    required this.interest,
    required this.age,
    required this.location,
    required this.base,
  });
}

/// 自分のプロフィール（マッチング計算用）
class MyProfile {
  final int age;
  final String prefecture;
  final String? trainLine;
  final List<String> interests;
  const MyProfile({
    required this.age,
    required this.prefecture,
    this.trainLine,
    required this.interests,
  });
}
