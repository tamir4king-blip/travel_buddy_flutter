enum AchievementTier { bronze, silver, gold, platinum }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String? iconName;
  final AchievementTier tier;
  final int xpReward;
  final double? latitude;
  final double? longitude;
  final double? claimRadius;
  final String? collectionId;
  final List<String> tags;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  // Retroactive claiming fields
  final DateTime? visitDate;
  final List<String> photos;
  final String? notes;
  final bool isRetroactive;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.iconName,
    required this.tier,
    required this.xpReward,
    this.latitude,
    this.longitude,
    this.claimRadius,
    this.collectionId,
    this.tags = const [],
    this.isUnlocked = false,
    this.unlockedAt,
    this.visitDate,
    this.photos = const [],
    this.notes,
    this.isRetroactive = false,
  });

  static int xpForTier(AchievementTier tier) {
    return switch (tier) {
      AchievementTier.bronze => 10,
      AchievementTier.silver => 20,
      AchievementTier.gold => 35,
      AchievementTier.platinum => 50,
    };
  }
}
