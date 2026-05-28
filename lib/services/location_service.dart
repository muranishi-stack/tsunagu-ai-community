// LocationService — GPS → 都道府県自動判定
// =====================================================
// geolocator で現在地取得 → geocoding で逆ジオコーディング → 都道府県名抽出
//
// Phase 1.5 - TSUNAGU
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final String prefecture; // 例: "東京都"
  final String? city; // 例: "新宿区"
  final double latitude;
  final double longitude;

  LocationResult({
    required this.prefecture,
    this.city,
    required this.latitude,
    required this.longitude,
  });
}

class LocationException implements Exception {
  final String message;
  final LocationErrorType type;
  LocationException(this.type, this.message);
  @override
  String toString() => 'LocationException: $message';
}

enum LocationErrorType {
  serviceDisabled, // GPS自体OFF
  permissionDenied, // ユーザーが拒否
  permissionPermanentlyDenied, // 永久拒否（設定アプリ誘導が必要）
  timeout, // 取得タイムアウト
  unknown, // その他
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// パーミッションチェック + GPS取得 + 都道府県判定 をまとめて実行
  Future<LocationResult> detectPrefecture() async {
    // 1. GPSサービスが有効か
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        LocationErrorType.serviceDisabled,
        '位置情報サービスがオフになっています。設定からONにしてください。',
      );
    }

    // 2. パーミッションリクエスト
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw LocationException(
        LocationErrorType.permissionDenied,
        '位置情報の利用が許可されていません。',
      );
    }
    if (perm == LocationPermission.deniedForever) {
      throw LocationException(
        LocationErrorType.permissionPermanentlyDenied,
        '位置情報が永久に拒否されています。設定アプリから許可してください。',
      );
    }

    // 3. 位置取得 (タイムアウト 10秒)
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      throw LocationException(
        LocationErrorType.timeout,
        '位置情報の取得に時間がかかりすぎました。',
      );
    }

    // 4. 逆ジオコーディング (Webでは未対応な場合あり)
    String prefecture = '東京都'; // フォールバック
    String? city;
    try {
      // localeを日本語に設定 (失敗しても続行)
      try {
        await setLocaleIdentifier('ja_JP');
      } catch (_) {}
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // administrativeArea = 都道府県, locality = 市区町村
        if (p.administrativeArea != null &&
            p.administrativeArea!.isNotEmpty) {
          prefecture = _normalizePrefecture(p.administrativeArea!);
        }
        city = p.locality;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Geocoding failed (using fallback prefecture): $e');
      }
      // Webでgeocoding失敗時は座標から大雑把に判定
      prefecture = _fallbackPrefectureFromLatLng(pos.latitude, pos.longitude);
    }

    return LocationResult(
      prefecture: prefecture,
      city: city,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  /// バックグラウンドGPS更新（権限プロンプトを出さない・例外を返さない）
  /// 起動時の自動更新用。既に許可されている場合のみ取得し、失敗時は null を返す。
  Future<LocationResult?> tryDetectSilently() async {
    try {
      // GPSサービスチェック (プロンプト出さない)
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // 既存パーミッションのみチェック (requestPermission しない)
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      // 位置取得 (タイムアウト短め)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // 逆ジオコーディング (任意)
      String prefecture = _fallbackPrefectureFromLatLng(
        pos.latitude,
        pos.longitude,
      );
      String? city;
      try {
        try {
          await setLocaleIdentifier('ja_JP');
        } catch (_) {}
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          if (p.administrativeArea != null &&
              p.administrativeArea!.isNotEmpty) {
            prefecture = _normalizePrefecture(p.administrativeArea!);
          }
          city = p.locality;
        }
      } catch (_) {
        // 逆ジオコーディング失敗は許容
      }

      return LocationResult(
        prefecture: prefecture,
        city: city,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Silent GPS update failed: $e');
      }
      return null;
    }
  }

  /// "Tokyo" や "東京" を "東京都" に正規化
  String _normalizePrefecture(String raw) {
    final r = raw.trim();
    // 既に "県/都/府/道" で終わっていればそのまま
    if (r.endsWith('都') ||
        r.endsWith('道') ||
        r.endsWith('府') ||
        r.endsWith('県')) {
      return r;
    }
    // 英語→日本語マッピング (主要なもののみ)
    const map = {
      'Tokyo': '東京都',
      'Osaka': '大阪府',
      'Kyoto': '京都府',
      'Hokkaido': '北海道',
      'Aichi': '愛知県',
      'Kanagawa': '神奈川県',
      'Saitama': '埼玉県',
      'Chiba': '千葉県',
      'Fukuoka': '福岡県',
      'Hyogo': '兵庫県',
    };
    if (map.containsKey(r)) return map[r]!;
    // 日本語で「東京」のような末尾欠落は補正
    if (r == '東京') return '東京都';
    if (r == '大阪') return '大阪府';
    if (r == '京都') return '京都府';
    if (r == '北海道') return '北海道';
    // 不明はそのまま返す (UI側で手動選択にfallback)
    return r;
  }

  /// 逆ジオコーディング失敗時の超大雑把なlat/lng判定
  String _fallbackPrefectureFromLatLng(double lat, double lng) {
    // 東京 (35.68, 139.69) を中心に簡易判定
    if (lat >= 35.5 && lat <= 35.9 && lng >= 139.4 && lng <= 140.0) {
      return '東京都';
    }
    if (lat >= 34.5 && lat <= 34.9 && lng >= 135.3 && lng <= 135.8) {
      return '大阪府';
    }
    if (lat >= 34.9 && lat <= 35.2 && lng >= 135.6 && lng <= 135.9) {
      return '京都府';
    }
    if (lat >= 43.0 && lat <= 43.2 && lng >= 141.2 && lng <= 141.5) {
      return '北海道';
    }
    if (lat >= 35.1 && lat <= 35.3 && lng >= 136.8 && lng <= 137.0) {
      return '愛知県';
    }
    if (lat >= 33.5 && lat <= 33.7 && lng >= 130.3 && lng <= 130.5) {
      return '福岡県';
    }
    return '東京都'; // 最終フォールバック
  }
}
