/// TSUNAGU アプリのバージョン情報
///
/// バージョン規則:
///   - Phase X.Y: 大きな機能リリース単位 (X=メジャー / Y=マイナー)
///   - 数値版は YYMMDD でビルド日を併記
///
/// Phase 1.11.1 - TSUNAGU
library;

class AppVersion {
  AppVersion._();

  /// ユーザー向けバージョン表記
  static const String version = '1.11.1';

  /// 内部フェーズ識別子
  static const String phase = 'Phase 1.11.1';

  /// ビルド日 (YYYY-MM-DD)
  static const String buildDate = '2026-05-29';

  /// バージョン + ビルド日 の組み合わせ表記
  static const String fullLabel = 'v$version · $buildDate';

  /// フッターなどで使う短い表記
  static const String shortLabel = 'v$version';
}
