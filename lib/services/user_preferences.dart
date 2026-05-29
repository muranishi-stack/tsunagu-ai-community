import 'package:flutter/foundation.dart';
import '../models/connection_category.dart';
import 'ai_matching_service.dart';

/// 自分のプロフィール状態を保持する ChangeNotifier
/// ※ shared_preferencesによる永続化は将来追加可能。現状はメモリ保持。
class UserPreferences extends ChangeNotifier {
  // シングルトン
  static final UserPreferences _instance = UserPreferences._internal();
  factory UserPreferences() => _instance;
  UserPreferences._internal();

  // 基本プロフィール（のりあつ）
  String name = 'のりあつ';
  int age = 32;
  String occupation = '会社員';

  // カテゴリ設定
  ConnectionCategory primaryCategory = ConnectionCategory.business;
  Set<ConnectionCategory> openTo = {
    ConnectionCategory.business,
    ConnectionCategory.learning,
    ConnectionCategory.friend,
  };

  // 興味
  List<String> interests = ['ビジネス', '学び', '読書', 'カフェ', 'テクノロジー'];

  // 地域
  String prefecture = '東京都';
  String? trainLine = 'JR山手線';

  // フィルター（検索条件）
  ConnectionCategory? filterCategory; // null = すべてのカテゴリ
  String? filterPrefecture; // null = すべて
  String? filterTrainLine;  // null = すべて

  /// 距離フィルター: 何km以内のユーザーのみ表示するか
  /// null = 距離無制限 (デフォルト)
  /// 値あり = lat/lng 未保存ユーザーは非表示 (Choice B)
  /// Phase 1.11.9: デフォルトを 25km → null (無制限) に変更
  /// 理由: 初回表示で 0人になるケースを防ぎ、ユーザーが任意で距離を絞る形へ
  double? filterMaxDistanceKm;

  /// 年齢フィルター: 表示する相手の最小年齢
  /// デフォルトは自分の年齢 -5 歳（initAgeFilterFromMyAge() で初期化）
  int filterMinAge = 18;

  /// 年齢フィルター: 表示する相手の最大年齢
  /// デフォルトは自分の年齢 +5 歳
  int filterMaxAge = 99;

  /// 年齢フィルターが手動設定されたか（true なら自動初期化をスキップ）
  bool _ageFilterCustomized = false;

  // 自分の現在地 (起動時GPS自動更新で AuthGate から書き込み)
  // Firestore とは独立に、フィルタ計算のためメモリ上にも保持する
  double? myLatitude;
  double? myLongitude;

  /// AIマッチング計算用の自プロフィール
  MyProfile get myProfile => MyProfile(
        age: age,
        prefecture: prefecture,
        trainLine: trainLine,
        interests: interests,
      );

  // ----- 更新メソッド -----

  void setPrimaryCategory(ConnectionCategory cat) {
    primaryCategory = cat;
    // primaryは自動的にopenToにも入れる
    openTo.add(cat);
    notifyListeners();
  }

  void toggleOpenTo(ConnectionCategory cat) {
    if (openTo.contains(cat)) {
      // primaryは外せない
      if (cat == primaryCategory) return;
      openTo.remove(cat);
    } else {
      openTo.add(cat);
    }
    notifyListeners();
  }

  void setPrefecture(String pref) {
    prefecture = pref;
    trainLine = null; // 都道府県変更時は沿線リセット
    notifyListeners();
  }

  void setTrainLine(String? line) {
    trainLine = line;
    notifyListeners();
  }

  void setFilterCategory(ConnectionCategory? cat) {
    filterCategory = cat;
    notifyListeners();
  }

  void setFilterPrefecture(String? pref) {
    filterPrefecture = pref;
    if (pref == null) {
      filterTrainLine = null;
    }
    notifyListeners();
  }

  void setFilterTrainLine(String? line) {
    filterTrainLine = line;
    notifyListeners();
  }

  void clearFilters() {
    filterCategory = null;
    filterPrefecture = null;
    filterTrainLine = null;
    filterMaxDistanceKm = null;
    filterMinAge = 18;
    filterMaxAge = 99;
    _ageFilterCustomized = false;
    notifyListeners();
  }

  void setFilterMaxDistanceKm(double? km) {
    filterMaxDistanceKm = km;
    notifyListeners();
  }

  void setMyLocation(double? lat, double? lng) {
    myLatitude = lat;
    myLongitude = lng;
    notifyListeners();
  }

  /// 年齢フィルタを (min, max) で更新
  void setFilterAgeRange(int min, int max) {
    filterMinAge = min.clamp(18, 99);
    filterMaxAge = max.clamp(18, 99);
    if (filterMinAge > filterMaxAge) {
      filterMinAge = filterMaxAge;
    }
    _ageFilterCustomized = true;
    notifyListeners();
  }

  /// 自分の年齢から ±5 歳のデフォルト範囲を設定する。
  /// 既にユーザーが手動設定済みなら何もしない。
  void initAgeFilterFromMyAge(int myAge) {
    if (_ageFilterCustomized) return;
    filterMinAge = (myAge - 5).clamp(18, 99);
    filterMaxAge = (myAge + 5).clamp(18, 99);
    notifyListeners();
  }

  bool get hasActiveAgeFilter =>
      _ageFilterCustomized && (filterMinAge > 18 || filterMaxAge < 99);

  bool get hasActiveLocationFilter =>
      filterPrefecture != null ||
      filterTrainLine != null ||
      filterMaxDistanceKm != null;
}
