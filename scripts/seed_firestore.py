"""
TSUNAGU Firestore Seed Script
==============================

This script seeds the TSUNAGU-AI-Community Firestore database with:
  - 40 realistic user profiles (across 5 categories)
  - 12 user reports (various statuses)
  - 30 transactions (revenue records)
  - 12 AI moderation flags (varying severities)

Usage:
    python3 scripts/seed_firestore.py [--clear]

  --clear    Delete existing data in the collections before seeding.

Requirements:
    pip install firebase-admin==7.1.0
    Set the path to your Firebase Admin SDK JSON file at FIREBASE_KEY_PATH below.
"""

import sys
import os
import random
from datetime import datetime, timedelta, timezone

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 Run: pip install firebase-admin==7.1.0")
    sys.exit(1)

# ============================================================
# Configuration
# ============================================================
FIREBASE_KEY_PATH = "/opt/flutter/firebase-admin-sdk.json"
SEED_USER_COUNT = 40
SEED_REPORT_COUNT = 12
SEED_TRANSACTION_COUNT = 30
SEED_AI_FLAG_COUNT = 12

# ============================================================
# Initialize Firebase
# ============================================================
if not os.path.exists(FIREBASE_KEY_PATH):
    print(f"❌ Firebase admin key not found at: {FIREBASE_KEY_PATH}")
    sys.exit(1)

