import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cut_the_cable/data/models/inventory_item.dart';
import 'package:cut_the_cable/data/models/player_progress.dart';
import 'package:cut_the_cable/data/models/achievement.dart';
import 'package:cut_the_cable/data/models/level_model.dart';
import 'package:cut_the_cable/data/repositories/inventory_repository.dart';
import 'package:cut_the_cable/data/repositories/save_repository.dart';
import 'package:cut_the_cable/data/repositories/achievement_repository.dart';
import 'package:cut_the_cable/game/systems/level_state_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('InventoryRepository Tests', () {
    test('initializes empty and correctly grants and uses items', () async {
      final repo = InventoryRepository();
      var inv = await repo.load();
      expect(inv.hintCredits, equals(0));
      expect(inv.boosterCount(BoosterType.slowMotion), equals(0));

      // Grant hints & boosters
      await repo.grantHints(3);
      await repo.grantBooster(BoosterType.slowMotion, 2);
      await repo.grantBooster(BoosterType.candyRescue, 1);

      inv = await repo.load();
      expect(inv.hintCredits, equals(3));
      expect(inv.boosterCount(BoosterType.slowMotion), equals(2));
      expect(inv.boosterCount(BoosterType.candyRescue), equals(1));

      // Use a hint
      final afterHint = await repo.useHint();
      expect(afterHint, isNotNull);
      expect(afterHint!.hintCredits, equals(2));

      // Reload from prefs
      final reloaded = await repo.load();
      expect(reloaded.hintCredits, equals(2));
    });

    test('returns null when using booster with zero balance', () async {
      final repo = InventoryRepository();
      await repo.grantBooster(BoosterType.candyRescue, 1);

      // Use the single candy rescue
      final firstUse = await repo.useBooster(BoosterType.candyRescue);
      expect(firstUse, isNotNull);
      expect(firstUse!.boosterCount(BoosterType.candyRescue), equals(0));

      // Attempt second use when 0 remaining
      final secondUse = await repo.useBooster(BoosterType.candyRescue);
      expect(secondUse, isNull);
    });
  });

  group('SaveRepository Tests', () {
    test('initializes player progress and records level completion idempotently', () async {
      final repo = SaveRepository();
      final initial = await repo.loadProgress(100);
      expect(initial.levels.length, equals(100));
      expect(initial.levels[1]!.unlocked, isTrue);
      expect(initial.levels[2]!.unlocked, isFalse);

      final updated = await repo.recordCompletion(
        progress: initial,
        levelId: 1,
        score: 1500,
        stars: 3,
        unlockNext: true,
        maxLevel: 100,
        currencyReward: 25,
      );

      expect(updated.levels[1]!.completed, isTrue);
      expect(updated.levels[1]!.bestScore, equals(1500));
      expect(updated.levels[1]!.bestStars, equals(3));
      expect(updated.levels[2]!.unlocked, isTrue);
      expect(updated.currency, equals(25));
      expect(updated.totalStars, equals(3));

      // Lower score should not overwrite existing high score
      final replay = await repo.recordCompletion(
        progress: updated,
        levelId: 1,
        score: 1000,
        stars: 2,
        unlockNext: true,
        maxLevel: 100,
        currencyReward: 10,
      );

      expect(replay.levels[1]!.bestScore, equals(1500)); // Retained higher score
      expect(replay.levels[1]!.bestStars, equals(3));     // Retained 3 stars
      expect(replay.currency, equals(35));                // Currency still accumulated
    });
  });

  group('AchievementRepository Tests', () {
    test('evaluates and unlocks achievements based on progress', () async {
      final repo = AchievementRepository();
      var ap = await repo.load();
      expect(ap.unlocked, isEmpty);

      // Level 1 complete with 3 stars
      var progress = PlayerProgress.initial(100);
      progress = progress.copyWith(
        levels: {
          ...progress.levels,
          1: progress.levels[1]!.copyWith(completed: true, bestStars: 3),
        },
        totalStars: 3,
      );

      final newlyUnlocked = await repo.evaluate(
        playerProgress: progress,
        achievementProgress: ap,
      );

      // Should unlock firstCut and threeStarsLevel
      expect(newlyUnlocked.any((a) => a.id == AchievementId.firstCut), isTrue);
      expect(newlyUnlocked.any((a) => a.id == AchievementId.threeStarsLevel), isTrue);

      final reloaded = await repo.load();
      expect(reloaded.unlocked.contains(AchievementId.firstCut), isTrue);
      expect(reloaded.unlocked.contains(AchievementId.threeStarsLevel), isTrue);
    });
  });

  group('Star Gating and World Unlock Tests', () {
    test('evaluates world unlock status based on cumulative star requirements', () {
      final requirements = [0, 18, 45, 75, 110, 145, 185, 225, 260, 285];
      var progress = PlayerProgress.initial(100);

      // Fresh player starts with 0 stars
      expect(progress.totalStars, equals(0));
      // World 1 is always unlocked
      expect(progress.isWorldUnlocked(1, requirements), isTrue);
      expect(progress.starsNeededForWorld(1, requirements), equals(0));

      // World 2 requires 18 stars -> locked
      expect(progress.isWorldUnlocked(2, requirements), isFalse);
      expect(progress.starsNeededForWorld(2, requirements), equals(18));

      // Award 18 stars
      progress = progress.copyWith(totalStars: 18);
      expect(progress.isWorldUnlocked(2, requirements), isTrue);
      expect(progress.starsNeededForWorld(2, requirements), equals(0));

      // World 3 requires 45 stars -> still locked, needs 27 more
      expect(progress.isWorldUnlocked(3, requirements), isFalse);
      expect(progress.starsNeededForWorld(3, requirements), equals(27));

      // Award 45 stars -> unlocks World 3
      progress = progress.copyWith(totalStars: 45);
      expect(progress.isWorldUnlocked(3, requirements), isTrue);
      expect(progress.starsNeededForWorld(3, requirements), equals(0));

      // Test boundary world 10
      expect(progress.isWorldUnlocked(10, requirements), isFalse);
      expect(progress.starsNeededForWorld(10, requirements), equals(285 - 45));
    });
  });

  group('LevelStateManager Star Calculation Tests', () {
    test('awards 3 stars when all 3 physical stars are collected regardless of elapsed time', () {
      const scoring = ScoringDef(threeStars: 5270, twoStars: 3180, oneStar: 1090);
      const level = LevelModel(
        levelId: 9,
        worldId: 1,
        name: 'Level 9',
        worldName: 'Candy Garden',
        difficulty: 0,
        candy: Vec2(x: 0.35, y: 0.35),
        monster: Vec2(x: 0.76, y: 0.82),
        ropes: [],
        stars: [
          StarDef(id: 'star_0', x: 0.4, y: 0.5),
          StarDef(id: 'star_1', x: 0.5, y: 0.5),
          StarDef(id: 'star_2', x: 0.6, y: 0.5),
        ],
        obstacles: [],
        objectives: ['deliver_candy'],
        scoring: scoring,
        hintEligible: true,
        boosterEligible: true,
        hintText: 'Hint',
        physicsOverrides: {},
      );

      final manager = LevelStateManager(
        level: level,
        totalStars: 3,
        onVictory: () {},
        onFailure: () {},
      );

      // Collect all 3 stars
      manager.recordStarCollected('star_0');
      manager.recordStarCollected('star_1');
      manager.recordStarCollected('star_2');

      // Even if score is low or score calculation has elapsed time, 3 stars MUST be awarded
      final score = manager.calculateScore();
      final stars = manager.calculateStars(score);

      expect(stars, equals(3), reason: 'All 3 stars collected must grant 3 stars');
    });

    test('awards 2 stars when 2 stars collected, and 1 star when 1 collected', () {
      const scoring = ScoringDef(threeStars: 5270, twoStars: 3180, oneStar: 1090);
      const level = LevelModel(
        levelId: 9,
        worldId: 1,
        name: 'Level 9',
        worldName: 'Candy Garden',
        difficulty: 0,
        candy: Vec2(x: 0.35, y: 0.35),
        monster: Vec2(x: 0.76, y: 0.82),
        ropes: [],
        stars: [
          StarDef(id: 'star_0', x: 0.4, y: 0.5),
          StarDef(id: 'star_1', x: 0.5, y: 0.5),
          StarDef(id: 'star_2', x: 0.6, y: 0.5),
        ],
        obstacles: [],
        objectives: ['deliver_candy'],
        scoring: scoring,
        hintEligible: true,
        boosterEligible: true,
        hintText: 'Hint',
        physicsOverrides: {},
      );

      final manager2 = LevelStateManager(
        level: level,
        totalStars: 3,
        onVictory: () {},
        onFailure: () {},
      );
      manager2.recordStarCollected('star_0');
      manager2.recordStarCollected('star_1');
      expect(manager2.calculateStars(manager2.calculateScore()), equals(2));

      final manager1 = LevelStateManager(
        level: level,
        totalStars: 3,
        onVictory: () {},
        onFailure: () {},
      );
      manager1.recordStarCollected('star_0');
      expect(manager1.calculateStars(manager1.calculateScore()), equals(1));
    });
  });
}
