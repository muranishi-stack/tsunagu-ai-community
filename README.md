# TSUNAGU

> 日本限定の多目的コミュニケーションアプリ (恋愛 / 友達 / 仕事 / 学び / 趣味)

朱色 (#E63946) × 結びマークをブランドカラーとした、5カテゴリを一つのアプリで切り替えられるマルチパーパス・コミュニケーション・プラットフォーム。

## 🎨 Brand

- **Primary color**: 朱色 vermillion `#E63946`
- **Logo**: 結びマーク (musubi knot)
- **Package name**: `com.tsunagu.app`
- **Display name**: TSUNAGU

## 🛠 Tech Stack

- **Flutter**: 3.35.4 (locked)
- **Dart**: 3.9.2 (locked)
- **State management**: ChangeNotifier (singleton pattern)
- **Theme**: Material Design 3
- **Web preview**: serve.py (Python HTTP server with SPA fallback)

## 📱 Platforms

| Platform | Status |
|---|---|
| Android | ✅ Release APK 構築済み (signed) |
| iOS | ⚙️ Xcode から構築可能 (本書参照) |
| Web | ✅ Hash URL strategy 採用、Service Worker disabled |

## 🚀 Getting Started

### Prerequisites

- Flutter 3.35.4
- Dart 3.9.2
- (iOS) Xcode 15+, CocoaPods, macOS
- (Android) Android Studio + Android SDK API 35

### Setup

```bash
git clone https://github.com/muranishi-stack/tsunagu-ai-community.git
cd tsunagu-ai-community
flutter pub get
```

### Run on Web

```bash
flutter build web --release --pwa-strategy=none
python3 serve.py 5060
# Open http://localhost:5060
```

### Run on Android

```bash
flutter run -d <android-device-id>
# Or build APK
flutter build apk --release
```

---

## 🍎 iOS ビルド手順 (Mac + Xcode)

実機 iPhone で TSUNAGU をテストするには macOS と Xcode が必要です。

### 1. 環境準備

```bash
# Xcode Command Line Tools
xcode-select --install

# CocoaPods
sudo gem install cocoapods

# Flutter SDK 3.35.4
# https://docs.flutter.dev/get-started/install/macos

# Verify
flutter doctor
```

### 2. プロジェクトのクローン

```bash
git clone https://github.com/muranishi-stack/tsunagu-ai-community.git
cd tsunagu-ai-community
flutter pub get
```

### 3. iOS 依存パッケージのインストール

```bash
cd ios
pod install
cd ..
```

> ⚠️ `pod install` 中にエラーが出る場合は `pod repo update` を試してください。

### 4. Bundle ID の確認・設定

Xcode で `ios/Runner.xcworkspace` を開きます (`.xcodeproj` ではなく `.xcworkspace`!)

```bash
open ios/Runner.xcworkspace
```

- 左ペインで **Runner** を選択
- **Signing & Capabilities** タブを開く
- **Team**: ご自身の Apple ID を選択
  - 無料 Apple ID でも OK (7日間有効の自己署名)
  - 有料 Developer Program ($99/年) なら 1年間有効 + TestFlight 配布可
- **Bundle Identifier**: `com.tsunagu.app` (もし既に他で使われていたら `com.yourname.tsunagu` のように変更)
- **Automatically manage signing** を ON

### 5. iPhone を接続して実行

1. iPhone を USB-C / Lightning ケーブルで Mac に接続
2. iPhone 側で「**このコンピュータを信頼**」を選択
3. Xcode 上部のデバイス選択欄で **自分の iPhone** を選択
4. ▶️ 実行ボタンをクリック (または `Cmd + R`)

### 6. iPhone 側で開発元を信頼

初回実行時、iPhone で以下のエラーが出ます:

> "信頼されていないデベロッパ"

**設定アプリで信頼操作**:

1. iPhone の **設定** → **一般** → **VPN とデバイス管理**
2. 自分の Apple ID が表示されているのでタップ
3. **「<your-email>" を信頼**」をタップ → 確認
4. ホーム画面に戻って **TSUNAGU** アイコンをタップ起動

### 7. (オプション) コマンドラインから IPA ビルド

```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

ビルド成果物: `build/ios/ipa/tsunagu.ipa`

### 📅 無料 Apple ID の制限事項

| 項目 | 無料 | 有料 ($99/年) |
|---|---|---|
| 有効期限 | 7日間 | 1年間 |
| インストール可能端末数 | 3台 | 100台 |
| TestFlight 配布 | ❌ | ✅ (最大10,000人) |
| App Store 公開 | ❌ | ✅ |
| 7日後の再インストール | 必要 | 不要 |

---

## 🏗 Project Structure

```
lib/
├── main.dart              # Entry point + routing
├── theme/
│   └── app_theme.dart     # 朱色テーマ定義
├── widgets/
│   └── tsunagu_logo.dart  # 結びマークロゴ
├── screens/               # ユーザー向け画面
│   └── main_screen.dart   # 5カテゴリ切替 + Tinder風 UI
└── admin/                 # 管理コンソール
    ├── models/
    ├── services/
    │   └── admin_service.dart   # AI 巡回 + データ連携
    ├── screens/
    │   ├── login_screen.dart
    │   ├── dashboard_screen.dart
    │   ├── users_screen.dart
    │   ├── revenue_screen.dart
    │   ├── boosts_screen.dart
    │   ├── reports_screen.dart
    │   ├── ai_moderation_screen.dart    # AI 自動巡回 + 人間レビュー
    │   ├── analytics_screen.dart
    │   ├── announcements_screen.dart
    │   ├── data_sources_screen.dart     # 国内サービス連携センター
    │   └── settings_screen.dart
    └── widgets/
        └── admin_layout.dart
```

## 🛡 Admin Console

管理コンソールには 5 カテゴリのアプリ機能とは別に、以下の運営機能が含まれます:

- **ダッシュボード**: KPI / 売上トレンド
- **ユーザー管理**: スワイプ、検索、サイドパネル詳細
- **課金・売上**: トランザクション一覧 + CSV エクスポート
- **ブースト履歴**
- **モデレーション**: ユーザー通報の一括処理
- **🆕 AI 巡回**: 規約違反 / 事件性のあるコンテンツを AI が定期スキャン → 管理者が判断
- **分析**: アクション分析
- **お知らせ配信**: プッシュ通知 / アプリ内通知
- **🆕 データ連携**: ローンチ期データ取り込み (LINE 公式 / Yahoo! JAPAN / Connpass / 合成シードなど国内9サービス)
- **設定**

### Admin ログイン

```
URL: /#/admin/login
Email: admin@tsunagu.jp
Password: Admin@2025!
```

## 🔐 Security

以下のファイルは `.gitignore` で除外されており、リポジトリには含まれません:

- `android/key.properties` (Android 署名パスワード)
- `android/release-key.jks` (Android 署名鍵)
- `google-services.json` / `GoogleService-Info.plist` (Firebase 設定)

Android リリース APK をビルドする場合は、別途これらの署名鍵をローカルに配置する必要があります。

## 📄 License

Proprietary. All rights reserved.
