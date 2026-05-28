import 'connection_category.dart';

class UserProfile {
  final String id;
  final String name;
  final int age;
  final String location;
  final String occupation;
  final String bio;
  final List<String> interests;
  final List<String> photos;
  final int aiMatchScore;
  final String aiInsight;
  final String education;
  final String height;
  final List<ConnectionCategory> openTo;
  final ConnectionCategory primaryCategory;
  final String prefecture;       // 都道府県
  final String? trainLine;       // 主要沿線（任意）

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    required this.occupation,
    required this.bio,
    required this.interests,
    required this.photos,
    required this.aiMatchScore,
    required this.aiInsight,
    required this.education,
    required this.height,
    required this.openTo,
    required this.primaryCategory,
    required this.prefecture,
    this.trainLine,
  });
}

class Match {
  final UserProfile user;
  final DateTime matchedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool hasUnread;

  Match({
    required this.user,
    required this.matchedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.hasUnread = false,
  });
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}
