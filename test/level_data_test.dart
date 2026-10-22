import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cut_the_cable/data/models/level_model.dart';

void main() {
  group('Level Data Integrity Tests (All 100 Levels)', () {
    final levelsDir = Directory('assets/levels');

    test('Directory assets/levels exists and has 10 worlds', () {
      expect(levelsDir.existsSync(), isTrue);
      final worlds = levelsDir
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path.contains('world_'))
          .toList();
      expect(worlds.length, equals(10));
    });

    test('All 100 level JSON files exist, parse successfully, and have valid data', () {
      int parsedCount = 0;
      final seenLevelIds = <int>{};

      for (int world = 1; world <= 10; world++) {
        for (int lvl = 1; lvl <= 10; lvl++) {
          final levelId = (world - 1) * 10 + lvl;
          final file = File('assets/levels/world_$world/level_$levelId.json');
          expect(file.existsSync(), isTrue, reason: 'Missing file: ${file.path}');

          final content = file.readAsStringSync();
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;
          final level = LevelModel.fromJson(jsonMap);

          expect(level.levelId, equals(levelId), reason: 'levelId mismatch in ${file.path}');
          expect(level.worldId, equals(world), reason: 'worldId mismatch in ${file.path}');
          expect(level.name.isNotEmpty, isTrue);
          expect(level.worldName.isNotEmpty, isTrue);

          // Candy position within 0..1 bounds
          expect(level.candy.x >= 0.0 && level.candy.x <= 1.0, isTrue);
          expect(level.candy.y >= 0.0 && level.candy.y <= 1.0, isTrue);

          // Monster position within 0..1 bounds
          expect(level.monster.x >= 0.0 && level.monster.x <= 1.0, isTrue);
          expect(level.monster.y >= 0.0 && level.monster.y <= 1.0, isTrue);

          // At least 1 rope
          expect(level.ropes.isNotEmpty, isTrue, reason: 'Level $levelId has no ropes');
          for (final rope in level.ropes) {
            expect(rope.anchorX >= 0.0 && rope.anchorX <= 1.0, isTrue);
            expect(rope.anchorY >= 0.0 && rope.anchorY <= 1.0, isTrue);
            expect(rope.length > 0, isTrue);
          }

          // Stars (usually 3 stars per level)
          expect(level.stars.length, equals(3), reason: 'Level $levelId does not have 3 stars');
          for (final star in level.stars) {
            expect(star.x >= 0.0 && star.x <= 1.0, isTrue);
            expect(star.y >= 0.0 && star.y <= 1.0, isTrue);
          }

          // Scoring thresholds
          expect(level.scoring.threeStars > level.scoring.twoStars, isTrue);
          expect(level.scoring.twoStars > level.scoring.oneStar, isTrue);

          seenLevelIds.add(level.levelId);
          parsedCount++;
        }
      }

      expect(parsedCount, equals(100));
      expect(seenLevelIds.length, equals(100));
    });
  });
}
