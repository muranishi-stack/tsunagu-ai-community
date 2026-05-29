// AiProfileOptimizeScreen — AIプロフィール最適化
// =====================================================
// 現在のプロフィールを Gemini (Cloud Function) で最適化し、
// 改善後の自己紹介・改善ポイント・追加興味候補を提示。
// 「この内容で保存」で bio を更新する。
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/ai_profile_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class AiProfileOptimizeScreen extends StatefulWidget {
  const AiProfileOptimizeScreen({super.key});

  @override
  State<AiProfileOptimizeScreen> createState() =>
      _AiProfileOptimizeScreenState();
}

class _AiProfileOptimizeScreenState extends State<AiProfileOptimizeScreen> {
  final _svc = UserService();
  final _ai = AiProfileService();

  UserProfile? _profile;
  bool _loading = true;
  bool _optimizing = false;
  bool _saving = false;
  String? _error;
  AiProfileSuggestion? _result;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _svc.getCurrentUserProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  Future<void> _optimize() async {
    final p = _profile;
    if (p == null) return;
    setState(() {
      _optimizing = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await _ai.optimize(
        name: p.name,
        age: p.age,
        occupation: p.occupation,
        bio: p.bio,
        interests: p.interests,
        primaryCategory: p.primaryCategory.name,
      );
      if (!mounted) return;
      setState(() => _result = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  Future<void> _save() async {
    final p = _profile;
    final r = _result;
    if (p == null || r == null || r.improvedBio.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _svc.updateProfile(p.copyWith(bio: r.improvedBio));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('自己紹介を更新しました')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIプロフィール最適化',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.0)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.vermillion)))
          : _profile == null
              ? const Center(child: Text('プロフィールが見つかりません'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _label('現在の自己紹介'),
                    const SizedBox(height: 8),
                    _box(_profile!.bio.isEmpty ? '(未記入)' : _profile!.bio,
                        muted: _profile!.bio.isEmpty),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _optimizing ? null : _optimize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.vermillion,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: _optimizing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_optimizing
                            ? 'AIが作成中…'
                            : (_result == null
                                ? 'AIで最適化する'
                                : 'もう一度生成する')),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                    if (_result != null) ...[
                      const SizedBox(height: 28),
                      _label('AI 改善案'),
                      const SizedBox(height: 8),
                      _box(_result!.improvedBio, highlight: true),
                      if (_result!.tips.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _label('改善ポイント'),
                        const SizedBox(height: 8),
                        ..._result!.tips.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('・',
                                      style: TextStyle(
                                          color: AppTheme.vermillion,
                                          fontWeight: FontWeight.bold)),
                                  Expanded(
                                      child: Text(t,
                                          style: const TextStyle(
                                              fontSize: 13, height: 1.6))),
                                ],
                              ),
                            )),
                      ],
                      if (_result!.suggestedInterests.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _label('追加するとよい興味'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _result!.suggestedInterests
                              .map((i) => Chip(
                                    label: Text(i,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: AppTheme.vermillion
                                        .withValues(alpha: 0.08),
                                    side: BorderSide(
                                        color: AppTheme.vermillion
                                            .withValues(alpha: 0.3)),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _save,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side:
                                const BorderSide(color: AppTheme.vermillion),
                            foregroundColor: AppTheme.vermillion,
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.vermillion))
                              : const Icon(Icons.check, size: 18),
                          label: const Text('この自己紹介で保存する'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppTheme.vermillion));

  Widget _box(String text, {bool highlight = false, bool muted = false}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight
              ? AppTheme.vermillion.withValues(alpha: 0.06)
              : AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(8),
          border: highlight
              ? Border.all(color: AppTheme.vermillion.withValues(alpha: 0.3))
              : null,
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: muted ? AppTheme.textTertiary(context) : null)),
      );
}
