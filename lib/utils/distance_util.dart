/// Distance calculation utilities for TSUNAGU
///
/// Haversine formula を使用して 2 地点間の距離を km 単位で計算。
/// プライバシー上、生の lat/lng は他人に公開せず、距離だけを表示する設計。
library;

import 'dart:math' as math;

class DistanceUtil {
  DistanceUtil._();

  /// 地球の半径 (km)
  static const double earthRadiusKm = 6371.0;

  /// 2 地点間の大圏距離を km 単位で返す（Haversine 公式）
  ///
  /// [lat1], [lon1]: 地点 A の緯度経度
  /// [lat2], [lon2]: 地点 B の緯度経度
  ///
  /// 例: 東京駅 (35.6812, 139.7671) と 大阪駅 (34.7024, 135.4959) → 約 396 km
  static double calculateKm(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// 双方の座標が揃っている場合のみ距離を返す、片方でも欠けたら null
  static double? tryCalculateKm({
    double? lat1,
    double? lon1,
    double? lat2,
    double? lon2,
  }) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      return null;
    }
    return calculateKm(lat1, lon1, lat2, lon2);
  }

  /// 距離をユーザーフレンドリーな文字列に整形
  ///
  /// - 1km 未満: "950m"
  /// - 10km 未満: "5.3km"
  /// - 10km 以上: "12km"
  /// - null: "距離不明"
  static String formatKm(double? km) {
    if (km == null) return '距離不明';
    if (km < 1.0) {
      final m = (km * 1000).round();
      return '${m}m';
    }
    if (km < 10.0) {
      return '${km.toStringAsFixed(1)}km';
    }
    return '${km.round()}km';
  }

  /// マッチング画面用の説明テキスト
  static String formatDescription(double? km) {
    if (km == null) return '距離不明';
    if (km < 1.0) return 'すぐ近く';
    if (km < 5.0) return '${km.toStringAsFixed(1)}km';
    if (km < 50.0) return '${km.toStringAsFixed(0)}km';
    return '${km.round()}km';
  }

  static double _toRadians(double deg) => deg * (math.pi / 180.0);
}

/// 距離フィルター用プリセット
class DistancePresets {
  DistancePresets._();

  /// 選択可能な距離 (km)、最後の null は「制限なし」
  static const List<double?> options = [5, 10, 25, 50, 100, null];

  /// デフォルト値（25km）
  static const double defaultKm = 25.0;

  static String labelFor(double? km) {
    if (km == null) return '制限なし';
    if (km < 10) return '${km.toInt()}km';
    return '${km.toInt()}km';
  }
}
