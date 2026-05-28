// ProfileEditScreen — Edit name, bio, prefecture, occupation, height, interests
// =====================================================
// Phase 1.6 - TSUNAGU

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../data/japan_locations.dart';
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

  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _interestsCtrl;
  late TextEditingController _educationCtrl;
  String _prefecture = '';
  Gender _gender = Gender.preferNotToSay;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _occupationCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _interestsCtrl = TextEditingController();
    _educationCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _occupationCtrl.dispose();
    _heightCtrl.dispose();
    _interestsCtrl.dispose();
    _educationCtrl.dispose();
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
      _occupationCtrl.text = p.occupation;
      _heightCtrl.text = p.height;
      _interestsCtrl.text = p.interests.join('、');
      _educationCtrl.text = p.education;
      setState(() {
        _profile = p;
        _prefecture = p.prefecture;
        _gender = p.gender;
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
      final interests = _interestsCtrl.text
          .split(RegExp(r'[、,\s]+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      final updated = p.copyWith(
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        occupation: _occupationCtrl.text.trim(),
        height: _heightCtrl.text.trim(),
        education: _educationCtrl.text.trim(),
        prefecture: _prefecture,
        gender: _gender,
        interests: interests,
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
              trailing:
                  p == _prefecture ? const Icon(Icons.check, color: AppTheme.vermillion) : null,
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
            const SizedBox(height: 28),
            _sectionTitle('プロフィール詳細'),
            const SizedBox(height: 12),
            _textField(
              controller: _occupationCtrl,
              label: '職業',
              hint: '例: エンジニア、会社員',
              maxLength: 30,
            ),
            const SizedBox(height: 16),
            _textField(
              controller: _educationCtrl,
              label: '学歴',
              hint: '例: ○○大学',
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            _textField(
              controller: _heightCtrl,
              label: '身長',
              hint: '例: 170cm',
              maxLength: 10,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            _textField(
              controller: _interestsCtrl,
              label: '興味・趣味',
              hint: '例: 映画、キャンプ、料理（カンマか読点で区切る）',
              maxLines: 2,
              maxLength: 200,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

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
}
