class UserProfile {
  final String id;
  final String displayName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final int totalXp;
  final int level;
  final bool isPremium;
  final bool isPublic;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.displayName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.totalXp = 0,
    this.level = 1,
    this.isPremium = false,
    this.isPublic = true,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    int? totalXp,
    int? level,
    bool? isPremium,
    bool? isPublic,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      isPremium: isPremium ?? this.isPremium,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'totalXp': totalXp,
      'level': level,
      'isPremium': isPremium,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      isPremium: json['isPremium'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Demo user for development
  static UserProfile get demo => UserProfile(
        id: 'demo-user-1',
        displayName: 'Jide',
        username: 'jide_travels',
        bio: 'Explorer & adventure seeker',
        totalXp: 1250,
        level: 8,
        createdAt: DateTime(2025, 1, 1),
      );
}
