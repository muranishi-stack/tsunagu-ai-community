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
  String? filterPrefecture; // null = すべて
  String? filterTrainLine;  // null = すべて

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
    filterPrefecture = null;
    filterTrainLine = null;
    notifyListeners();
  }

  bool get hasActiveLocationFilter =>
      filterPrefecture != null || filterTrainLine != null;
}
