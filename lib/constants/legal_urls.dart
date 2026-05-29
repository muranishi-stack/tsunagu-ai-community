/// TSUNAGU の法的文書 URL 定数
///
/// Firebase Hosting に公開された公式 URL。
/// App Store / Google Play 申請、新規登録時の同意フロー、
/// 設定画面からのリンクなど、アプリ内すべての法的文書参照は
/// ここから引きます。
class LegalUrls {
  LegalUrls._();

  static const String termsOfService =
      'https://tsunagu-ai.app/legal/terms-of-service';

  static const String privacyPolicy =
      'https://tsunagu-ai.app/legal/privacy-policy';

  static const String tokushoho =
      'https://tsunagu-ai.app/legal/tokushoho';
}
