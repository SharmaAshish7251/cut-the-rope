import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/player_progress.dart';
import '../models/game_settings.dart';

class SaveRepository {
  static const _progressKey = 'player_progress_v1';
  static const _settingsKey = 'game_settings_v1';
  final _log = Logger();

  Future<PlayerProgress> loadProgress(int totalLevels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);
      if (raw == null) return PlayerProgress.initial(totalLevels);
      return PlayerProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _log.w('Corrupted save data, resetting.', error: e);
      return PlayerProgress.initial(totalLevels);
    }
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  /// Saves completion result idempotently — never overwrites a better score.
  Future<PlayerProgress> recordCompletion({
    required PlayerProgress progress,
    required int levelId,
    required int score,
    required int stars,
    required bool unlockNext,
    required int maxLevel,
    int currencyReward = 0,
  }) async {
    final levels = Map<int, LevelProgress>.from(progress.levels);
    final existing = levels[levelId] ?? LevelProgress.initial(levelId, unlocked: true);

    final updated = existing.copyWith(
      completed: true,
      bestScore: score > existing.bestScore ? score : existing.bestScore,
      bestStars: stars > existing.bestStars ? stars : existing.bestStars,
      attempts: existing.attempts + 1,
    );
    levels[levelId] = updated;

    // Unlock next level if appropriate
    if (unlockNext && levelId < maxLevel) {
      final next = levels[levelId + 1] ?? LevelProgress.initial(levelId + 1);
      levels[levelId + 1] = next.copyWith(unlocked: true);
    }

    final totalStars = levels.values.fold(0, (sum, l) => sum + l.bestStars);
    final newCurrency = progress.currency + currencyReward;
    final newProgress = progress.copyWith(
      levels: levels,
      totalStars: totalStars,
      currency: newCurrency,
    );
    await saveProgress(newProgress);
    return newProgress;
  }

  Future<GameSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw == null) return const GameSettings();
      return GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      return const GameSettings();
    }
  }

  Future<void> saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    await prefs.remove(_settingsKey);
  }
}
