/**
 * TSUNAGU Cloud Functions
 *
 * 主機能:
 *  - lineAuth: LINE OAuth の認可コード（code）と redirectUri を受け取り、
 *    LINE Access Token → LINE Profile を取得し、Firebase Custom Token を発行して返す。
 *
 * セキュリティ:
 *  - LINE Channel Secret は Secret Manager の `LINE_CHANNEL_SECRET` から取得
 *  - LINE Channel ID は環境変数 `LINE_CHANNEL_ID` から取得（公開しても問題なし）
 *  - CORS は本番 origin に絞る（開発中は * を許容）
 */

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

// 環境変数 & シークレット
const LINE_CHANNEL_ID = defineString("LINE_CHANNEL_ID", {
  default: "2010225529",
  description: "LINE Login Channel ID (公開可能)",
});
const LINE_CHANNEL_SECRET = defineSecret("LINE_CHANNEL_SECRET");

// Gemini API キー（Secret Manager 管理。クライアントには出さない）
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-2.0-flash";
const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/" +
  GEMINI_MODEL +
  ":generateContent";

// LINE 公式エンドポイント
const LINE_TOKEN_URL = "https://api.line.me/oauth2/v2.1/token";
const LINE_PROFILE_URL = "https://api.line.me/v2/profile";
const LINE_VERIFY_URL = "https://api.line.me/oauth2/v2.1/verify";

/** CORS ヘッダーを設定 */
function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Max-Age", "3600");
}

/**
 * LINE OAuth Code → Firebase Custom Token 交換
 *
 * リクエスト (POST application/json):
 *   { "code": "<LINE auth code>", "redirectUri": "<callback URL>" }
 *
 * レスポンス:
 *   200 { "customToken": "...", "lineUserId": "...", "displayName": "...", "pictureUrl": "..." }
 *   400/401/500 { "error": "..." }
 */
