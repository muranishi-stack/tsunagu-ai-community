# `public/` — Firebase Hosting 配信ファイル

このディレクトリは [Firebase Hosting](https://firebase.google.com/docs/hosting) で `https://tsunagu-ai.app` 配下に配信される静的ファイルです。

```
public/
├── index.html              ← トップページ（簡易ランディング）
├── assets/
│   └── legal.css           ← 共通スタイル
└── legal/
    ├── privacy-policy.html      ← プライバシーポリシー
    ├── terms-of-service.html    ← 利用規約
    └── tokushoho.html           ← 特定商取引法に基づく表示
```

## デプロイ手順

### 初回セットアップ

#### 1. Firebase CLI のインストール

```bash
# Node.js が必要です（未インストールなら brew install node 等）
npm install -g firebase-tools
firebase --version  # ← バージョンが表示されれば OK
```

#### 2. Firebase にログイン

```bash
firebase login
# ブラウザが開く → Google アカウントで認証
```

#### 3. プロジェクトの紐付けを確認

`.firebaserc` に `tsunagu-ai-community` がデフォルトプロジェクトとして登録されています。次のコマンドで確認:

```bash
firebase projects:list
firebase use --add  # 必要なら tsunagu-ai-community を選択して default に
```

### デプロイ

リポジトリのルートで:

```bash
firebase deploy --only hosting
```

成功すると以下のような URL が表示されます:

```
✔  Deploy complete!

Hosting URL: https://tsunagu-ai-community.web.app
```

この URL ですぐにアクセス可能。後段でカスタムドメインを `tsunagu-ai.app` に紐付ければ独自ドメインで公開できます。

### カスタムドメイン（`tsunagu-ai.app`）の紐付け

1. [Firebase Console → Hosting](https://console.firebase.google.com/project/tsunagu-ai-community/hosting/sites) を開く
2. 「**カスタムドメインを追加**」をクリック
3. `tsunagu-ai.app` を入力
4. **所有確認用 TXT レコード** が表示される → コピー
5. **お名前.com の DNS 設定** で TXT レコードを追加（手順は後述）
6. 数分〜数十分後、Firebase Console で「**続行**」をクリック
7. **A レコード**（Firebase のホスト IP 2 つ）が表示される → コピー
8. お名前.com で `tsunagu-ai.app` の A レコードを 2 つ追加（既存があれば置換）
9. DNS 伝播後、Firebase が **SSL 証明書を自動発行**（数時間以内）
10. 完了後 `https://tsunagu-ai.app` でアクセス可能

### お名前.com の DNS レコード設定

1. https://navi.onamae.com/login にログイン
2. 「ドメイン」→ `tsunagu-ai.app` を選択
3. 「DNS / 転送設定」→「DNS レコード設定を利用する」を開く
4. 以下を追加:

| 種別 | ホスト名 | TTL | VALUE |
|---|---|---|---|
| TXT | (空欄、または `@`) | 3600 | `firebase=...`（Firebase Console で表示された値） |
| A | (空欄、または `@`) | 3600 | `151.101.1.x`（Firebase Console で表示された値） |
| A | (空欄、または `@`) | 3600 | `151.101.65.x`（Firebase Console で表示された値） |

> ⚠️ お名前.com 標準のネームサーバ (`01.dnsv.jp` 等) を使う場合は上記の DNS レコード設定で OK。
> 既に他のネームサーバ（Cloudflare 等）に切り替えている場合はそちらで設定してください。

5. 「確認画面へ進む」→「設定する」

### 反映確認

```bash
# TXT レコードが反映されているか
dig +short TXT tsunagu-ai.app

# A レコードが反映されているか
dig +short A tsunagu-ai.app
```

伝播は通常 5〜30 分、最大 24〜48 時間かかることがあります。

## アクセス URL（カスタムドメイン設定後）

```
https://tsunagu-ai.app/                          ← トップ
https://tsunagu-ai.app/legal/privacy-policy      ← プライバシーポリシー（cleanUrls 有効）
https://tsunagu-ai.app/legal/terms-of-service    ← 利用規約
https://tsunagu-ai.app/legal/tokushoho           ← 特定商取引法表示
```

これらの URL を App Store / Google Play 申請時に **プライバシーポリシー URL** として提出します。

## ローカルプレビュー

Firebase CLI で本番環境と同じ挙動を確認できます:

```bash
firebase emulators:start --only hosting
# → http://localhost:5000 で配信
```

または素の Python HTTP サーバでも OK:

```bash
cd public && python3 -m http.server 5070
# → http://localhost:5070
```
