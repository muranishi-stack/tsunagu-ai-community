import 'package:flutter/material.dart';
import '../models/connection_category.dart';
import '../services/user_preferences.dart';
import '../theme/app_theme.dart';

/// プロフィールカテゴリ編集ボトムシート
/// - プライマリカテゴリ（自分の主目的）を1つ選択
/// - openTo（受け入れ可能なカテゴリ）を複数選択
class CategoryEditSheet extends StatefulWidget {
  const CategoryEditSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const CategoryEditSheet(),
    );
  }

  @override
  State<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<CategoryEditSheet> {
  final _prefs = UserPreferences();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.paleGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(height: 1, width: 16, color: AppTheme.vermillion),
              const SizedBox(width: 12),
              const Text(
                'CONNECTION CATEGORIES',
                style: TextStyle(
                  color: AppTheme.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ----- Primary -----
          const Text(
            '主な目的（1つ選択）',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.charcoal,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'あなたが最も求めている繋がりのタイプ',
            style: TextStyle(fontSize: 11, color: AppTheme.grey, height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ConnectionCategory.values.map((cat) {
              final selected = _prefs.primaryCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _prefs.setPrimaryCategory(cat);
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.vermillion : Colors.transparent,
                    border: Border.all(
                      color:
                          selected ? AppTheme.vermillion : AppTheme.paleGrey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? cat.activeIcon : cat.icon,
                        size: 14,
                        color: selected ? Colors.white : AppTheme.darkGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.label,
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.darkGrey,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          // ----- Open To -----
          const Text(
            '受け入れ可能（複数選択可）',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.charcoal,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '出会いたい繋がりのタイプを全て選んでください',
            style: TextStyle(fontSize: 11, color: AppTheme.grey, height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ConnectionCategory.values.map((cat) {
              final selected = _prefs.openTo.contains(cat);
              final isPrimary = _prefs.primaryCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _prefs.toggleOpenTo(cat);
                  });
                },
                child: Opacity(
                  opacity: isPrimary ? 0.6 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.vermillion.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppTheme.vermillion
                            : AppTheme.paleGrey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? Icons.check : cat.icon,
                          size: 12,
                          color: selected
                              ? AppTheme.vermillion
                              : AppTheme.darkGrey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.vermillion
                                : AppTheme.darkGrey,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
              child: const Text(
                '保存',
                style: TextStyle(
                  letterSpacing: 3.0,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