exports.lineAuth = onRequest(
  {
    region: "asia-northeast1", // 東京リージョン
    secrets: [LINE_CHANNEL_SECRET],
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (req, res) => {
    setCors(res);

    // Preflight
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed" });
      return;
    }

    try {
      const { code, redirectUri } = req.body || {};
      if (!code || !redirectUri) {
        res.status(400).json({ error: "code と redirectUri が必要です" });
        return;
      }

      const channelId = LINE_CHANNEL_ID.value();
      const channelSecret = LINE_CHANNEL_SECRET.value();

      // ====== Step 1: LINE Access Token を取得 ======
      const tokenParams = new URLSearchParams({
        grant_type: "authorization_code",
        code,
        redirect_uri: redirectUri,
        client_id: channelId,
        client_secret: channelSecret,
      });

      let tokenResp;
      try {
        tokenResp = await axios.post(LINE_TOKEN_URL, tokenParams.toString(), {
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          timeout: 10000,
        });
      } catch (e) {
        const detail = e.response?.data || e.message;
        logger.error("LINE token exchange failed", detail);
        res.status(401).json({
          error: "LINE token exchange failed",
          detail: detail,
        });
        return;
      }

      const lineAccessToken = tokenResp.data.access_token;
      const lineIdToken = tokenResp.data.id_token; // OpenID Connect 用（任意）

      // ====== Step 2: LINE プロフィール取得 ======
      let profileResp;
      try {
        profileResp = await axios.get(LINE_PROFILE_URL, {
          headers: { Authorization: `Bearer ${lineAccessToken}` },
          timeout: 10000,
        });
      } catch (e) {
        const detail = e.response?.data || e.message;
        logger.error("LINE profile fetch failed", detail);
        res.status(401).json({
          error: "LINE profile fetch failed",
          detail: detail,
        });
        return;
      }

      const lineUserId = profileResp.data.userId;
      const displayName = profileResp.data.displayName || "LINE ユーザー";
      const pictureUrl = profileResp.data.pictureUrl || null;

      if (!lineUserId) {
        res.status(500).json({ error: "LINE user ID not found in profile" });
        return;
      }

      // ====== Step 3: Firebase Custom Token を発行 ======
      const firebaseUid = `line:${lineUserId}`;

      // Firebase Auth に対応ユーザーが無ければ作成
      try {
        await admin.auth().getUser(firebaseUid);
      } catch (e) {
        if (e.code === "auth/user-not-found") {
          await admin.auth().createUser({
            uid: firebaseUid,
            displayName,
            photoURL: pictureUrl || undefined,
          });
          logger.info(`Created new Firebase user: ${firebaseUid}`);
        } else {
          throw e;
        }
      }

      // Firestore にも基本プロフィール（既存なら touch のみ）
      try {
        const ref = admin.firestore().collection("users").doc(firebaseUid);
        const snap = await ref.get();
        if (!snap.exists) {
          await ref.set({
            uid: firebaseUid,
            displayName,
            photoURL: pictureUrl,
            provider: "line",
            lineUserId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          await ref.update({
            lastSignInAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        // Firestore 書き込み失敗は致命的ではないので warn のみ
        logger.warn("Firestore upsert failed (non-fatal)", e.message);
      }

      const customToken = await admin.auth().createCustomToken(firebaseUid, {
        provider: "line",
        lineUserId,
      });

      logger.info(`Issued custom token for ${firebaseUid}`);
      res.status(200).json({
        customToken,
        lineUserId,
        firebaseUid,
        displayName,
        pictureUrl,
      });
    } catch (err) {
      logger.error("lineAuth unhandled error", err);
      res.status(500).json({ error: "Internal Server Error", detail: err.message });
    }
  }
);

/**
 * AIプロフィール最適化 (Gemini)
 *
 * リクエスト (POST application/json, Authorization: Bearer <Firebase IDトークン>):
 *   {
 *     "name": "...", "age": 32, "occupation": "...",
 *     "bio": "...", "interests": ["...","..."],
 *     "primaryCategory": "business"
 *   }
 * レスポンス:
 *   200 {
 *     "improvedBio": "...",       // 改善後の自己紹介文（そのまま使える）
 *     "tips": ["...", "..."],     // 改善ポイント
 *     "suggestedInterests": ["..."]
 *   }
 *
 * セキュリティ:
 *   - 呼び出しには有効な Firebase ID トークンが必須（verifyIdToken）
 *   - GEMINI_API_KEY は Secret Manager から取得しクライアントには出さない
 */
exports.optimizeProfile = onRequest(
  {
    region: "asia-northeast1",
    secrets: [GEMINI_API_KEY],
    cors: true,
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (req, res) => {
    setCors(res);
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed" });
      return;
    }

    // ===== 認証チェック =====
    const authHeader = req.headers.authorization || "";
    const idToken = authHeader.startsWith("Bearer ")
      ? authHeader.substring(7)
      : null;
    if (!idToken) {
      res.status(401).json({ error: "認証が必要です" });
      return;
    }
    try {
      await admin.auth().verifyIdToken(idToken);
    } catch (e) {
      logger.warn("optimizeProfile: invalid ID token", e.message);
      res.status(401).json({ error: "認証トークンが無効です" });
      return;
    }

    try {
      const {
        name = "",
        age = "",
        occupation = "",
        bio = "",
        interests = [],
        primaryCategory = "",
      } = req.body || {};

      const categoryLabels = {
        romance: "恋愛",
        friend: "友達",
        business: "仕事",
        learning: "学び",
        hobby: "趣味",
      };
      const categoryJa = categoryLabels[primaryCategory] || primaryCategory;

      const prompt = [
        "あなたは日本のマルチパーパス・コミュニケーションアプリ「TSUNAGU」の",
        "プロフィール最適化アシスタントです。以下のユーザー情報をもとに、",
        "魅力的で誠実、かつ読みやすい自己紹介文に改善してください。",
        "誇張・虚偽・不適切表現は避け、120〜200字程度の日本語にしてください。",
        "",
        `主な目的: ${categoryJa}`,
        `ニックネーム: ${name}`,
        `年齢: ${age}`,
        `職業: ${occupation}`,
        `興味: ${Array.isArray(interests) ? interests.join("、") : interests}`,
        `現在の自己紹介: ${bio || "(未記入)"}`,
        "",
        "次の JSON 形式のみで回答してください（前後に説明文やコードブロックは不要）:",
        '{"improvedBio":"改善後の自己紹介文","tips":["改善ポイント1","改善ポイント2","改善ポイント3"],"suggestedInterests":["追加候補の興味1","興味2"]}',
      ].join("\n");

      let geminiResp;
      try {
        geminiResp = await axios.post(
          `${GEMINI_URL}?key=${GEMINI_API_KEY.value()}`,
          {
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.7,
              responseMimeType: "application/json",
            },
          },
          {
            headers: { "Content-Type": "application/json" },
            timeout: 20000,
          }
        );
      } catch (e) {
        const detail = e.response?.data || e.message;
        logger.error("Gemini API call failed", detail);
        res.status(502).json({
          error: "AI生成に失敗しました",
          detail: typeof detail === "string" ? detail : JSON.stringify(detail),
        });
        return;
      }

      const text =
        geminiResp.data?.candidates?.[0]?.content?.parts?.[0]?.text || "";

      let parsed;
      try {
        parsed = JSON.parse(text);
      } catch (_) {
        // JSON でない場合は本文をそのまま improvedBio に
        parsed = { improvedBio: text.trim(), tips: [], suggestedInterests: [] };
      }

      res.status(200).json({
        improvedBio: parsed.improvedBio || "",
        tips: Array.isArray(parsed.tips) ? parsed.tips : [],
        suggestedInterests: Array.isArray(parsed.suggestedInterests)
          ? parsed.suggestedInterests
          : [],
      });
    } catch (err) {
      logger.error("optimizeProfile unhandled error", err);
      res
        .status(500)
        .json({ error: "Internal Server Error", detail: err.message });
    }
  }
);

/**
 * ヘルスチェック用エンドポイント（デバッグ用）
 */
exports.ping = onRequest(
  { region: "asia-northeast1", cors: true },
  (req, res) => {
    setCors(res);
    res.status(200).json({
      ok: true,
      service: "tsunagu-functions",
      time: new Date().toISOString(),
    });
  }
);
