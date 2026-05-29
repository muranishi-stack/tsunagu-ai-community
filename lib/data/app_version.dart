/// TSUNAGU アプリのバージョン情報
///
/// バージョン規則:
///   - Phase X.Y: 大きな機能リリース単位 (X=メジャー / Y=マイナー)
///   - 数値版は YYMMDD でビルド日を併記
///
/// Phase 1.11.9 - TSUNAGU
/// Fix: DISCOVER screen full restoration on iPhone Safari
///   - lat/lng injected for all 42 seed users (prefecture-based)
///   - Distance filter default 25km → 無制限
///   - Age filter only applied when user customizes it
///   - ATTACK/SKIP button hit-test fixed (Material + InkWell + IgnorePointer badge)
///   - _swipedUids exclusion in _applyFilters (prevents revival after swipe)
///   - List reference replacement in _swipeCard for guaranteed UI rebuild
///   - Restored Phase 1.11.2 button handler (_dragOffset initial offset)
///     for visible swipe animation on iOS Safari
///   - AnimationStatusListener instead of Future.then() (iOS Safari fix)
///   - Listener (Pointer) based drag for reliable iOS Safari gesture
///   - CSS touch-action / overscroll-behavior tuned for mobile Web
library;

class AppVersion {
  AppVersion._();

  /// ユーザー向けバージョン表記
  static const String version = '1.11.9';

  /// 内部フェーズ識別子
  static const String phase = 'Phase 1.11.9';

  /// ビルド日 (YYYY-MM-DD)
  static const String buildDate = '2026-05-29';

  /// バージョン + ビルド日 の組み合わせ表記
  static const String fullLabel = 'v$version · $buildDate';

  /// フッターなどで使う短い表記
  static const String shortLabel = 'v$version';
}
