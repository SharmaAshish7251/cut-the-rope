import 'dart:convert';
import 'package:flutter/services.dart';

/// Normalized (0..1) 2-D coordinate stored in JSON.
class Vec2 {
  final double x;
  final double y;
  const Vec2({required this.x, required this.y});
  factory Vec2.fromJson(Map<String, dynamic> j) =>
      Vec2(x: (j['x'] as num).toDouble(), y: (j['y'] as num).toDouble());
}

class RopeDef {
  final String id;
  final double anchorX;
  final double anchorY;
  final double length;
  final bool cuttable;

  const RopeDef({
    required this.id,
    required this.anchorX,
    required this.anchorY,
    required this.length,
    required this.cuttable,
  });

  factory RopeDef.fromJson(Map<String, dynamic> j) => RopeDef(
        id: j['id'] as String,
        anchorX: (j['anchorX'] as num).toDouble(),
        anchorY: (j['anchorY'] as num).toDouble(),
        length: (j['length'] as num).toDouble(),
        cuttable: j['cuttable'] as bool? ?? true,
      );
}

class StarDef {
  final String id;
  final double x;
  final double y;

  const StarDef({required this.id, required this.x, required this.y});

  factory StarDef.fromJson(Map<String, dynamic> j) => StarDef(
        id: j['id'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
      );
}

class ObstacleDef {
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final Map<String, dynamic> extras;

  const ObstacleDef({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.extras = const {},
  });

  factory ObstacleDef.fromJson(Map<String, dynamic> j) => ObstacleDef(
        type: j['type'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        width: (j['width'] as num).toDouble(),
        height: (j['height'] as num).toDouble(),
        extras: Map<String, dynamic>.from(
          (j..remove('type')..remove('x')..remove('y')..remove('width')..remove('height')),
        ),
      );
}

class ScoringDef {
  final int threeStars;
  final int twoStars;
  final int oneStar;

  const ScoringDef({
    required this.threeStars,
    required this.twoStars,
    required this.oneStar,
  });

  factory ScoringDef.fromJson(Map<String, dynamic> j) => ScoringDef(
        threeStars: j['threeStars'] as int,
        twoStars: j['twoStars'] as int,
        oneStar: j['oneStar'] as int,
      );

  int starsForScore(int score) {
    if (score >= threeStars) return 3;
    if (score >= twoStars) return 2;
    if (score >= oneStar) return 1;
    return 0;
  }
}

class LevelModel {
  final int levelId;
  final int worldId;
  final String name;
  final String worldName;
  final int difficulty;
  final Vec2 candy;
  final Vec2 monster;
  final List<RopeDef> ropes;
  final List<StarDef> stars;
  final List<ObstacleDef> obstacles;
  final List<String> objectives;
  final ScoringDef scoring;
  final bool hintEligible;
  final bool boosterEligible;
  final String hintText;
  final Map<String, dynamic> physicsOverrides;

  const LevelModel({
    required this.levelId,
    required this.worldId,
    required this.name,
    required this.worldName,
    required this.difficulty,
    required this.candy,
    required this.monster,
    required this.ropes,
    required this.stars,
    required this.obstacles,
    required this.objectives,
    required this.scoring,
    required this.hintEligible,
    required this.boosterEligible,
    required this.hintText,
    required this.physicsOverrides,
  });

  factory LevelModel.fromJson(Map<String, dynamic> j) => LevelModel(
        levelId: j['levelId'] as int,
        worldId: j['worldId'] as int,
        name: j['name'] as String,
        worldName: j['worldName'] as String? ?? '',
        difficulty: j['difficulty'] as int,
        candy: Vec2.fromJson(j['candy'] as Map<String, dynamic>),
        monster: Vec2.fromJson(j['monster'] as Map<String, dynamic>),
        ropes: (j['ropes'] as List)
            .map((e) => RopeDef.fromJson(e as Map<String, dynamic>))
            .toList(),
        stars: (j['stars'] as List)
            .map((e) => StarDef.fromJson(e as Map<String, dynamic>))
            .toList(),
        obstacles: (j['obstacles'] as List)
            .map((e) => ObstacleDef.fromJson(e as Map<String, dynamic>))
            .toList(),
        objectives: List<String>.from(j['objectives'] as List),
        scoring: ScoringDef.fromJson(j['scoring'] as Map<String, dynamic>),
        hintEligible: j['hintEligible'] as bool? ?? true,
        boosterEligible: j['boosterEligible'] as bool? ?? true,
        hintText: j['hintText'] as String? ?? '',
        physicsOverrides: Map<String, dynamic>.from(
          j['physicsOverrides'] as Map<String, dynamic>? ?? {},
        ),
      );

  static Future<LevelModel> load(int worldId, int levelId) async {
    final raw = await rootBundle
        .loadString('assets/levels/world_$worldId/level_$levelId.json');
    return LevelModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
