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
  CollectionInfo(id: 'europe', name: 'European Countries', icon: '🇪🇺', bonusXp: 150),
  CollectionInfo(id: 'americas', name: 'American Destinations', icon: '🗽', bonusXp: 150),
  CollectionInfo(id: 'national-parks', name: 'National Parks', icon: '🌲', bonusXp: 200),
  CollectionInfo(id: 'ski-resorts', name: 'Ski Resorts', icon: '⛷️', bonusXp: 150),
  CollectionInfo(id: 'capitals', name: 'World Capitals', icon: '🏛️', bonusXp: 200),
  CollectionInfo(id: 'ancient-sites', name: 'Ancient Religious Sites', icon: '🕌', bonusXp: 250),
  CollectionInfo(id: 'tourist-destinations', name: 'Popular Tourist Destinations', icon: '🌍', bonusXp: 200),
  CollectionInfo(id: 'africa', name: 'African Countries', icon: '🌍', bonusXp: 150),
  CollectionInfo(id: 'asia', name: 'Asian Countries', icon: '🌏', bonusXp: 150),
  CollectionInfo(id: 'south-america', name: 'South American Countries', icon: '🌎', bonusXp: 150),
  CollectionInfo(id: 'oceania', name: 'Oceania', icon: '🏝️', bonusXp: 150),
];

CollectionInfo? getCollectionInfo(String id) {
  try {
    return collectionRegistry.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
