/// Non-web (mobile) platform stub for web-only helpers.
/// 実行時は kIsWeb の分岐で呼ばれないため、ここはダミー実装で十分。
library;

void redirectTo(String url) {
  throw UnsupportedError('redirectTo is only available on Web');
}

Map<String, String> readQueryParams() => const {};

void clearQueryParams() {}
