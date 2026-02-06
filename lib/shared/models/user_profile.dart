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
