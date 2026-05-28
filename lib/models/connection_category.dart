import 'package:flutter/material.dart';

/// Connection categories - the multi-purpose connection types TSUNAGU supports
enum ConnectionCategory {
  romance,   // 恋愛
  friend,    // 友達
  business,  // 仕事仲間
  learning,  // 学び
  hobby,     // 趣味
}

extension ConnectionCategoryX on ConnectionCategory {
  String get label {
    switch (this) {
      case ConnectionCategory.romance:
        return '恋愛';
      case ConnectionCategory.friend:
        return '友達';
      case ConnectionCategory.business:
        return '仕事';
      case ConnectionCategory.learning:
        return '学び';
      case ConnectionCategory.hobby:
        return '趣味';
    }
  }

  String get englishLabel {
    switch (this) {
      case ConnectionCategory.romance:
        return 'ROMANCE';
      case ConnectionCategory.friend:
        return 'FRIEND';
      case ConnectionCategory.business:
        return 'BUSINESS';
      case ConnectionCategory.learning:
        return 'LEARNING';
      case ConnectionCategory.hobby:
        return 'HOBBY';
    }
  }

  String get description {
    switch (this) {
      case ConnectionCategory.romance:
        return 'パートナー・恋人を見つける';
      case ConnectionCategory.friend:
        return '気の合う友達を見つける';
      case ConnectionCategory.business:
        return 'ビジネスパートナー・仲間';
      case ConnectionCategory.learning:
        return '学習仲間・メンター';
      case ConnectionCategory.hobby:
        return '同じ趣味の仲間';
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionCategory.romance:
        return Icons.favorite_outline;
      case ConnectionCategory.friend:
        return Icons.emoji_people_outlined;
      case ConnectionCategory.business:
        return Icons.business_center_outlined;
      case ConnectionCategory.learning:
        return Icons.school_outlined;
      case ConnectionCategory.hobby:
        return Icons.palette_outlined;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case ConnectionCategory.romance:
        return Icons.favorite;
      case ConnectionCategory.friend:
        return Icons.emoji_people;
      case ConnectionCategory.business:
        return Icons.business_center;
      case ConnectionCategory.learning:
        return Icons.school;
      case ConnectionCategory.hobby:
        return Icons.palette;
    }
  }
}
