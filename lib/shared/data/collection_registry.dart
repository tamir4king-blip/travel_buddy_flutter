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
  CollectionInfo(id: 'beaches', name: 'Beaches', icon: '🏖️', bonusXp: 75),
  CollectionInfo(id: 'landmarks', name: 'Landmarks', icon: '🏛️', bonusXp: 100),
  CollectionInfo(id: 'parks', name: 'Parks', icon: '🌳', bonusXp: 100),
  CollectionInfo(id: 'culture', name: 'Culture', icon: '🎭', bonusXp: 75),
];

CollectionInfo? getCollectionInfo(String id) {
  try {
    return collectionRegistry.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
