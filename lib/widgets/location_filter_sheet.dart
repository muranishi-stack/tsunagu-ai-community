import 'package:flutter/material.dart';
import '../data/japan_locations.dart';
import '../services/user_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/distance_util.dart';

/// 都道府県・沿線フィルター ボトムシート
class LocationFilterSheet extends StatefulWidget {
  const LocationFilterSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const LocationFilterSheet(),
    );
  }

  @override
  State<LocationFilterSheet> createState() => _LocationFilterSheetState();
}

class _LocationFilterSheetState extends State<LocationFilterSheet> {
  final _prefs = UserPreferences();
  String? _tempPrefecture;
  String? _tempTrainLine;
  double? _tempMaxDistanceKm;

  @override
  void initState() {
    super.initState();
    _tempPrefecture = _prefs.filterPrefecture;
    _tempTrainLine = _prefs.filterTrainLine;
    _tempMaxDistanceKm = _prefs.filterMaxDistanceKm;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(height: 1, width: 16, color: AppTheme.vermillion),
                  const SizedBox(width: 12),
                  const Text(
                    'LOCATION FILTER',
                    style: TextStyle(
                      color: AppTheme.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempPrefecture = null;
                        _tempTrainLine = null;
                        _tempMaxDistanceKm = null;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                    ),
                    child: const Text(
                      'クリア',
                      style: TextStyle(
                        color: AppTheme.vermillion,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDistanceSection(),
                    const SizedBox(height: 28),
                    _buildPrefectureSection(),
                    if (_tempPrefecture != null &&
                        JapanLocations.hasTrainLineData(_tempPrefecture!)) ...[
                      const SizedBox(height: 24),
                      _buildTrainLineSection(),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Action button (fixed at bottom)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: const BoxDecoration(
                color: AppTheme.white,
                border: Border(
                    top: BorderSide(color: AppTheme.paleGrey, width: 0.5)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _prefs.setFilterPrefecture(_tempPrefecture);
                    _prefs.setFilterTrainLine(_tempTrainLine);
                    _prefs.setFilterMaxDistanceKm(_tempMaxDistanceKm);
                    Navigator.pop(context, true);
                  },
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
                    '適用',
                    style: TextStyle(
                      letterSpacing: 3.0,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 距離フィルター UI (5/10/25/50/100/∞ km プリセット)
  Widget _buildDistanceSection() {
    final hasMyLocation =
        _prefs.myLatitude != null && _prefs.myLongitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '距離',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.charcoal,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            if (_tempMaxDistanceKm != null)
              Text(
                '${_tempMaxDistanceKm!.toInt()}km 以内',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.vermillion,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              )
            else
              const Text(
                '無制限',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.grey,
                  letterSpacing: 1.0,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (!hasMyLocation)
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              '現在地が未取得です。アプリ再起動で自動取得します',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.grey,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DistancePresets.options.map((km) {
            final label = km == null ? '∞' : '${km.toInt()}km';
            final selected = _tempMaxDistanceKm == km;
            return _buildChip(
              label: label,
              selected: selected,
              onTap: () {
                setState(() {
                  _tempMaxDistanceKm = km;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrefectureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '都道府県',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.charcoal,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        // 「すべて」チップ
        _buildChip(
          label: 'すべて',
          selected: _tempPrefecture == null,
          onTap: () {
            setState(() {
              _tempPrefecture = null;
              _tempTrainLine = null;
            });
          },
        ),
        const SizedBox(height: 16),
        // 地方別グループ
        ...JapanLocations.prefecturesByRegion.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.grey,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.value.map((pref) {
                    return _buildChip(
                      label: pref,
                      selected: _tempPrefecture == pref,
                      onTap: () {
                        setState(() {
                          _tempPrefecture = pref;
                          _tempTrainLine = null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrainLineSection() {
    final lines = JapanLocations.getTrainLines(_tempPrefecture!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '沿線',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.charcoal,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($_tempPrefecture)',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildChip(
          label: 'すべての沿線',
          selected: _tempTrainLine == null,
          onTap: () => setState(() => _tempTrainLine = null),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: lines.map((line) {
            return _buildChip(
              label: line,
              selected: _tempTrainLine == line,
              onTap: () => setState(() => _tempTrainLine = line),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.vermillion : Colors.transparent,
          border: Border.all(
            color: selected ? AppTheme.vermillion : AppTheme.paleGrey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.darkGrey,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
