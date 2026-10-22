import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/achievement.dart';
import '../models/player_progress.dart';

/// Tracks unlocked achievements and stats for achievement evaluation.
class AchievementProgress {
  final Set<AchievementId> unlocked;
  final int boostersUsed;
  final int hintsUsed;
  final double fastestCompletion; // seconds, 0 = not tracked yet
  final int maxRetriesOnLevel;

  const AchievementProgress({
    this.unlocked = const {},
    this.boostersUsed = 0,
    this.hintsUsed = 0,
    this.fastestCompletion = 999,
    this.maxRetriesOnLevel = 0,
  });

  AchievementProgress copyWith({
    Set<AchievementId>? unlocked,
    int? boostersUsed,
    int? hintsUsed,
    double? fastestCompletion,
    int? maxRetriesOnLevel,
  }) =>
      AchievementProgress(
        unlocked: unlocked ?? Set.from(this.unlocked),
        boostersUsed: boostersUsed ?? this.boostersUsed,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        fastestCompletion: fastestCompletion ?? this.fastestCompletion,
        maxRetriesOnLevel: maxRetriesOnLevel ?? this.maxRetriesOnLevel,
      );

  Map<String, dynamic> toJson() => {
        'unlocked': unlocked.map((a) => a.name).toList(),
        'boostersUsed': boostersUsed,
        'hintsUsed': hintsUsed,
        'fastestCompletion': fastestCompletion,
        'maxRetriesOnLevel': maxRetriesOnLevel,
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> j) {
    final rawUnlocked = (j['unlocked'] as List?)?.cast<String>() ?? [];
    final unlocked = rawUnlocked
        .map((name) => AchievementId.values.where((a) => a.name == name).firstOrNull)
        .whereType<AchievementId>()
        .toSet();
    return AchievementProgress(
      unlocked: unlocked,
      boostersUsed: j['boostersUsed'] as int? ?? 0,
      hintsUsed: j['hintsUsed'] as int? ?? 0,
      fastestCompletion: (j['fastestCompletion'] as num?)?.toDouble() ?? 999,
      maxRetriesOnLevel: j['maxRetriesOnLevel'] as int? ?? 0,
    );
  }
}

class AchievementRepository {
  static const _key = 'achievements_v1';
  final _log = Logger();

  Future<AchievementProgress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const AchievementProgress();
      return AchievementProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      _log.w('Corrupted achievement data, resetting.', error: e);
      return const AchievementProgress();
    }
  }

  Future<void> save(AchievementProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  /// Evaluate all achievements against current state.
  /// Returns list of newly unlocked achievements.
  Future<List<Achievement>> evaluate({
    required PlayerProgress playerProgress,
    required AchievementProgress achievementProgress,
  }) async {
    final newlyUnlocked = <Achievement>[];
    final completed = playerProgress.levels.values.where((l) => l.completed).length;
    final totalStars = playerProgress.totalStars;
    final ap = achievementProgress;

    for (final achievement in allAchievements) {
      if (ap.unlocked.contains(achievement.id)) continue;

      bool earned = false;
      switch (achievement.id) {
        case AchievementId.firstCut:
          earned = completed >= 1;
          break;
        case AchievementId.tenLevels:
          earned = completed >= 10;
          break;
        case AchievementId.fiftyLevels:
          earned = completed >= 50;
          break;
        case AchievementId.allLevels:
          earned = completed >= 100;
          break;
        case AchievementId.threeStarsLevel:
          earned = playerProgress.levels.values.any((l) => l.bestStars >= 3);
          break;
        case AchievementId.threeStarsWorld:
          for (int w = 0; w < 10; w++) {
            final start = w * 10 + 1;
            final end = start + 9;
            bool allThree = true;
            for (int l = start; l <= end; l++) {
              if ((playerProgress.levels[l]?.bestStars ?? 0) < 3) {
                allThree = false;
                break;
              }
            }
            if (allThree) { earned = true; break; }
          }
          break;
        case AchievementId.allStars:
          earned = totalStars >= 300;
          break;
        case AchievementId.firstBooster:
          earned = ap.boostersUsed >= 1;
          break;
        case AchievementId.tenBoosters:
          earned = ap.boostersUsed >= 10;
          break;
        case AchievementId.firstHint:
          earned = ap.hintsUsed >= 1;
          break;
        case AchievementId.speedDemon:
          earned = ap.fastestCompletion <= 5.0;
          break;
        case AchievementId.persistent:
          earned = ap.maxRetriesOnLevel >= 10;
          break;
        case AchievementId.collector:
          // Check 7 consecutive daily claims
          earned = false; // Tracked via inventory claim history
          break;
      }

      if (earned) newlyUnlocked.add(achievement);
    }

    if (newlyUnlocked.isNotEmpty) {
      final updated = ap.copyWith(
        unlocked: {...ap.unlocked, ...newlyUnlocked.map((a) => a.id)},
      );
      await save(updated);
    }

    return newlyUnlocked;
  }

  Future<AchievementProgress> recordBoosterUsed(AchievementProgress ap) async {
    final updated = ap.copyWith(boostersUsed: ap.boostersUsed + 1);
    await save(updated);
    return updated;
  }

  Future<AchievementProgress> recordHintUsed(AchievementProgress ap) async {
    final updated = ap.copyWith(hintsUsed: ap.hintsUsed + 1);
    await save(updated);
    return updated;
  }

  Future<AchievementProgress> recordCompletionTime(
      AchievementProgress ap, double seconds) async {
    final updated = ap.copyWith(
      fastestCompletion:
          seconds < ap.fastestCompletion ? seconds : ap.fastestCompletion,
    );
    await save(updated);
    return updated;
  }
}
