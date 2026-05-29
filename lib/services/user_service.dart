// UserService — Frontend Firebase integration hub
// =====================================================
// Auth + Firestore (users / swipes / matches / chats) + Storage (profile photos)
// Singleton pattern, matches existing AdminService/FirestoreService convention.
//
// Phase 1.5 - TSUNAGU
// Created: 2025

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/connection_category.dart';
import '../models/user_profile.dart';

class UserService {
  // ─── Singleton ─────────────────────────────────────────────────────────
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Collection refs ───────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _swipes =>
      _db.collection('swipes');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');
  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  // ─── Current user shortcuts ────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ═══════════════════════════════════════════════════════════════════════
  // AUTHENTICATION
  // ═══════════════════════════════════════════════════════════════════════

  /// 新規登録 (email + password)
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred;
  }

  /// ログイン
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred;
  }

  /// ログアウト（GoogleもFirebaseも両方ログアウト）
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Googleにサインインしていない場合は無視
    }
    await _auth.signOut();
  }

  /// パスワードリセットメール送信
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ═══════════════════════════════════════════════════════════════════════
  // SAFETY (通報・ブロック)
  // ═══════════════════════════════════════════════════════════════════════

  /// ユーザーを通報する。`reports` コレクションへ書き込み、管理コンソールが
  /// 確認・対応する。
  Future<void> submitReport({
    required String targetUserId,
    required String targetUserName,
    required String reason,
    String description = '',
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('ログインが必要です');
    }
    String reporterName = '';
    try {
      reporterName = (await getProfile(uid))?.name ?? '';
    } catch (_) {}
    await _reports.add({
      'reporter_id': uid,
      'reporter_name': reporterName,
      'target_user_id': targetUserId,
      'target_user_name': targetUserName,
      'reason': reason,
      'description': description,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// ユーザーをブロックする。自分の user doc の `blocked_uids` に追加する。
  /// DISCOVER 等の一覧はこのリストを除外して表示する。
  Future<void> blockUser(String targetUserId) async {
    final uid = currentUid;
    if (uid == null) return;
    await _users.doc(uid).set({
      'blocked_uids': FieldValue.arrayUnion([targetUserId]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 自分がブロックしたユーザー UID 一覧を取得
  Future<Set<String>> getBlockedUids() async {
    final uid = currentUid;
    if (uid == null) return {};
    try {
      final doc = await _users.doc(uid).get();
      final list = (doc.data()?['blocked_uids'] as List?) ?? const [];
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  /// Googleアカウントでサインイン
  /// プラットフォームに応じて適切な認証フローを使用
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Firebase Auth の signInWithPopup
        final googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Android/iOS: google_sign_in パッケージを使用
        final googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // ユーザーがキャンセル
          return null;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: 'Googleログインに失敗しました: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROFILE CRUD
  // ═══════════════════════════════════════════════════════════════════════

  /// プロフィールが存在するかチェック (オンボーディング判定用)
  Future<bool> hasProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data();
    if (data == null) return false;
    // photos が空 or name が空ならまだオンボーディング未完了
    final name = data['name'] as String?;
    final photos = (data['photos'] as List?) ?? const [];
    return (name != null && name.isNotEmpty) && photos.isNotEmpty;
  }

  /// 指定UIDのプロフィール取得
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return UserProfile.fromFirestore(doc.id, data);
  }

  /// 現在ログイン中のユーザーのプロフィール取得
  Future<UserProfile?> getCurrentUserProfile() async {
    final uid = currentUid;
    if (uid == null) return null;
    return getProfile(uid);
  }

  /// 現在ログイン中のユーザーのプロフィールをリアルタイム監視
  Stream<UserProfile?> watchCurrentUserProfile() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _users.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return UserProfile.fromFirestore(snap.id, data);
    });
  }

  /// プロフィール作成 (オンボーディング完了時)
  Future<void> createProfile(UserProfile profile) async {
    final data = profile.toFirestore();
    // 新規作成時は created_at もセット
    data['created_at'] = FieldValue.serverTimestamp();
    await _users.doc(profile.id).set(data, SetOptions(merge: true));
  }

  /// プロフィール更新
  Future<void> updateProfile(UserProfile profile) async {
    final data = profile.toFirestore();
    // 更新時は created_at は触らない
    data.remove('created_at');
    await _users.doc(profile.id).set(data, SetOptions(merge: true));
  }

  /// 最終アクティブ時刻を更新 (アプリ起動時など)
  Future<void> touchLastActive() async {
    final uid = currentUid;
    if (uid == null) return;
    await _users.doc(uid).set({
      'last_active_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 現在地（lat/lng）を Firestore に保存
  /// 起動毎の自動更新 or プロフィール画面の「更新」ボタンから呼ばれる
  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
    String? prefecture,
  }) async {
    final uid = currentUid;
    if (uid == null) return;
    final data = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'location_updated_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (prefecture != null && prefecture.isNotEmpty) {
      data['prefecture'] = prefecture;
    }
    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISCOVER (スワイプ用ユーザー取得)
  // ═══════════════════════════════════════════════════════════════════════

  /// Seedデータを除外するかどうかのフラグ
  /// - dart-define で `INCLUDE_SEED_DATA=false` を渡せば本番モードで除外
  /// - デフォルト (未指定) は true → 開発/プレビュー/本番すべてで Seed を表示
  /// - 本番リリース時は `flutter build web --release --dart-define=INCLUDE_SEED_DATA=false` で除外可能
  static const bool _includeSeedData = bool.fromEnvironment(
    'INCLUDE_SEED_DATA',
    defaultValue: true,
  );

  /// スワイプ画面用のユーザー一覧取得
  ///
  /// - 自分自身は除外
  /// - INCLUDE_SEED_DATA=false の場合は is_seed_data=true を除外
  /// - すでにスワイプ済みのユーザーも除外 (excludeUids)
  Future<List<UserProfile>> discoverUsers({
    required String currentUid,
    ConnectionCategory? category,
    int limit = 50,
    Set<String> excludeUids = const {},
  }) async {
    // 注意: orderBy + where の組み合わせはインデックス要求するので避ける
    // 一度取得してメモリで絞り込む
    Query<Map<String, dynamic>> query = _users.limit(limit);

    final snap = await query.get();
    final excludeAll = {...excludeUids, currentUid};

    final results = <UserProfile>[];
    for (final doc in snap.docs) {
      if (excludeAll.contains(doc.id)) continue;
      final data = doc.data();

      // is_seed_data フィルタ (本番モードでのみ除外、デフォルトは表示)
      final isSeed = (data['is_seed_data'] as bool?) ?? false;
      if (!_includeSeedData && isSeed) continue;

      // 名前と写真が無いユーザー (オンボーディング未完了) は除外
      final name = data['name'] as String?;
      final photos = (data['photos'] as List?) ?? const [];
      if (name == null || name.isEmpty || photos.isEmpty) continue;

      // status が banned/suspended のユーザーは除外
      final status = data['status'] as String?;
      if (status == 'banned' || status == 'suspended') continue;

      final profile = UserProfile.fromFirestore(doc.id, data);

      // カテゴリフィルタ (メモリ側)
      if (category != null) {
        final ok = profile.primaryCategory == category ||
            profile.openTo.contains(category);
        if (!ok) continue;
      }

      results.add(profile);
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SWIPES
  // ═══════════════════════════════════════════════════════════════════════

  /// スワイプ記録
  /// Returns: マッチ成立した場合は matchId、未成立なら null
  /// [isSuperLike] true の場合、Super Like 通知も生成
  Future<String?> recordSwipe({
    required String fromUid,
    required String toUid,
    required bool liked,
    bool isSuperLike = false,
  }) async {
    final swipeId = '${fromUid}_$toUid';
    await _swipes.doc(swipeId).set({
      'from_uid': fromUid,
      'to_uid': toUid,
      'liked': liked,
      'is_super_like': isSuperLike,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Super Like の場合、相手の通知コレクションに記録
    if (isSuperLike && liked) {
      await _db
          .collection('superlike_notifications')
          .doc('${toUid}_$fromUid')
          .set({
        'to_uid': toUid,
        'from_uid': fromUid,
        'created_at': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    // Like の場合のみ相互Like判定
    if (!liked) return null;

    final reverseSwipeId = '${toUid}_$fromUid';
    final reverse = await _swipes.doc(reverseSwipeId).get();
    if (!reverse.exists) return null;
    final reverseLiked = (reverse.data()?['liked'] as bool?) ?? false;
    if (!reverseLiked) return null;

    // 相互Like → マッチ作成
    final matchId = _matchId(fromUid, toUid);
    await _matches.doc(matchId).set({
      'uids': [fromUid, toUid]..sort(),
      'user_a': fromUid.compareTo(toUid) < 0 ? fromUid : toUid,
      'user_b': fromUid.compareTo(toUid) < 0 ? toUid : fromUid,
      'matched_at': FieldValue.serverTimestamp(),
      'is_super_like_match': isSuperLike,
      'last_message': null,
      'last_message_time': null,
      'last_message_sender': null,
      'unread_for_a': 0,
      'unread_for_b': 0,
    }, SetOptions(merge: true));

    return matchId;
  }

  /// スワイプを取り消し（Rewind機能用）
  /// 関連するマッチ・SuperLike通知も削除
  Future<void> undoSwipe({
    required String fromUid,
    required String toUid,
  }) async {
    final swipeId = '${fromUid}_$toUid';
    // Swipeレコード削除
    await _swipes.doc(swipeId).delete();
    // Matchがあれば削除
    final matchId = _matchId(fromUid, toUid);
    await _matches.doc(matchId).delete().catchError((_) {});
    // SuperLike通知があれば削除
    await _db
        .collection('superlike_notifications')
        .doc('${toUid}_$fromUid')
        .delete()
        .catchError((_) {});
  }

  /// 自分が受信したSuperLike一覧（未読のみ）
  Stream<List<Map<String, dynamic>>> watchSuperLikesReceived(String uid) {
    return _db
        .collection('superlike_notifications')
        .where('to_uid', isEqualTo: uid)
        .where('seen', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  /// SuperLike通知を既読にする
  Future<void> markSuperLikeSeen(String notificationId) async {
    await _db
        .collection('superlike_notifications')
        .doc(notificationId)
        .update({'seen': true});
  }

  /// 自分が既にスワイプしたUID一覧 (excludeUids 用)
  Future<Set<String>> getSwipedUids(String fromUid) async {
    final snap =
        await _swipes.where('from_uid', isEqualTo: fromUid).get();
    return snap.docs
        .map((d) => (d.data()['to_uid'] as String?) ?? '')
        .where((u) => u.isNotEmpty)
        .toSet();
  }

  /// 安定したmatch ID (UIDをアルファベット順に並べて結合)
  static String _matchId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// public matchId 生成ヘルパー (ChatScreen/MatchesScreen用)
  static String makeMatchId(String a, String b) => _matchId(a, b);

  // ═══════════════════════════════════════════════════════════════════════
  // MATCHES
  // ═══════════════════════════════════════════════════════════════════════

  /// 自分のマッチ一覧をリアルタイム監視
  Stream<List<Map<String, dynamic>>> watchMatches(String uid) {
    return _matches
        .where('uids', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  /// 一回限りのマッチ取得 (initStateで使う簡易版)
  Future<List<Map<String, dynamic>>> getMatches(String uid) async {
    final snap = await _matches.where('uids', arrayContains: uid).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHATS (messages サブコレクション)
  // ═══════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> messagesRef(String matchId) =>
      _chats.doc(matchId).collection('messages');

  /// チャットメッセージのリアルタイム監視 (asc=古い順)
  Stream<List<Message>> watchMessages(String matchId, String currentUid) {
    return messagesRef(matchId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              return Message.fromFirestore(d.id, d.data(), currentUid);
            }).toList());
  }

  /// メッセージ送信
  Future<void> sendMessage({
    required String matchId,
    required String senderUid,
    required String text,
    required List<String> recipientUids,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // メッセージドキュメント追加
    await messagesRef(matchId).add({
      'sender_uid': senderUid,
      'text': trimmed,
      'created_at': FieldValue.serverTimestamp(),
    });

    // マッチドキュメントの last_message を更新
    final matchSnap = await _matches.doc(matchId).get();
    if (!matchSnap.exists) return;
    final mdata = matchSnap.data();
    if (mdata == null) return;
    final userA = mdata['user_a'] as String?;
    final userB = mdata['user_b'] as String?;

    final updates = <String, dynamic>{
      'last_message': trimmed,
      'last_message_time': FieldValue.serverTimestamp(),
      'last_message_sender': senderUid,
    };
    // 相手側の未読カウントを増やす
    if (senderUid == userA) {
      updates['unread_for_b'] = FieldValue.increment(1);
    } else if (senderUid == userB) {
      updates['unread_for_a'] = FieldValue.increment(1);
    }
    await _matches.doc(matchId).update(updates);
  }

  /// 未読カウントをリセット (チャット画面を開いたとき)
  Future<void> markChatRead({
    required String matchId,
    required String currentUid,
  }) async {
    final matchSnap = await _matches.doc(matchId).get();
    if (!matchSnap.exists) return;
    final mdata = matchSnap.data();
    if (mdata == null) return;
    final userA = mdata['user_a'] as String?;
    final updates = <String, dynamic>{};
    if (currentUid == userA) {
      updates['unread_for_a'] = 0;
    } else {
      updates['unread_for_b'] = 0;
    }
    if (updates.isNotEmpty) {
      await _matches.doc(matchId).update(updates);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PHOTO UPLOAD (Firebase Storage)
  // ═══════════════════════════════════════════════════════════════════════

  /// プロフィール写真をアップロード (Web/Mobile共通)
  ///
  /// - [bytes] Web/Mobile共通で使うバイナリ
  /// - [uid] 保存先パス: profile_photos/{uid}/{slot}.jpg
  /// - [slot] 0〜5の写真スロット番号
  Future<String> uploadProfilePhotoBytes({
    required String uid,
    required Uint8List bytes,
    required int slot,
    String contentType = 'image/jpeg',
  }) async {
    // パス: users/{uid}/photos/{slot}.jpg (Storage rulesに合わせる)
    final ref = _storage
        .ref()
        .child('users')
        .child(uid)
        .child('photos')
        .child('$slot.jpg');

    final metadata = SettableMetadata(contentType: contentType);
    final task = await ref.putData(bytes, metadata);
    final url = await task.ref.getDownloadURL();
    return url;
  }

  /// モバイル用: File でアップロード
  Future<String> uploadProfilePhotoFile({
    required String uid,
    required File file,
    required int slot,
  }) async {
    final ref = _storage
        .ref()
        .child('users')
        .child(uid)
        .child('photos')
        .child('$slot.jpg');

    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final task = await ref.putFile(file, metadata);
    final url = await task.ref.getDownloadURL();
    return url;
  }

  /// プロフィール写真削除
  Future<void> deleteProfilePhoto(String uid, int slot) async {
    try {
      await _storage
          .ref()
          .child('users')
          .child(uid)
          .child('photos')
          .child('$slot.jpg')
          .delete();
    } catch (_) {
      // 元から無い場合は無視
    }
  }
}
