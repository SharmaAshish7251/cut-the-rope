import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/level_model.dart';

class LevelRepository {
  final _cache = <int, LevelModel>{};
  final _log = Logger();

  Future<LevelModel> getLevel(int levelId) async {
    if (_cache.containsKey(levelId)) return _cache[levelId]!;
    final worldId = ((levelId - 1) ~/ 10) + 1;
    try {
      final raw = await rootBundle
          .loadString('assets/levels/world_$worldId/level_$levelId.json');
      final model = LevelModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _cache[levelId] = model;
      return model;
    } catch (e) {
      _log.e('Failed to load level $levelId', error: e);
      rethrow;
    }
  }

  Future<List<LevelModel>> getWorldLevels(int worldId) async {
    final start = (worldId - 1) * 10 + 1;
    final end = worldId * 10;
    final futures = <Future<LevelModel>>[];
    for (var i = start; i <= end; i++) {
      futures.add(getLevel(i));
    }
    return Future.wait(futures);
  }

  void clearCache() => _cache.clear();
}
