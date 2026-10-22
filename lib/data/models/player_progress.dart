/// Tracks all player progression, serialised to Hive.
class LevelProgress {
  final int levelId;
  final bool completed;
  final bool unlocked;
  final int bestScore;
  final int bestStars;
  final int attempts;

  const LevelProgress({
    required this.levelId,
    required this.completed,
    required this.unlocked,
    required this.bestScore,
    required this.bestStars,
    required this.attempts,
  });

  LevelProgress copyWith({
    bool? completed,
    bool? unlocked,
    int? bestScore,
    int? bestStars,
    int? attempts,
  }) {
    return LevelProgress(
      levelId: levelId,
      completed: completed ?? this.completed,
      unlocked: unlocked ?? this.unlocked,
      bestScore: bestScore ?? this.bestScore,
      bestStars: bestStars ?? this.bestStars,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'completed': completed,
        'unlocked': unlocked,
        'bestScore': bestScore,
        'bestStars': bestStars,
        'attempts': attempts,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> j) => LevelProgress(
        levelId: j['levelId'] as int,
        completed: j['completed'] as bool? ?? false,
        unlocked: j['unlocked'] as bool? ?? false,
        bestScore: j['bestScore'] as int? ?? 0,
        bestStars: j['bestStars'] as int? ?? 0,
        attempts: j['attempts'] as int? ?? 0,
      );

  factory LevelProgress.initial(int levelId, {bool unlocked = false}) =>
      LevelProgress(
        levelId: levelId,
        completed: false,
        unlocked: unlocked,
        bestScore: 0,
        bestStars: 0,
        attempts: 0,
      );
}

class PlayerProgress {
  final Map<int, LevelProgress> levels;
  final int totalStars;
  final int currency;
  final bool tutorialCompleted;
  final int schemaVersion;
  final DateTime lastSaved;

  const PlayerProgress({
    required this.levels,
    required this.totalStars,
    required this.currency,
    required this.tutorialCompleted,
    required this.schemaVersion,
    required this.lastSaved,
  });

  factory PlayerProgress.initial(int totalLevels) {
    final levels = <int, LevelProgress>{};
    for (var i = 1; i <= totalLevels; i++) {
      // Only Level 1 is unlocked for a fresh player
      levels[i] = LevelProgress.initial(i, unlocked: i == 1);
    }
    return PlayerProgress(
      levels: levels,
      totalStars: 0,
      currency: 0,
      tutorialCompleted: false,
      schemaVersion: 1,
      lastSaved: DateTime.now(),
    );
  }

  /// Returns the next incomplete level id, or 1 if none found.
  int get nextLevel {
    for (final entry in levels.entries) {
      if (entry.value.unlocked && !entry.value.completed) return entry.key;
    }
    return 1;
  }

  int get highestUnlocked =>
      levels.entries.where((e) => e.value.unlocked).map((e) => e.key).fold(1, (a, b) => a > b ? a : b);

  PlayerProgress copyWith({
    Map<int, LevelProgress>? levels,
    int? totalStars,
    int? currency,
    bool? tutorialCompleted,
  }) {
    return PlayerProgress(
      levels: levels ?? this.levels,
      totalStars: totalStars ?? this.totalStars,
      currency: currency ?? this.currency,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      schemaVersion: schemaVersion,
      lastSaved: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'levels': levels.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'totalStars': totalStars,
        'currency': currency,
        'tutorialCompleted': tutorialCompleted,
        'schemaVersion': schemaVersion,
        'lastSaved': lastSaved.toIso8601String(),
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> j) {
    final rawLevels = j['levels'] as Map<String, dynamic>;
    final levels = rawLevels.map((k, v) =>
        MapEntry(int.parse(k), LevelProgress.fromJson(v as Map<String, dynamic>)));
    return PlayerProgress(
      levels: levels,
      totalStars: j['totalStars'] as int? ?? 0,
      currency: j['currency'] as int? ?? 0,
      tutorialCompleted: j['tutorialCompleted'] as bool? ?? false,
      schemaVersion: j['schemaVersion'] as int? ?? 1,
      lastSaved: DateTime.tryParse(j['lastSaved'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Checks whether a world (1..10) is unlocked according to star gating requirements.
  bool isWorldUnlocked(int worldId, List<int> requirements) {
    if (worldId <= 1) return true;
    if (worldId > requirements.length) return false;
    return totalStars >= requirements[worldId - 1];
  }

  /// Calculates stars still needed to unlock the specified world.
  int starsNeededForWorld(int worldId, List<int> requirements) {
    if (worldId <= 1 || isWorldUnlocked(worldId, requirements)) return 0;
    return requirements[worldId - 1] - totalStars;
  }
}
