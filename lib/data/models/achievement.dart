/// Achievement definitions and tracking for Cut the Cable.
enum AchievementId {
  firstCut,
  tenLevels,
  fiftyLevels,
  allLevels,
  threeStarsLevel,
  threeStarsWorld,
  allStars,
  firstBooster,
  tenBoosters,
  firstHint,
  speedDemon,
  persistent,
  collector,
}

class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final String emoji;
  final int rewardCurrency;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.rewardCurrency,
  });
}

const allAchievements = [
  Achievement(
    id: AchievementId.firstCut,
    title: 'First Cut',
    description: 'Complete your first level',
    emoji: '✂️',
    rewardCurrency: 10,
  ),
  Achievement(
    id: AchievementId.tenLevels,
    title: 'Getting Started',
    description: 'Complete 10 levels',
    emoji: '🌟',
    rewardCurrency: 25,
  ),
  Achievement(
    id: AchievementId.fiftyLevels,
    title: 'Halfway There',
    description: 'Complete 50 levels',
    emoji: '🔥',
    rewardCurrency: 50,
  ),
  Achievement(
    id: AchievementId.allLevels,
    title: 'Master Cutter',
    description: 'Complete all 100 levels',
    emoji: '🏆',
    rewardCurrency: 200,
  ),
  Achievement(
    id: AchievementId.threeStarsLevel,
    title: 'Perfectionist',
    description: 'Get 3 stars on any level',
    emoji: '⭐',
    rewardCurrency: 15,
  ),
  Achievement(
    id: AchievementId.threeStarsWorld,
    title: 'World Champion',
    description: 'Get 3 stars on all levels in a world',
    emoji: '🌍',
    rewardCurrency: 75,
  ),
  Achievement(
    id: AchievementId.allStars,
    title: 'Star Collector',
    description: 'Collect all 300 stars',
    emoji: '💫',
    rewardCurrency: 300,
  ),
  Achievement(
    id: AchievementId.firstBooster,
    title: 'Power Up',
    description: 'Use your first booster',
    emoji: '⚡',
    rewardCurrency: 10,
  ),
  Achievement(
    id: AchievementId.tenBoosters,
    title: 'Booster Fan',
    description: 'Use 10 boosters',
    emoji: '🚀',
    rewardCurrency: 30,
  ),
  Achievement(
    id: AchievementId.firstHint,
    title: 'Wise Move',
    description: 'Use your first hint',
    emoji: '💡',
    rewardCurrency: 10,
  ),
  Achievement(
    id: AchievementId.speedDemon,
    title: 'Speed Demon',
    description: 'Complete a level in under 5 seconds',
    emoji: '⏱',
    rewardCurrency: 20,
  ),
  Achievement(
    id: AchievementId.persistent,
    title: 'Never Give Up',
    description: 'Retry a level 10 times',
    emoji: '💪',
    rewardCurrency: 15,
  ),
  Achievement(
    id: AchievementId.collector,
    title: 'Daily Collector',
    description: 'Claim daily rewards 7 days in a row',
    emoji: '🎁',
    rewardCurrency: 50,
  ),
];
