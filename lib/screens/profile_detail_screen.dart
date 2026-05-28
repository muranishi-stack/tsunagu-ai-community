import 'package:flutter/material.dart';
import '../data/profile_options.dart';
import '../models/user_profile.dart';
import '../services/user_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/distance_util.dart';

class ProfileDetailScreen extends StatelessWidget {
  final UserProfile profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: AppTheme.white,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    profile.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: AppTheme.paleGrey,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w200,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${profile.age}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(height: 1, width: 40, color: AppTheme.gold),
                        const SizedBox(height: 12),
                        Text(
                          '${profile.occupation} · ${profile.location}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIInsight(),
                  const SizedBox(height: 32),
                  _buildSection('ABOUT', profile.bio),
                  const SizedBox(height: 32),
                  _buildSectionHeader('DETAILS'),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.work_outline,
                    profile.jobCategory ?? profile.occupation,
                  ),
                  _buildDetailRow(
                    Icons.school_outlined,
                    profile.educationLevel != EducationLevel.unspecified
                        ? profile.educationLevel.label
                        : profile.education,
                  ),
                  _buildDetailRow(Icons.location_on_outlined, profile.location),
                  if (_distanceLabel() != null)
                    _buildDetailRow(
                      Icons.place_outlined,
                      'あなたから ${_distanceLabel()}',
                    ),
                  _buildDetailRow(
                    Icons.straighten,
                    profile.heightCm != null
                        ? '${profile.heightCm}cm'
                        : profile.height,
                  ),
                  if (profile.mbti != null && profile.mbti!.isNotEmpty)
                    _buildDetailRow(
                      Icons.psychology_outlined,
                      MbtiTypes.labelFor(profile.mbti),
                    ),

                  // ─── LIFESTYLE ───
                  if (_hasLifestyle()) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader('LIFESTYLE'),
                    const SizedBox(height: 16),
                    if (profile.drinking != DrinkingHabit.unspecified)
                      _buildDetailRow(
                        Icons.local_bar_outlined,
                        '飲酒: ${profile.drinking.label}',
                      ),
                    if (profile.smoking != SmokingHabit.unspecified)
                      _buildDetailRow(
                        Icons.smoke_free_outlined,
                        '喫煙: ${profile.smoking.label}',
                      ),
                    if (profile.holidayStyle != HolidayStyle.unspecified)
                      _buildDetailRow(
                        Icons.weekend_outlined,
                        '休日: ${profile.holidayStyle.label}',
                      ),
                    if (profile.holidayActivities.isNotEmpty)
                      _buildDetailRow(
                        Icons.local_activity_outlined,
                        profile.holidayActivities.join(' · '),
                      ),
                    if (profile.languages.isNotEmpty)
                      _buildDetailRow(
                        Icons.translate_outlined,
                        profile.languages.join(' · '),
                      ),
                  ],

                  // ─── VALUES ───
                  if (_hasValues()) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader('VALUES'),
                    const SizedBox(height: 16),
                    if (profile.childrenPlan != ChildrenPlan.unspecified)
                      _buildDetailRow(
                        Icons.child_care_outlined,
                        '子供: ${profile.childrenPlan.label}',
                      ),
                    if (profile.marriageView != MarriageView.unspecified)
                      _buildDetailRow(
                        Icons.favorite_border,
                        '結婚観: ${profile.marriageView.label}',
                      ),
                  ],

                  const SizedBox(height: 32),
                  _buildSectionHeader('INTERESTS'),
                  const SizedBox(height: 16),
                  _buildInterests(),
                  const SizedBox(height: 32),
                  if (profile.photos.length > 1) ...[
                    _buildSectionHeader('PHOTOS'),
                    const SizedBox(height: 16),
                    _buildPhotoGrid(),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border(top: BorderSide(color: AppTheme.paleGrey, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.black, width: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'PASS',
                  style: TextStyle(
                    color: AppTheme.black,
                    letterSpacing: 3.0,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('LIKE送信しました',
                          style: TextStyle(letterSpacing: 1.5)),
                      backgroundColor: AppTheme.black,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.black,
                  foregroundColor: AppTheme.gold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'LIKE',
                  style: TextStyle(letterSpacing: 3.0, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsight() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 14),
              const SizedBox(width: 8),
              Text(
                'AI MATCH ANALYSIS',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(),
              Text(
                '${profile.aiMatchScore}',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: AppTheme.paleGrey),
          const SizedBox(height: 12),
          Text(
            profile.aiInsight,
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 13,
              height: 1.7,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            color: AppTheme.charcoal,
            fontSize: 14,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(height: 1, width: 16, color: AppTheme.gold),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.black,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }

  /// LIFESTYLE セクションに表示する内容があるか
  bool _hasLifestyle() {
    return profile.drinking != DrinkingHabit.unspecified ||
        profile.smoking != SmokingHabit.unspecified ||
        profile.holidayStyle != HolidayStyle.unspecified ||
        profile.holidayActivities.isNotEmpty ||
        profile.languages.isNotEmpty;
  }

  /// VALUES セクションに表示する内容があるか
  bool _hasValues() {
    return profile.childrenPlan != ChildrenPlan.unspecified ||
        profile.marriageView != MarriageView.unspecified;
  }

  /// 自分との距離を表示用文字列で返す（lat/lng 両方そろっている時のみ）
  String? _distanceLabel() {
    final prefs = UserPreferences();
    final km = DistanceUtil.tryCalculateKm(
      lat1: prefs.myLatitude,
      lon1: prefs.myLongitude,
      lat2: profile.latitude,
      lon2: profile.longitude,
    );
    if (km == null) return null;
    return DistanceUtil.formatKm(km);
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.grey),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: profile.interests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.paleGrey),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            interest,
            style: const TextStyle(
              color: AppTheme.charcoal,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: profile.photos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.network(
            profile.photos[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: AppTheme.paleGrey,
            ),
          ),
        );
      },
    );
  }
}
