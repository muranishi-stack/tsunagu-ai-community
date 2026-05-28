/// Web (dart:html) implementation for LINE OAuth helpers.
library;

// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 現在のタブをそのまま指定URLへ遷移
void redirectTo(String url) {
  html.window.location.assign(url);
}

/// 現在の URL のクエリパラメータを取得
Map<String, String> readQueryParams() {
  final uri = Uri.parse(html.window.location.href);
  return Map<String, String>.from(uri.queryParameters);
}

/// URL から code/state/error を取り除き、履歴を pushState で書き換える
void clearQueryParams() {
  final current = Uri.parse(html.window.location.href);
  final cleared = current.replace(queryParameters: {});
  // queryParameters が空でも '?' が付かない形にするため toString() を加工
  final cleanedStr = cleared.toString().replaceFirst(RegExp(r'\?$'), '');
  html.window.history.replaceState(null, '', cleanedStr);
}
