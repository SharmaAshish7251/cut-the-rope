import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/game_config.dart';
import '../data/models/player_progress.dart';
import '../data/models/game_settings.dart';
import '../data/models/inventory_item.dart';
import '../data/repositories/save_repository.dart';
import '../data/repositories/level_repository.dart';
import '../data/repositories/inventory_repository.dart';
import '../services/audio_service.dart';
import '../services/network_service.dart';
import '../services/ads_service.dart';
import '../services/reward_service.dart';

// ── Singletons ─────────────────────────────────────────────────────────────

final saveRepositoryProvider = Provider<SaveRepository>((_) => SaveRepository());
final levelRepositoryProvider = Provider<LevelRepository>((_) => LevelRepository());
final inventoryRepositoryProvider = Provider<InventoryRepository>((_) => InventoryRepository());
final audioServiceProvider    = Provider<AudioService>((_) => AudioService());
final networkServiceProvider  = Provider<NetworkService>((_) => NetworkService());

// ── Config ─────────────────────────────────────────────────────────────────

final gameConfigProvider = FutureProvider<GameConfig>((ref) => GameConfig.load());

// ── Ads ────────────────────────────────────────────────────────────────────

final adsServiceProvider = Provider<AdsService>((ref) {
  final config = ref.watch(gameConfigProvider).valueOrNull;
  if (config == null) throw StateError('AdsService created before config loaded');
  return AdsService(config.ads);
});

// ── Reward Service ─────────────────────────────────────────────────────────

final rewardServiceProvider = Provider<RewardService>((ref) {
  final config = ref.watch(gameConfigProvider).valueOrNull;
  if (config == null) throw StateError('RewardService created before config loaded');
  return RewardService(
    ads: ref.watch(adsServiceProvider),
    network: ref.watch(networkServiceProvider),
    inventoryRepo: ref.watch(inventoryRepositoryProvider),
    gameplay: config.gameplay,
    adsConfig: config.ads,
  );
});

// ── Player progress ────────────────────────────────────────────────────────

class ProgressNotifier extends StateNotifier<AsyncValue<PlayerProgress>> {
  final SaveRepository _repo;
  final int _totalLevels;

  ProgressNotifier(this._repo, this._totalLevels) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final p = await _repo.loadProgress(_totalLevels);
      state = AsyncValue.data(p);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<PlayerProgress> get future async {
    while (state is AsyncLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return state.requireValue;
  }

  Future<void> recordCompletion({
    required int levelId,
    required int score,
    required int stars,
    required bool unlockNext,
    required int maxLevel,
    int currencyReward = 0,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = await _repo.recordCompletion(
      progress: current,
      levelId: levelId,
      score: score,
      stars: stars,
      unlockNext: unlockNext,
      maxLevel: maxLevel,
      currencyReward: currencyReward,
    );
    state = AsyncValue.data(updated);
  }

  Future<void> addCurrency(int amount) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(currency: current.currency + amount);
    await _repo.saveProgress(updated);
    state = AsyncValue.data(updated);
  }

  Future<bool> spendCurrency(int amount) async {
    final current = state.valueOrNull;
    if (current == null || current.currency < amount) return false;
    final updated = current.copyWith(currency: current.currency - amount);
    await _repo.saveProgress(updated);
    state = AsyncValue.data(updated);
    return true;
  }

  Future<void> markTutorialDone() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(tutorialCompleted: true);
    await _repo.saveProgress(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> refresh() => _load();
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, AsyncValue<PlayerProgress>>((ref) {
  final repo = ref.watch(saveRepositoryProvider);
  final config = ref.watch(gameConfigProvider).valueOrNull;
  return ProgressNotifier(repo, config?.game.totalLevels ?? 100);
});

// ── Inventory ──────────────────────────────────────────────────────────────

class InventoryNotifier extends StateNotifier<AsyncValue<Inventory>> {
  final InventoryRepository _repo;

  InventoryNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final inv = await _repo.load();
      state = AsyncValue.data(inv);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void updateInventory(Inventory inv) {
    state = AsyncValue.data(inv);
  }

  Future<void> refresh() => _load();
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, AsyncValue<Inventory>>((ref) {
  return InventoryNotifier(ref.watch(inventoryRepositoryProvider));
});

// ── Settings ───────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<GameSettings> {
  final SaveRepository _repo;

  SettingsNotifier(this._repo) : super(const GameSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.loadSettings();
  }

  Future<void> update(GameSettings settings) async {
    state = settings;
    await _repo.saveSettings(settings);
  }

  Future<void> toggleMusic() =>
      update(state.copyWith(musicEnabled: !state.musicEnabled));
  Future<void> toggleSound() =>
      update(state.copyWith(soundEnabled: !state.soundEnabled));
  Future<void> toggleVibration() =>
      update(state.copyWith(vibrationEnabled: !state.vibrationEnabled));
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, GameSettings>((ref) {
  return SettingsNotifier(ref.watch(saveRepositoryProvider));
});
