class SkillGroup {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<String> categories;
  final int maxLevel;
  final int xpPerLevel;
  final String gradientStart;
  final String gradientEnd;

  const SkillGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.categories,
    required this.maxLevel,
    required this.xpPerLevel,
    required this.gradientStart,
    required this.gradientEnd,
  });
}
