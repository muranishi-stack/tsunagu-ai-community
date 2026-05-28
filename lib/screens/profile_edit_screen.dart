// ProfileEditScreen — タップ選択式プロフィール編集（Phase 1.11）
// =====================================================
// AI マッチングの精度を高めるため、ライフスタイル/価値観を
// 全てタップで選択できるように再構築。
//
// Phase 1.11 - TSUNAGU

import 'package:flutter/material.dart';
import '../data/japan_locations.dart';
import '../data/profile_options.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _svc = UserService();
  final _formKey = GlobalKey<FormState>();

  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // テキスト系
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;

  // 選択系
  String _prefecture = '';
  Gender _gender = Gender.preferNotToSay;
  String? _jobCategory;
  EducationLevel _educationLevel = EducationLevel.unspecified;
  int? _heightCm;
  List<String> _interests = [];
  DrinkingHabit _drinking = DrinkingHabit.unspecified;
  SmokingHabit _smoking = SmokingHabit.unspecified;
  HolidayStyle _holidayStyle = HolidayStyle.unspecified;
  List<String> _holidayActivities = [];
  String? _mbti;
  List<String> _languages = [];
  ChildrenPlan _childrenPlan = ChildrenPlan.unspecified;
  MarriageView _marriageView = MarriageView.unspecified;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await _svc.getCurrentUserProfile();
      if (!mounted) return;
      if (p == null) {
        setState(() {
          _error = 'プロフィールが見つかりません';
          _loading = false;
        });
        return;
      }
      _nameCtrl.text = p.name;
      _bioCtrl.text = p.bio;
      setState(() {
        _profile = p;
        _prefecture = p.prefecture;
        _gender = p.gender;
        _jobCategory = p.jobCategory;
        _educationLevel = p.educationLevel;
        _heightCm = p.heightCm;
        _interests = List.from(p.interests);
        _drinking = p.drinking;
        _smoking = p.smoking;
        _holidayStyle = p.holidayStyle;
        _holidayActivities = List.from(p.holidayActivities);
        _mbti = p.mbti;
        _languages = List.from(p.languages);
        _childrenPlan = p.childrenPlan;
        _marriageView = p.marriageView;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '読込エラー: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_prefecture.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('都道府県を選択してください')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final p = _profile!;
      final updated = p.copyWith(
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        prefecture: _prefecture,
        gender: _gender,
        // ライフスタイル
        jobCategory: _jobCategory,
        occupation: _jobCategory ?? p.occupation,
        educationLevel: _educationLevel,
        education: _educationLevel == EducationLevel.unspecified
            ? p.education
            : _educationLevel.label,
        heightCm: _heightCm,
        height: _heightCm == null ? p.height : '${_heightCm}cm',
        interests: _interests,
        drinking: _drinking,
        smoking: _smoking,
        holidayStyle: _holidayStyle,
        holidayActivities: _holidayActivities,
        mbti: _mbti,
        languages: _languages,
        childrenPlan: _childrenPlan,
        marriageView: _marriageView,
        updatedAt: DateTime.now(),
      );
      await _svc.updateProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを更新しました')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  void _selectPrefecture() async {
    final prefs = JapanLocations.allPrefectures;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          itemCount: prefs.length,
          itemBuilder: (_, i) {
            final p = prefs[i];
            return ListTile(
              title: Text(p),
              trailing: p == _prefecture
                  ? const Icon(Icons.check, color: AppTheme.vermillion)
                  : null,
              onTap: () => Navigator.pop(ctx, p),
            );
          },
        ),
      ),
    );
    if (selected != null) {
      setState(() => _prefecture = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集',
            style: TextStyle(fontSize: 16, letterSpacing: 2)),
        actions: [
          if (!_loading && _error == null)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.vermillion),
                      ),
                    )
                  : const Text('保存',
                      style: TextStyle(
                          color: AppTheme.vermillion,
                          fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 基本情報 ───
            _sectionTitle('基本情報'),
            const SizedBox(height: 12),
            _textField(
              controller: _nameCtrl,
              label: 'ニックネーム *',
              hint: '3〜20文字',
              maxLength: 20,
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.length < 3 || s.length > 20) {
                  return '3〜20文字で入力してください';
                }
                final emojiRegex = RegExp(
                    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}]',
                    unicode: true);
                if (emojiRegex.hasMatch(s)) {
                  return '絵文字は使えません';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _genderSelector(),
            const SizedBox(height: 16),
            _prefectureSelector(),

            // ─── 自己紹介 ───
            const SizedBox(height: 28),
            _sectionTitle('自己紹介'),
            const SizedBox(height: 12),
            _textField(
              controller: _bioCtrl,
              label: '自己紹介',
              hint: 'あなたの魅力や趣味を教えてください',
              maxLines: 5,
              maxLength: 300,
            ),

            // ─── 仕事・学歴 ───
            const SizedBox(height: 28),
            _sectionTitle('仕事 & 学歴'),
            const SizedBox(height: 12),
            _singleChoiceField(
              label: '職業カテゴリ',
              value: _jobCategory,
              options: JobCategories.all,
              onTap: () async {
                final v = await _showSingleChoiceSheet(
                  '職業カテゴリ',
                  JobCategories.all,
                  _jobCategory,
                );
                if (v != null) setState(() => _jobCategory = v);
              },
            ),
            const SizedBox(height: 12),
            _enumChipsField<EducationLevel>(
              label: '学歴',
              current: _educationLevel,
              options: const [
                EducationLevel.graduate,
                EducationLevel.university,
                EducationLevel.juniorCollege,
                EducationLevel.highSchool,
                EducationLevel.other,
              ],
              labelFor: (v) => v.label,
              onSelected: (v) => setState(() => _educationLevel = v),
            ),

            // ─── 身体的特徴 ───
            const SizedBox(height: 28),
            _sectionTitle('身長'),
            const SizedBox(height: 4),
            _heightSlider(),

            // ─── ライフスタイル ───
            const SizedBox(height: 28),
            _sectionTitle('ライフスタイル'),
            const SizedBox(height: 12),
            _enumChipsField<DrinkingHabit>(
              label: '飲酒',
              current: _drinking,
              options: const [
                DrinkingHabit.often,
                DrinkingHabit.sometimes,
                DrinkingHabit.no,
              ],
              labelFor: (v) => v.label,
              onSelected: (v) => setState(() => _drinking = v),
            ),
            const SizedBox(height: 12),
            _enumChipsField<SmokingHabit>(
              label: '喫煙',
              current: _smoking,
              options: const [
                SmokingHabit.yes,
                SmokingHabit.electronic,
                SmokingHabit.no,
              ],
              labelFor: (v) => v.label,
              onSelected: (v) => setState(() => _smoking = v),
            ),
            const SizedBox(height: 12),
            _enumChipsField<HolidayStyle>(
              label: '休日の過ごし方',
              current: _holidayStyle,
              options: const [
                HolidayStyle.indoor,
                HolidayStyle.outdoor,
                HolidayStyle.both,
              ],
              labelFor: (v) => v.label,
              onSelected: (v) => setState(() => _holidayStyle = v),
            ),
            const SizedBox(height: 12),
            _multiSelectChipsField(
              label: '休日のアクティビティ',
              all: HolidayActivities.all,
              selected: _holidayActivities,
              onChanged: (list) => setState(() => _holidayActivities = list),
            ),

            // ─── 性格・言語 ───
            const SizedBox(height: 28),
            _sectionTitle('性格 & 言語'),
            const SizedBox(height: 12),
            _singleChoiceField(
              label: 'MBTI',
              value: _mbti == null ? null : MbtiTypes.labelFor(_mbti),
              options: MbtiTypes.all
                  .map((t) => '$t (${MbtiTypes.labelMap[t] ?? ''})')
                  .toList(),
              onTap: () async {
                final labels = MbtiTypes.all
                    .map((t) => '$t (${MbtiTypes.labelMap[t] ?? ''})')
                    .toList();
                final current =
                    _mbti == null ? null : MbtiTypes.labelFor(_mbti);
                final selectedLabel = await _showSingleChoiceSheet(
                  'MBTI',
                  labels,
                  current,
                );
                if (selectedLabel != null) {
                  final type = selectedLabel.split(' ').first;
                  setState(() => _mbti = type);
                }
              },
            ),
            const SizedBox(height: 12),
            _multiSelectChipsField(
              label: '話せる言語',
              all: Languages.all,
              selected: _languages,
              onChanged: (list) => setState(() => _languages = list),
            ),

            // ─── 価値観 ───
            const SizedBox(height: 28),
            _sectionTitle('価値観'),
            const SizedBox(height: 12),
            _enumChipsField<ChildrenPlan>(
              label: '子供の希望',
              current: _childrenPlan,
              options: const [
                ChildrenPlan.want,
                ChildrenPlan.either,
                ChildrenPlan.notWant,
                ChildrenPlan.undecided,
              ],
              labelFor: (v) => v.label,
              onSelected: (v) => setState(() => _childrenPlan = v),
            ),
            const SizedBox(height: 12),
            _enumChipsField<MarriageView>(
              label: '結婚観',
              current: _marriageView,
              options: const [
                MarriageView.asap,
                MarriageView.someday,
                MarriageView.notInterested,
                MarriageView.undecided,
              ],
              labelFor: (v) => v.label,
              onSelected: (v) => setState(() => _marriageView = v),
            ),

            // ─── 興味 ───
            const SizedBox(height: 28),
            _sectionTitle('興味・趣味'),
            const SizedBox(height: 8),
            _interestsField(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── 共通 UI コンポーネント ───────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: AppTheme.vermillion,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _genderSelector() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '性別',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Wrap(
        spacing: 8,
        children: Gender.values.map((g) {
          final selected = _gender == g;
          return ChoiceChip(
            label: Text(g.label),
            selected: selected,
            onSelected: (_) => setState(() => _gender = g),
            selectedColor: AppTheme.vermillion,
            labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
          );
        }).toList(),
      ),
    );
  }

  Widget _prefectureSelector() {
    return InkWell(
      onTap: _selectPrefecture,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '都道府県 *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _prefecture.isEmpty ? '選択してください' : _prefecture,
          style: TextStyle(
              fontSize: 15,
              color: _prefecture.isEmpty
                  ? Theme.of(context).hintColor
                  : Theme.of(context).textTheme.bodyLarge?.color),
        ),
      ),
    );
  }

  /// enum 用 ChoiceChip フィールド (3〜6 個程度の選択肢向け)
  Widget _enumChipsField<T>({
    required String label,
    required T current,
    required List<T> options,
    required String Function(T) labelFor,
    required ValueChanged<T> onSelected,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: options.map((opt) {
          final selected = current == opt;
          return ChoiceChip(
            label: Text(labelFor(opt)),
            selected: selected,
            onSelected: (_) => onSelected(opt),
            selectedColor: AppTheme.vermillion,
            labelStyle: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 選択肢が多い場合のリスト式単一選択フィールド
  Widget _singleChoiceField({
    required String label,
    required String? value,
    required List<String> options,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value == null || value.isEmpty ? '選択してください' : value,
          style: TextStyle(
            fontSize: 15,
            color: (value == null || value.isEmpty)
                ? Theme.of(context).hintColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Future<String?> _showSingleChoiceSheet(
    String title,
    List<String> options,
    String? current,
  ) async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            ...options.map((o) => ListTile(
                  title: Text(o),
                  trailing: o == current
                      ? const Icon(Icons.check, color: AppTheme.vermillion)
                      : null,
                  onTap: () => Navigator.pop(ctx, o),
                )),
          ],
        ),
      ),
    );
  }

  /// 複数選択 ChoiceChip フィールド
  Widget _multiSelectChipsField({
    required String label,
    required List<String> all,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '$label (${selected.length})',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: all.map((opt) {
          final isSel = selected.contains(opt);
          return FilterChip(
            label: Text(opt),
            selected: isSel,
            onSelected: (_) {
              final next = List<String>.from(selected);
              if (isSel) {
                next.remove(opt);
              } else {
                next.add(opt);
              }
              onChanged(next);
            },
            selectedColor: AppTheme.vermillion,
            labelStyle: TextStyle(
              color: isSel ? Colors.white : null,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 身長スライダー (140〜200cm)
  Widget _heightSlider() {
    final cm = _heightCm ?? 165;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              HeightOptions.labelFor(_heightCm),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _heightCm == null ? Colors.grey : AppTheme.vermillion,
              ),
            ),
            const Spacer(),
            if (_heightCm != null)
              TextButton(
                onPressed: () => setState(() => _heightCm = null),
                child: const Text('クリア',
                    style: TextStyle(fontSize: 11, color: AppTheme.grey)),
              ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.vermillion,
            thumbColor: AppTheme.vermillion,
            overlayColor: AppTheme.vermillion.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: cm.toDouble(),
            min: HeightOptions.min.toDouble(),
            max: HeightOptions.max.toDouble(),
            divisions: HeightOptions.max - HeightOptions.min,
            label: '${cm}cm',
            onChanged: (v) => setState(() => _heightCm = v.round()),
          ),
        ),
      ],
    );
  }

  /// 興味・趣味タグ (既存の interests を流用、+ 押下で追加)
  Widget _interestsField() {
    // よく使われる興味タグ候補（カテゴリ別の代表選択肢）
    const popular = [
      '映画', '音楽', 'カフェ', '料理', '旅行', '読書', 'カメラ', 'ファッション',
      'スポーツ', 'ジム', 'ヨガ', 'ランニング', 'アウトドア', 'キャンプ',
      'ゲーム', 'アニメ', 'マンガ', 'アート', '美術館', 'ライブ', 'フェス',
      'ワイン', 'コーヒー', 'スイーツ', 'グルメ', 'ペット', '猫', '犬',
      'テクノロジー', 'プログラミング', 'ビジネス', '投資', '学び', '英語',
    ];
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '興味・趣味 (${_interests.length})',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: popular.map((tag) {
          final isSel = _interests.contains(tag);
          return FilterChip(
            label: Text(tag),
            selected: isSel,
            onSelected: (_) {
              setState(() {
                if (isSel) {
                  _interests.remove(tag);
                } else {
                  _interests.add(tag);
                }
              });
            },
            selectedColor: AppTheme.vermillion,
            labelStyle: TextStyle(
              color: isSel ? Colors.white : null,
              fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
            ),
          );
        }).toList(),
      ),
    );
  }
}
