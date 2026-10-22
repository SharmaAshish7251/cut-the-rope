import 'dart:convert';
import 'package:flutter/services.dart';

/// Top-level configuration loaded from assets/config/game_config.json
class GameConfig {
  final GameMeta game;
  final ThemeConfig theme;
  final GameplayConfig gameplay;
  final AdsConfig ads;
  final ProgressionConfig progression;
  final AudioConfig audio;
  final FeatureFlags featureFlags;

  const GameConfig({
    required this.game,
    required this.theme,
    required this.gameplay,
    required this.ads,
    required this.progression,
    required this.audio,
    required this.featureFlags,
  });

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        game: GameMeta.fromJson(json['game'] as Map<String, dynamic>),
        theme: ThemeConfig.fromJson(json['theme'] as Map<String, dynamic>),
        gameplay: GameplayConfig.fromJson(json['gameplay'] as Map<String, dynamic>),
        ads: AdsConfig.fromJson(json['ads'] as Map<String, dynamic>),
        progression: ProgressionConfig.fromJson(json['progression'] as Map<String, dynamic>),
        audio: AudioConfig.fromJson(json['audio'] as Map<String, dynamic>),
        featureFlags: FeatureFlags.fromJson(json['featureFlags'] as Map<String, dynamic>),
      );

  static Future<GameConfig> load() async {
    final raw = await rootBundle.loadString('assets/config/game_config.json');
    return GameConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

class GameMeta {
  final String title;
  final String version;
  final int totalLevels;
  final int totalWorlds;
  final int levelsPerWorld;
  final int firstLevel;
  final String orientation;

  const GameMeta({
    required this.title,
    required this.version,
    required this.totalLevels,
    required this.totalWorlds,
    required this.levelsPerWorld,
    required this.firstLevel,
    required this.orientation,
  });

  factory GameMeta.fromJson(Map<String, dynamic> json) => GameMeta(
        title: json['title'] as String,
        version: json['version'] as String,
        totalLevels: json['totalLevels'] as int,
        totalWorlds: json['totalWorlds'] as int,
        levelsPerWorld: json['levelsPerWorld'] as int,
        firstLevel: json['firstLevel'] as int,
        orientation: json['orientation'] as String,
      );
}

class ThemeConfig {
  final String style;
  final String background;
  final String primary;
  final String secondary;
  final String accent;
  final String success;
  final String danger;
  final String text;
  final String surface;
  final double cornerRadius;
  final bool softShadows;
  final bool puffyHighlights;

  const ThemeConfig({
    required this.style,
    required this.background,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.danger,
    required this.text,
    required this.surface,
    required this.cornerRadius,
    required this.softShadows,
    required this.puffyHighlights,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) => ThemeConfig(
        style: json['style'] as String,
        background: json['background'] as String,
        primary: json['primary'] as String,
        secondary: json['secondary'] as String,
        accent: json['accent'] as String,
        success: json['success'] as String,
        danger: json['danger'] as String,
        text: json['text'] as String,
        surface: json['surface'] as String,
        cornerRadius: (json['cornerRadius'] as num).toDouble(),
        softShadows: json['softShadows'] as bool,
        puffyHighlights: json['puffyHighlights'] as bool,
      );
}

class GameplayConfig {
  final double gravity;
  final int maxStarsPerLevel;
  final double ropeCutSensitivityPx;
  final bool allowOfflineGameplay;
  final bool allowOfflineProgressSaving;
  final bool requireInternetForHints;
  final bool requireInternetToEarnBoosters;
  final bool requireCompletedRewardedAd;

  const GameplayConfig({
    required this.gravity,
    required this.maxStarsPerLevel,
    required this.ropeCutSensitivityPx,
    required this.allowOfflineGameplay,
    required this.allowOfflineProgressSaving,
    required this.requireInternetForHints,
    required this.requireInternetToEarnBoosters,
    required this.requireCompletedRewardedAd,
  });

  factory GameplayConfig.fromJson(Map<String, dynamic> json) => GameplayConfig(
        gravity: (json['gravity'] as num).toDouble(),
        maxStarsPerLevel: json['maxStarsPerLevel'] as int,
        ropeCutSensitivityPx: (json['ropeCutSensitivityPx'] as num).toDouble(),
        allowOfflineGameplay: json['allowOfflineGameplay'] as bool,
        allowOfflineProgressSaving: json['allowOfflineProgressSaving'] as bool,
        requireInternetForHints: json['requireInternetForHints'] as bool,
        requireInternetToEarnBoosters: json['requireInternetToEarnBoosters'] as bool,
        requireCompletedRewardedAd: json['requireCompletedRewardedAd'] as bool,
      );
}

class AdsConfig {
  final String provider;
  final bool testMode;
  final String androidAppId;
  final String androidRewardedAdUnitId;
  final String iosAppId;
  final String iosRewardedAdUnitId;
  final bool rewardedHints;
  final bool rewardedBoosters;
  final bool bannerAds;
  final bool interstitialAds;
  final int hintsPerCompletedAd;
  final int boostersPerCompletedAd;

  const AdsConfig({
    required this.provider,
    required this.testMode,
    required this.androidAppId,
    required this.androidRewardedAdUnitId,
    required this.iosAppId,
    required this.iosRewardedAdUnitId,
    required this.rewardedHints,
    required this.rewardedBoosters,
    required this.bannerAds,
    required this.interstitialAds,
    required this.hintsPerCompletedAd,
    required this.boostersPerCompletedAd,
  });

  factory AdsConfig.fromJson(Map<String, dynamic> json) => AdsConfig(
        provider: json['provider'] as String,
        testMode: json['testMode'] as bool,
        androidAppId: json['androidAppId'] as String,
        androidRewardedAdUnitId: json['androidRewardedAdUnitId'] as String,
        iosAppId: json['iosAppId'] as String,
        iosRewardedAdUnitId: json['iosRewardedAdUnitId'] as String,
        rewardedHints: json['rewardedHints'] as bool,
        rewardedBoosters: json['rewardedBoosters'] as bool,
        bannerAds: json['bannerAds'] as bool,
        interstitialAds: json['interstitialAds'] as bool,
        hintsPerCompletedAd: json['hintsPerCompletedAd'] as int,
        boostersPerCompletedAd: json['boostersPerCompletedAd'] as int,
      );
}

class ProgressionConfig {
  final bool unlockNextLevelOnCompletion;
  final bool allowReplay;
  final int maxLevel;
  final String resumePolicy;
  final List<int> worldStarRequirements;

  const ProgressionConfig({
    required this.unlockNextLevelOnCompletion,
    required this.allowReplay,
    required this.maxLevel,
    required this.resumePolicy,
    this.worldStarRequirements = const [0, 18, 45, 75, 110, 145, 185, 225, 260, 285],
  });

  factory ProgressionConfig.fromJson(Map<String, dynamic> json) => ProgressionConfig(
        unlockNextLevelOnCompletion: json['unlockNextLevelOnCompletion'] as bool,
        allowReplay: json['allowReplay'] as bool,
        maxLevel: json['maxLevel'] as int,
        resumePolicy: json['resumePolicy'] as String,
        worldStarRequirements: (json['worldStarRequirements'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [0, 18, 45, 75, 110, 145, 185, 225, 260, 285],
      );
}

class AudioConfig {
  final bool musicEnabledByDefault;
  final bool soundEnabledByDefault;
  final bool vibrationEnabledByDefault;

  const AudioConfig({
    required this.musicEnabledByDefault,
    required this.soundEnabledByDefault,
    required this.vibrationEnabledByDefault,
  });

  factory AudioConfig.fromJson(Map<String, dynamic> json) => AudioConfig(
        musicEnabledByDefault: json['musicEnabledByDefault'] as bool,
        soundEnabledByDefault: json['soundEnabledByDefault'] as bool,
        vibrationEnabledByDefault: json['vibrationEnabledByDefault'] as bool,
      );
}

class FeatureFlags {
  final bool shopEnabled;
  final bool achievementsEnabled;
  final bool dailyRewardsEnabled;
  final bool hintSystemEnabled;
  final bool boosterSystemEnabled;

  const FeatureFlags({
    required this.shopEnabled,
    required this.achievementsEnabled,
    required this.dailyRewardsEnabled,
    required this.hintSystemEnabled,
    required this.boosterSystemEnabled,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) => FeatureFlags(
        shopEnabled: json['shopEnabled'] as bool,
        achievementsEnabled: json['achievementsEnabled'] as bool,
        dailyRewardsEnabled: json['dailyRewardsEnabled'] as bool,
        hintSystemEnabled: json['hintSystemEnabled'] as bool,
        boosterSystemEnabled: json['boosterSystemEnabled'] as bool,
      );
}