cred = credentials.Certificate(FIREBASE_KEY_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()
print(f"✅ Connected to Firebase project: tsunagu-ai-community")

# ============================================================
# Sample data definitions
# ============================================================
FIRST_NAMES_F = [
    "Hana", "Aoi", "Yuki", "Rin", "Mio", "Sora", "Nao", "Ema",
    "Aki", "Kana", "Saki", "Yui", "Rio", "Nana", "Mei", "Sara",
    "Akari", "Hina", "Kohaku", "Tsumugi",
]
FIRST_NAMES_M = [
    "Ren", "Sho", "Kai", "Taku", "Yuto", "Hiro", "Riku", "Daichi",
    "Tomo", "Ko", "Jin", "Tatsu", "Naoki", "Yuma", "Haru", "Kazu",
    "Sota", "Itsuki", "Eito", "Aoi",
]
SURNAMES = [
    "Sato", "Suzuki", "Takahashi", "Tanaka", "Watanabe", "Ito", "Yamamoto",
    "Nakamura", "Kobayashi", "Kato", "Yoshida", "Yamada", "Sasaki", "Yamaguchi",
    "Matsumoto", "Inoue", "Kimura", "Hayashi", "Saito", "Shimizu",
]
PREFECTURES = [
    ("東京都", 0.35), ("神奈川県", 0.12), ("大阪府", 0.10), ("愛知県", 0.06),
    ("埼玉県", 0.07), ("千葉県", 0.06), ("京都府", 0.04), ("兵庫県", 0.05),
    ("福岡県", 0.05), ("北海道", 0.03), ("宮城県", 0.02), ("広島県", 0.02),
    ("静岡県", 0.03),
]
DOMAINS = ["gmail.com", "icloud.com", "yahoo.co.jp", "outlook.jp"]

CATEGORIES = ["romance", "friend", "business", "learning", "hobby"]
CATEGORY_WEIGHTS = [0.30, 0.22, 0.20, 0.13, 0.15]

STATUSES = ["active"] * 8 + ["suspended"] * 1 + ["pendingVerification"] * 1
PLANS = [None] * 5 + ["allCategory"] * 2 + ["singleCategory"] * 2 + ["freeTrial"]


def weighted_choice(pairs):
    items, weights = zip(*pairs)
    return random.choices(items, weights=weights, k=1)[0]


def pick_prefecture():
    return weighted_choice(PREFECTURES)


def pick_category():
    return random.choices(CATEGORIES, weights=CATEGORY_WEIGHTS, k=1)[0]


def now_utc():
    return datetime.now(timezone.utc)


# ============================================================
# Clear collections (optional)
# ============================================================
def clear_collection(collection_name, batch_size=100):
    print(f"🧹 Clearing collection '{collection_name}'...")
    coll = db.collection(collection_name)
    deleted = 0
    while True:
        docs = list(coll.limit(batch_size).stream())
        if not docs:
            break
        batch = db.batch()
        for doc in docs:
            batch.delete(doc.reference)
            deleted += 1
        batch.commit()
    print(f"   Deleted {deleted} documents")


# ============================================================
# Seed users
# ============================================================
def seed_users(count):
    print(f"\n👤 Seeding {count} users...")
    batch = db.batch()
    user_ids = []
    for i in range(count):
        is_female = random.random() < 0.5
        first = random.choice(FIRST_NAMES_F if is_female else FIRST_NAMES_M)
        last = random.choice(SURNAMES)
        suffix = random.randint(100, 9999)
        display_name = f"{first}{suffix}"
        email = f"{first.lower()}{suffix}@{random.choice(DOMAINS)}"

        days_ago = random.randint(1, 365)
        joined = now_utc() - timedelta(days=days_ago)
        last_active = now_utc() - timedelta(days=random.randint(0, 30))

        user_id = f"usr_{i:06d}"
        user_ids.append((user_id, display_name))

        doc_ref = db.collection("users").document(user_id)
        batch.set(doc_ref, {
            "name": display_name,
            "full_name": f"{last} {first}",
            "email": email,
            "age": random.randint(20, 45),
            "prefecture": pick_prefecture(),
            "primary_category": pick_category(),
            "joined_at": joined,
            "last_active_at": last_active,
            "status": random.choice(STATUSES),
            "match_count": random.randint(0, 50),
            "report_count": random.randint(0, 3) if random.random() < 0.1 else 0,
            "active_plan": random.choice(PLANS),
            "avatar_url": f"https://i.pravatar.cc/300?u={user_id}",
            "bio": _gen_bio(pick_category()),
            "interests": _gen_interests(),
            "is_seed_data": True,  # Marker for cleanup
            "created_at": joined,
            "updated_at": now_utc(),
        })

        # Firestore batch limit is 500
        if (i + 1) % 100 == 0:
            batch.commit()
            batch = db.batch()
            print(f"   Committed {i + 1} users...")

    batch.commit()
    print(f"✅ Seeded {count} users")
    return user_ids


def _gen_bio(category):
    bios = {
        "romance": [
            "新しい出会いを楽しみたいです。一緒に美味しいご飯を食べに行きましょう！",
            "アウトドアと旅行が好き。価値観を共有できる方とお話したいです。",
            "映画と読書が趣味です。ゆっくり関係を育てたいタイプです。",
            "気軽にお話しましょう！カフェ巡りが好きです。",
        ],
        "friend": [
            "新しい友達と気軽に話したい！趣味のことや日常のことなど。",
            "週末に一緒に遊べる友達募集中。映画とゲームが好きです。",
            "同世代で気が合う人と繋がりたいです。",
            "色々な人と話してみたい！LINEとかも教え合えたら嬉しい。",
        ],
        "business": [
            "スタートアップで働いています。同業界の方と繋がりたいです。",
            "副業仲間募集中！プログラミング・デザイン系の知識共有しませんか？",
            "ビジネスコミュニティを広げたいです。気軽にメッセージください。",
            "起業を考えている方、一緒に勉強会しませんか？",
        ],
        "learning": [
            "英語学習仲間募集！一緒にモチベ上げていきましょう。",
            "資格取得を目指して勉強中。情報交換できる方探してます。",
            "プログラミング初心者です。優しく教えてくれる方歓迎。",
            "読書会に参加したい！ノンフィクション好きです。",
        ],
        "hobby": [
            "カメラ・写真が趣味です。撮影スポット情報交換しましょう！",
            "登山仲間募集！初心者から上級者まで歓迎です。",
            "アニメ・漫画好きの方、語り合いましょう！",
            "音楽ライブ・フェスが好きです。一緒に行ける人募集！",
        ],
    }
    return random.choice(bios.get(category, ["よろしくお願いします！"]))


def _gen_interests():
    pool = [
        "旅行", "映画", "読書", "音楽", "アニメ", "ゲーム", "カフェ", "料理",
        "スポーツ", "ヨガ", "ジム", "登山", "キャンプ", "写真", "アート",
        "美術館", "ライブ", "フェス", "プログラミング", "デザイン", "投資",
        "英語", "中国語", "資格取得", "ボードゲーム", "ドライブ", "釣り",
    ]
    return random.sample(pool, k=random.randint(3, 7))


# ============================================================
# Seed reports
# ============================================================
def seed_reports(user_ids, count):
    print(f"\n🚨 Seeding {count} reports...")
    reasons = ["inappropriate", "spam", "harassment", "fake", "underage", "other"]
    statuses_list = ["pending"] * 4 + ["reviewing"] * 2 + ["resolved"] * 2 + ["dismissed"]
    descriptions = [
        "不適切な画像が掲載されていました",
        "勧誘のメッセージが繰り返し送られてきました",
        "プロフィール写真が他人の写真です",
        "年齢が実際と異なる可能性があります",
        "会話で侮辱的な言葉を受けました",
        "ビジネス勧誘の誘導があります",
        "連絡先を執拗に要求されました",
        "なりすましの疑いがあります",
    ]
    batch = db.batch()
    for i in range(count):
        reporter = random.choice(user_ids)
        target = random.choice(user_ids)
        while target == reporter:
            target = random.choice(user_ids)
        report_id = f"rpt_{i:04d}"
        doc_ref = db.collection("reports").document(report_id)
        batch.set(doc_ref, {
            "reporter_id": reporter[0],
            "reporter_name": reporter[1],
            "target_user_id": target[0],
            "target_user_name": target[1],
            "reason": random.choice(reasons),
            "description": random.choice(descriptions),
            "created_at": now_utc() - timedelta(hours=random.randint(1, 720)),
            "status": random.choice(statuses_list),
            "is_seed_data": True,
        })
    batch.commit()
    print(f"✅ Seeded {count} reports")


# ============================================================
# Seed transactions
# ============================================================
def seed_transactions(user_ids, count):
    print(f"\n💰 Seeding {count} transactions...")
    plans = {
        "allCategory": 4800,
        "singleCategory": 1980,
        "boost": 500,
        "freeTrial": 0,
    }
    plan_weights = [0.30, 0.30, 0.30, 0.10]
    plan_keys = list(plans.keys())
    statuses = ["completed"] * 7 + ["refunded"] + ["failed"] + ["pending"]
    payment_methods = ["applePay", "googlePay"]

    batch = db.batch()
    for i in range(count):
        user = random.choice(user_ids)
        plan_type = random.choices(plan_keys, weights=plan_weights, k=1)[0]
        tx_id = f"tx_{i:06d}"
        doc_ref = db.collection("transactions").document(tx_id)
        batch.set(doc_ref, {
            "date": now_utc() - timedelta(hours=random.randint(1, 90 * 24)),
            "user_id": user[0],
            "user_name": user[1],
            "plan_type": plan_type,
            "amount_jpy": plans[plan_type],
            "payment_method": random.choice(payment_methods),
            "status": random.choice(statuses),
            "selected_category": pick_category() if plan_type == "singleCategory" else None,
            "is_seed_data": True,
        })
    batch.commit()
    print(f"✅ Seeded {count} transactions")


# ============================================================
# Seed AI moderation flags
# ============================================================
def seed_ai_flags(user_ids, count):
    print(f"\n🤖 Seeding {count} AI flags...")
    samples = [
        {
            "category": "moneyRequest", "severity": "critical", "source": "message",
            "content": "実は今、生活費が足りなくて困っています。少しだけお金を貸してもらえませんか？",
            "keywords": ["お金を貸して", "生活費が足りなくて"],
            "reasoning": "金銭の貸借を直接要求している文脈を検出。詐欺リスクが高い。",
            "confidence": 0.94,
        },
        {
            "category": "contactExchange", "severity": "medium", "source": "message",
            "content": "よかったら LINE 交換しませんか？ID は abc_user_jp1234 です。",
            "keywords": ["LINE 交換", "abc_user_jp1234"],
            "reasoning": "外部連絡手段の直接的な交換誘導を検出。",
            "confidence": 0.88,
        },
        {
            "category": "selfHarm", "severity": "critical", "source": "profile",
            "content": "もう疲れました。誰かに会えなかったら本当に終わりにしようと思っています。",
            "keywords": ["終わりに", "本当に終わり"],
            "reasoning": "自傷・自殺念慮を示唆する表現を検出。即時のケア対応が必要。",
            "confidence": 0.91,
        },
        {
            "category": "impersonation", "severity": "high", "source": "photo",
            "content": "プロフィール写真3枚のうち2枚が、別アカウントと同一画像",
            "keywords": ["画像ハッシュ一致"],
            "reasoning": "他ユーザーのプロフィール画像と完全一致 (perceptual hash 距離 = 0)。",
            "confidence": 0.96,
        },
        {
            "category": "spamCommercial", "severity": "high", "source": "message",
            "content": "初心者でも月30万円稼げる副業の案内中！LINEで詳細をお伝えします。",
            "keywords": ["月30万円", "副業の案内", "稼げる"],
            "reasoning": "不労収入を謳う典型的な投資勧誘・MLM 系スパムパターンを検出。",
            "confidence": 0.97,
        },
        {
            "category": "harassment", "severity": "high", "source": "message",
            "content": "返事しないとか何様だよ。お前みたいなのは誰にも相手にされないだろ。",
            "keywords": ["何様", "誰にも相手にされない"],
            "reasoning": "相手を侮辱・威圧する暴言を検出。明確なハラスメントに該当。",
            "confidence": 0.89,
        },
        {
            "category": "minorRisk", "severity": "critical", "source": "profile",
            "content": "プロフィールで「実は今17歳の高2です♪」と記載されている",
            "keywords": ["17歳", "高2"],
            "reasoning": "登録年齢と自己申告内容に矛盾。本人が未成年と自己申告。",
            "confidence": 0.93,
        },
        {
            "category": "illegalSubstance", "severity": "critical", "source": "message",
            "content": "気分上がる白いやつ、安く譲りますよ。",
            "keywords": ["白いやつ"],
            "reasoning": "違法薬物の隠語パターンと取引示唆を同時に検出。",
            "confidence": 0.92,
        },
        {
            "category": "sexualContent", "severity": "medium", "source": "message",
            "content": "今夜会えませんか？大人な時間を一緒に過ごしましょう。",
            "keywords": ["大人な時間"],
            "reasoning": "性的な誘いを含む表現を検出。",
            "confidence": 0.78,
        },
        {
            "category": "hateSpeech", "severity": "high", "source": "profile",
            "content": "○○県民は本当に最低。あんなところの出身者とは関わりたくない。",
            "keywords": ["県民", "最低"],
            "reasoning": "特定の出身地・属性に対する差別表現を検出。",
            "confidence": 0.85,
        },
        {
            "category": "moneyRequest", "severity": "high", "source": "message",
            "content": "今度会う前に、入金確認の意味で 5000円だけ振り込んでもらえる？",
            "keywords": ["振り込んで", "入金確認"],
            "reasoning": "会う前の振込要求は典型的な詐欺パターン。",
            "confidence": 0.91,
        },
        {
            "category": "contactExchange", "severity": "low", "source": "username",
            "content": "表示名: \"サクラ★公式LINEあり💖\"",
            "keywords": ["公式LINEあり"],
            "reasoning": "表示名に外部誘導文言を含む。",
            "confidence": 0.72,
        },
    ]

    statuses = ["pending"] * 6 + ["underReview"] * 3 + ["confirmed"] * 2 + ["falsePositive"]

    batch = db.batch()
    for i in range(min(count, len(samples))):
        s = samples[i]
        target = random.choice(user_ids)
        flag_id = f"AIF-{i + 1:05d}"
        doc_ref = db.collection("ai_flags").document(flag_id)
        status = random.choice(statuses)
        batch.set(doc_ref, {
            "detected_at": now_utc() - timedelta(
                hours=random.randint(0, 48),
                minutes=random.randint(0, 59),
            ),
            "source": s["source"],
            "category": s["category"],
            "severity": s["severity"],
            "confidence": s["confidence"],
            "target_user_id": target[0],
            "target_user_name": target[1],
            "target_user_avatar": f"https://i.pravatar.cc/100?u={target[0]}",
            "content": s["content"],
            "matched_keywords": s["keywords"],
            "ai_reasoning": s["reasoning"],
            "status": status,
            "applied_enforcement": "warning" if status == "confirmed" else None,
            "reviewer_note": None,
            "reviewed_at": now_utc() - timedelta(hours=2) if status == "confirmed" else None,
            "related_report_id": None,
            "is_seed_data": True,
        })
    batch.commit()
    print(f"✅ Seeded {count} AI flags")


# ============================================================
# Main
# ============================================================
def main():
    clear = "--clear" in sys.argv
    if clear:
        print("⚠️  --clear option specified. Will delete existing data first.\n")
        for collection in ["users", "reports", "transactions", "ai_flags", "announcements"]:
            clear_collection(collection)

    user_ids = seed_users(SEED_USER_COUNT)
    seed_reports(user_ids, SEED_REPORT_COUNT)
    seed_transactions(user_ids, SEED_TRANSACTION_COUNT)
    seed_ai_flags(user_ids, SEED_AI_FLAG_COUNT)

    print("\n" + "=" * 60)
    print("🎉 Firestore seeding completed!")
    print(f"   📊 {SEED_USER_COUNT} users")
    print(f"   🚨 {SEED_REPORT_COUNT} reports")
    print(f"   💰 {SEED_TRANSACTION_COUNT} transactions")
    print(f"   🤖 {SEED_AI_FLAG_COUNT} AI flags")
    print("=" * 60)
    print("\n💡 Open the Firebase Console to verify:")
    print("   https://console.firebase.google.com/project/tsunagu-ai-community/firestore")


if __name__ == "__main__":
    main()
