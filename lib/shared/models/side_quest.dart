enum QuestDifficulty { easy, medium, hard, legendary }

enum VerificationMethod { photo, manual, location, timeBased }

class SideQuest {
  final String id;
  final String title;
  final String description;
  final String category;
  final String skillType;
  final QuestDifficulty difficulty;
  final int xpReward;
  final VerificationMethod verification;
  final bool isRepeatable;
  final int maxCompletions;
  final int completionCount;
  final bool isCompleted;

  const SideQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.skillType,
    required this.difficulty,
    required this.xpReward,
    this.verification = VerificationMethod.manual,
    this.isRepeatable = false,
    this.maxCompletions = 1,
    this.completionCount = 0,
    this.isCompleted = false,
  });
}
