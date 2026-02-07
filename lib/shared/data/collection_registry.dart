class CollectionInfo {
  final String id;
  final String name;
  final String icon;
  final int bonusXp;

  const CollectionInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.bonusXp,
  });
}

const collectionRegistry = <CollectionInfo>[
  CollectionInfo(id: 'getting-started', name: 'Getting Started', icon: '🚀', bonusXp: 50),
  CollectionInfo(id: 'cities', name: 'Cities', icon: '🏙️', bonusXp: 75),
  CollectionInfo(id: 'nature', name: 'Nature', icon: '🌲', bonusXp: 100),
  CollectionInfo(id: 'food-drink', name: 'Food & Drink', icon: '🍽️', bonusXp: 75),
  CollectionInfo(id: 'culture', name: 'Culture', icon: '🏛️', bonusXp: 100),
  CollectionInfo(id: 'photography', name: 'Photography', icon: '📸', bonusXp: 75),
  CollectionInfo(id: 'countries', name: 'Countries', icon: '🌍', bonusXp: 200),
  CollectionInfo(id: 'water-sports', name: 'Water Sports', icon: '🏄', bonusXp: 100),
];

CollectionInfo? getCollectionInfo(String id) {
  try {
    return collectionRegistry.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
