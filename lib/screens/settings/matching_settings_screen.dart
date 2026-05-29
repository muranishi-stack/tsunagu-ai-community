// MatchingSettingsScreen — マッチング設定
// =====================================================
// DISCOVER のフィルタ条件（カテゴリ / 年齢 / 距離）を編集する。
// UserPreferences はメモリ保持の ChangeNotifier。変更すると
// DISCOVER 画面が自動的に再フィルタされる。
import 'package:flutter/material.dart';

import '../../models/connection_category.dart';
import '../../services/user_preferences.dart';
import '../../theme/app_theme.dart';

class MatchingSettingsScreen extends StatefulWidget {
  const MatchingSettingsScreen({super.key});

  @override
  State<MatchingSettingsScreen> createState() =>
      _MatchingSettingsScreenState();
}

class _MatchingSettingsScreenState extends State<MatchingSettingsScreen> {
  final _prefs = UserPreferences();

  static const _distancePresets = <double?>[5, 10, 25, 50, 100, null];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マッチング設定',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              _prefs.clearFilters();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('フィルタをリセットしました')),
              );
            },
            child: const Text('リセット',
                style: TextStyle(color: AppTheme.vermillion)),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _prefs,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _header('表示するカテゴリ'),
            _categoryChips(),
            const Divider(height: 32),
            _header('年齢'),
            _ageRange(),
            const Divider(height: 32),
            _header('距離'),
            _distance(),
          ],
        ),
      ),
    );
  }

  Widget _header(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppTheme.vermillion,
          ),
        ),
      );

  Widget _categoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ConnectionCategory.values.map((cat) {
          final selected = _prefs.openTo.contains(cat);
          final isPrimary = cat == _prefs.primaryCategory;
          return FilterChip(
            label: Text(cat.label),
            avatar: Icon(cat.icon,
                size: 18,
                color: selected ? Colors.white : AppTheme.textSecondary(context)),
            selected: selected,
            showCheckmark: false,
            selectedColor: AppTheme.vermillion,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
            onSelected: isPrimary
                ? null // メインカテゴリは外せない
                : (_) {
                    _prefs.toggleOpenTo(cat);
                    setState(() {});
                  },
          );
        }).toList(),
      ),
    );
  }

  Widget _ageRange() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_prefs.filterMinAge}歳',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const Text('〜', style: TextStyle(color: AppTheme.grey)),
              Text('${_prefs.filterMaxAge}歳',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ),
        RangeSlider(
          min: 18,
          max: 99,
          divisions: 81,
          activeColor: AppTheme.vermillion,
          values: RangeValues(
            _prefs.filterMinAge.toDouble(),
            _prefs.filterMaxAge.toDouble(),
          ),
          labels: RangeLabels(
            '${_prefs.filterMinAge}',
            '${_prefs.filterMaxAge}',
          ),
          onChanged: (v) {
            _prefs.setFilterAgeRange(v.start.round(), v.end.round());
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _distance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _distancePresets.map((km) {
          final selected = _prefs.filterMaxDistanceKm == km;
          final label = km == null ? '指定なし' : '${km.toInt()}km以内';
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            selectedColor: AppTheme.vermillion,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) {
              _prefs.setFilterMaxDistanceKm(km);
              setState(() {});
            },
          );
        }).toList(),
      ),
    );
  }
}
