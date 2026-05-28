// OnboardingScreen — プロフィール初期登録 (5ステップ)
// =====================================================
// Step 1: ニックネーム
// Step 2: 生年月日 (18歳以上必須)
// Step 3: 性別 (男性/女性/その他/回答しない)
// Step 4: 都道府県 (GPS自動 + 手動選択)
// Step 5: プロフィール写真 (最低1枚必須)
//
// Phase 1.5 - TSUNAGU
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/japan_locations.dart';
import '../../models/connection_category.dart';
import '../../models/user_profile.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _primary = Color(0xFFE63946);
  static const _totalSteps = 5;

  int _currentStep = 0;
  bool _saving = false;
  bool _saved = false; // 保存成功後はボタン無効化のまま遷移待ち
  String? _saveError;

  // Step 1: ニックネーム
  final _nameCtrl = TextEditingController();

  // Step 2: 生年月日
  DateTime? _dateOfBirth;

  // Step 3: 性別
  Gender _gender = Gender.preferNotToSay;

  // Step 4: 都道府県
  String? _prefecture;
  bool _detectingLocation = false;
  String? _locationError;

  // Step 5: 写真
  final List<_PhotoSlot> _photoSlots = List.generate(
    6,
    (i) => _PhotoSlot(slot: i),
  );

  // Step 6 (オプション): プライマリーカテゴリ
  ConnectionCategory _primaryCategory = ConnectionCategory.friend;
  final Set<ConnectionCategory> _openTo = {ConnectionCategory.friend};

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─── Validation ────────────────────────────────────────────────────────

  String? _validateNickname(String? v) {
    if (v == null || v.trim().isEmpty) return 'ニックネームを入力してください';
    final t = v.trim();
    if (t.runes.length < 3) return '3文字以上で入力してください';
    if (t.runes.length > 20) return '20文字以内で入力してください';
    // 絵文字検出 (簡易: 一般的な絵文字範囲)
    for (final r in t.runes) {
      if ((r >= 0x1F300 && r <= 0x1FAFF) ||
          (r >= 0x2600 && r <= 0x27BF) ||
          (r >= 0x1F000 && r <= 0x1F2FF)) {
        return '絵文字は使用できません';
      }
    }
    return null;
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _validateNickname(_nameCtrl.text) == null;
      case 1:
        if (_dateOfBirth == null) return false;
        final age = UserProfile.calculateAge(_dateOfBirth!);
        return age >= 18;
      case 2:
        return true; // 性別は常に選択済み (default: preferNotToSay)
      case 3:
        return _prefecture != null && _prefecture!.isNotEmpty;
      case 4:
        // 写真1枚以上 + カテゴリ選択済み
        final hasPhoto = _photoSlots.any((s) => s.hasImage);
        return hasPhoto && _openTo.isNotEmpty;
      default:
        return false;
    }
  }

  // ─── GPS位置検出 ───────────────────────────────────────────────────────

  Future<void> _detectLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationError = null;
    });
    try {
      final result = await LocationService().detectPrefecture();
      setState(() {
        _prefecture = result.prefecture;
        _detectingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('位置情報を取得しました: ${result.prefecture}')),
        );
      }
    } on LocationException catch (e) {
      setState(() {
        _detectingLocation = false;
        _locationError = e.message;
      });
    } catch (e) {
      setState(() {
        _detectingLocation = false;
        _locationError = '位置情報の取得に失敗しました';
      });
    }
  }

  // ─── 写真選択 ───────────────────────────────────────────────────────────

  Future<void> _pickPhoto(int slot) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      setState(() {
        _photoSlots[slot] = _PhotoSlot(
          slot: slot,
          bytes: bytes,
          mobileFile: kIsWeb ? null : File(xfile.path),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写真の選択に失敗しました: $e')),
        );
      }
    }
  }

  void _removePhoto(int slot) {
    setState(() => _photoSlots[slot] = _PhotoSlot(slot: slot));
  }

  // ─── 保存 ───────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    // 二重実行ガード (押下中 or 既に成功済みなら何もしない)
    if (_saving || _saved) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final svc = UserService();
      final user = svc.currentUser;
      if (user == null) {
        throw Exception('ログインしていません');
      }
      final uid = user.uid;

      // 1. 写真をStorageにアップロード
      final photoUrls = <String>[];
      for (final ps in _photoSlots) {
        if (!ps.hasImage) continue;
        String url;
        if (ps.bytes != null) {
          url = await svc.uploadProfilePhotoBytes(
            uid: uid,
            bytes: ps.bytes!,
            slot: ps.slot,
          );
        } else if (ps.mobileFile != null) {
          url = await svc.uploadProfilePhotoFile(
            uid: uid,
            file: ps.mobileFile!,
            slot: ps.slot,
          );
        } else {
          continue;
        }
        photoUrls.add(url);
      }

      if (photoUrls.isEmpty) {
        throw Exception('プロフィール写真を最低1枚アップロードしてください');
      }

      // 2. プロフィールを Firestore に保存
      final age = UserProfile.calculateAge(_dateOfBirth!);
      final profile = UserProfile(
        id: uid,
        name: _nameCtrl.text.trim(),
        age: age,
        dateOfBirth: _dateOfBirth,
        prefecture: _prefecture!,
        gender: _gender,
        photos: photoUrls,
        primaryCategory: _primaryCategory,
        openTo: _openTo.toList(),
        email: user.email ?? '',
        location: _prefecture!,
        isSeedData: false,
      );
      await svc.createProfile(profile);

      // 保存完了 → AuthGate (Firestoreリアルタイム購読) が自動的に
      // MainScreen に遷移する。ここでは _saved=true にして遷移待ち画面を出す
      if (mounted) {
        setState(() {
          _saved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを保存しました！TSUNAGUへようこそ 🎉'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      // 保存成功時は _saving を false にしない (ボタン無効のまま AuthGate の遷移を待つ)
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveError = 'プロフィール保存に失敗しました: $e';
          _saving = false; // エラー時のみ再試行できるように戻す
        });
      }
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // プログレスバー
            _buildProgressBar(),
            const SizedBox(height: 8),
            // ステップタイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'ステップ ${_currentStep + 1} / $_totalSteps',
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const Spacer(),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _currentStep--),
                      child: const Text('戻る',
                          style: TextStyle(color: Colors.black54)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ステップコンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildStepContent(),
                ),
              ),
            ),
            // エラー表示
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_saveError!,
                            style: TextStyle(
                                color: Colors.red.shade900, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            // 次へ / 完了ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isStepValid() && !_saving && !_saved)
                      ? () {
                          if (_currentStep < _totalSteps - 1) {
                            setState(() => _currentStep++);
                          } else {
                            _saveProfile();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: (_saving || _saved)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _saved ? 'TSUNAGU を起動中...' : '保存中...',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          _currentStep < _totalSteps - 1 ? '次へ' : '登録を完了する',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: i <= _currentStep ? _primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _stepNickname();
      case 1:
        return _stepDateOfBirth();
      case 2:
        return _stepGender();
      case 3:
        return _stepPrefecture();
      case 4:
        return _stepPhotosAndCategory();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: ニックネーム ───────────────────────────────────────────────

  Widget _stepNickname() {
    final err = _validateNickname(_nameCtrl.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('ニックネームを教えてください', '他のユーザーに表示される名前です'),
        const SizedBox(height: 32),
        TextField(
          controller: _nameCtrl,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: 'ニックネーム (3〜20文字)',
            hintText: 'たろう、Hanako など',
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
            errorText: _nameCtrl.text.isEmpty ? null : err,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          '※ 絵文字は使用できません',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  // ─── Step 2: 生年月日 ───────────────────────────────────────────────────

  Widget _stepDateOfBirth() {
    final age = _dateOfBirth != null
        ? UserProfile.calculateAge(_dateOfBirth!)
        : null;
    final under18 = age != null && age < 18;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('生年月日を教えてください', 'TSUNAGUは18歳以上のみご利用いただけます'),
        const SizedBox(height: 32),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initial = _dateOfBirth ??
                DateTime(now.year - 25, now.month, now.day);
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(now.year - 100),
              lastDate: DateTime(now.year - 18, now.month, now.day),
              helpText: '生年月日を選択',
              cancelText: 'キャンセル',
              confirmText: 'OK',
              builder: (ctx, child) {
                return Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: _primary),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) setState(() => _dateOfBirth = picked);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: Colors.black54),
                const SizedBox(width: 12),
                Text(
                  _dateOfBirth == null
                      ? '日付を選択する'
                      : '${_dateOfBirth!.year}年 ${_dateOfBirth!.month}月 ${_dateOfBirth!.day}日',
                  style: TextStyle(
                    fontSize: 16,
                    color: _dateOfBirth == null
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (age != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: under18 ? Colors.red.shade50 : _primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$age歳',
                      style: TextStyle(
                        color: under18 ? Colors.red : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (under18) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '申し訳ございません。TSUNAGUは18歳以上のみご利用いただけます。',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          '※ 年齢は他のユーザーに表示されます。生年月日そのものは非公開です。',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  // ─── Step 3: 性別 ───────────────────────────────────────────────────────

  Widget _stepGender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('性別を選んでください', 'プロフィール上で公開される情報です'),
        const SizedBox(height: 32),
        ..._buildGenderTile(Gender.male, '男性', Icons.male),
        ..._buildGenderTile(Gender.female, '女性', Icons.female),
        ..._buildGenderTile(Gender.other, 'その他', Icons.transgender),
        ..._buildGenderTile(
            Gender.preferNotToSay, '回答しない', Icons.visibility_off_outlined),
      ],
    );
  }

  List<Widget> _buildGenderTile(Gender g, String label, IconData icon) {
    final selected = _gender == g;
    return [
      InkWell(
        onTap: () => setState(() => _gender = g),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? _primary.withValues(alpha: 0.08) : Colors.white,
            border: Border.all(
              color: selected ? _primary : Colors.grey.shade400,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? _primary : Colors.black54),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? _primary : Colors.black87,
                ),
              ),
              const Spacer(),
              if (selected) const Icon(Icons.check_circle, color: _primary),
            ],
          ),
        ),
      ),
    ];
  }

  // ─── Step 4: 都道府県 ───────────────────────────────────────────────────

  Widget _stepPrefecture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('お住まいの都道府県は？', 'マッチング距離の計算に使用されます'),
        const SizedBox(height: 24),
        // GPS自動検出ボタン
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _detectingLocation ? null : _detectLocation,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
            ),
            icon: _detectingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_primary),
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(_detectingLocation ? '位置情報を取得中...' : 'GPSで自動取得'),
          ),
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 8),
          Text(
            _locationError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'または手動選択',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _prefecture,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: '都道府県を選ぶ',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          items: JapanLocations.allPrefectures
              .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => _prefecture = v),
        ),
        if (_prefecture != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: _primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '選択中: $_prefecture',
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Step 5: 写真 + カテゴリ ───────────────────────────────────────────

  Widget _stepPhotosAndCategory() {
    final hasPhoto = _photoSlots.any((s) => s.hasImage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepTitle('プロフィール写真とカテゴリ',
            '最低1枚の写真と、主な目的を選択してください'),
        const SizedBox(height: 24),

        // 写真グリッド (6枠)
        const Text(
          '写真 (1枚必須・最大6枚)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: 6,
          itemBuilder: (ctx, i) => _photoTile(i),
        ),
        if (!hasPhoto) ...[
          const SizedBox(height: 8),
          Text(
            '※ 最低1枚は必須です',
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
        ],

        const SizedBox(height: 32),
        const Text(
          'メインの目的',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          'TSUNAGUを使う一番の目的は？',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ConnectionCategory.values.map((c) {
            final selected = _primaryCategory == c;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.icon, size: 16,
                      color: selected ? Colors.white : Colors.black54),
                  const SizedBox(width: 6),
                  Text(c.label),
                ],
              ),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _primaryCategory = c;
                  _openTo.add(c);
                });
              },
              selectedColor: _primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        const Text(
          '他にも興味のあるカテゴリ (任意)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ConnectionCategory.values
              .where((c) => c != _primaryCategory)
              .map((c) {
            final selected = _openTo.contains(c);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.icon, size: 16,
                      color: selected ? _primary : Colors.black54),
                  const SizedBox(width: 4),
                  Text(c.label),
                ],
              ),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _openTo.add(c);
                  } else {
                    _openTo.remove(c);
                  }
                });
              },
              selectedColor: _primary.withValues(alpha: 0.15),
              checkmarkColor: _primary,
              labelStyle: TextStyle(
                color: selected ? _primary : Colors.black87,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _photoTile(int slot) {
    final ps = _photoSlots[slot];
    return InkWell(
      onTap: () => _pickPhoto(slot),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ps.hasImage ? _primary : Colors.grey.shade300,
            width: ps.hasImage ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ps.hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  ps.bytes!,
                  fit: BoxFit.cover,
                ),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: Colors.grey.shade500, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    slot == 0 ? '必須' : '任意',
                    style: TextStyle(
                      color: slot == 0 ? _primary : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (ps.hasImage)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removePhoto(slot),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            if (slot == 0 && ps.hasImage)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'メイン',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepTitle(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

/// 写真スロット (Web/Mobile両対応)
class _PhotoSlot {
  final int slot;
  final Uint8List? bytes;
  final File? mobileFile;

  _PhotoSlot({required this.slot, this.bytes, this.mobileFile});

  bool get hasImage => bytes != null;
}
