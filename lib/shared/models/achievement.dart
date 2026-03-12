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
  // Pending claim: detected nearby but not yet claimed by user
  final bool isPendingClaim;
  final DateTime? pendingClaimAt;

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
    this.isPendingClaim = false,
    this.pendingClaimAt,
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    DateTime? visitDate,
    List<String>? photos,
    String? notes,
    bool? isRetroactive,
    double? claimRadius,
    bool? isPendingClaim,
    DateTime? pendingClaimAt,
    bool clearPendingClaimAt = false,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      tier: tier,
      xpReward: xpReward,
      latitude: latitude,
      longitude: longitude,
      claimRadius: claimRadius ?? this.claimRadius,
      collectionId: collectionId,
      tags: tags,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      visitDate: visitDate ?? this.visitDate,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
      isRetroactive: isRetroactive ?? this.isRetroactive,
      isPendingClaim: isPendingClaim ?? this.isPendingClaim,
      pendingClaimAt: clearPendingClaimAt
          ? null
          : (pendingClaimAt ?? this.pendingClaimAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'visitDate': visitDate?.toIso8601String(),
      'photos': photos,
      'notes': notes,
      'isRetroactive': isRetroactive,
      'isPendingClaim': isPendingClaim,
      'pendingClaimAt': pendingClaimAt?.toIso8601String(),
    };
  }

  static Achievement fromJsonOverlay(Achievement base, Map<String, dynamic> json) {
    return base.copyWith(
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      visitDate: json['visitDate'] != null
          ? DateTime.parse(json['visitDate'] as String)
          : null,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? const [],
      notes: json['notes'] as String?,
      isRetroactive: json['isRetroactive'] as bool? ?? false,
      isPendingClaim: json['isPendingClaim'] as bool? ?? false,
      pendingClaimAt: json['pendingClaimAt'] != null
          ? DateTime.parse(json['pendingClaimAt'] as String)
          : null,
    );
  }

  static int xpForTier(AchievementTier tier) {
    return switch (tier) {
      AchievementTier.bronze => 10,
      AchievementTier.silver => 20,
      AchievementTier.gold => 35,
      AchievementTier.platinum => 50,
    };
  }
}
