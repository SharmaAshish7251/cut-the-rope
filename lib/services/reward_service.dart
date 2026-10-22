import 'package:logger/logger.dart';
import '../config/game_config.dart';
import '../data/models/inventory_item.dart';
import '../data/repositories/inventory_repository.dart';
import '../services/ads_service.dart';
import '../services/network_service.dart';

/// Outcome of a reward-gated action (hint or booster).
enum RewardOutcome {
  granted,
  offline,
  adFailed,
  adCancelled,
  noInventory,
}

/// Orchestrates the hint / booster reward flow:
///   1. Check network connectivity
///   2. Show rewarded ad
///   3. Grant reward to inventory on confirmed completion
class RewardService {
  final AdsService _ads;
  final NetworkService _network;
  final InventoryRepository _inventoryRepo;
  final GameplayConfig _gameplay;
  final AdsConfig _adsConfig;
  final _log = Logger();

  RewardService({
    required AdsService ads,
    required NetworkService network,
    required InventoryRepository inventoryRepo,
    required GameplayConfig gameplay,
    required AdsConfig adsConfig,
  })  : _ads = ads,
        _network = network,
        _inventoryRepo = inventoryRepo,
        _gameplay = gameplay,
        _adsConfig = adsConfig;

  /// Attempt to earn a hint via rewarded ad.
  /// Returns the outcome and the updated inventory (if granted).
  Future<(RewardOutcome, Inventory?)> earnHint() async {
    if (_gameplay.requireInternetForHints) {
      if (!await _network.isOnline()) return (RewardOutcome.offline, null);
    }

    if (_gameplay.requireCompletedRewardedAd) {
      final result = await _ads.showRewardedAd();
      switch (result) {
        case AdResult.rewarded:
          final inv = await _inventoryRepo.grantHints(
            _adsConfig.hintsPerCompletedAd,
          );
          _log.i('Hint earned via ad');
          return (RewardOutcome.granted, inv);
        case AdResult.cancelled:
          return (RewardOutcome.adCancelled, null);
        case AdResult.failed:
          return (RewardOutcome.adFailed, null);
      }
    }

    // No ad required — grant directly
    final inv = await _inventoryRepo.grantHints(1);
    return (RewardOutcome.granted, inv);
  }

  /// Attempt to earn a booster via rewarded ad.
  Future<(RewardOutcome, Inventory?)> earnBooster(BoosterType type) async {
    if (_gameplay.requireInternetToEarnBoosters) {
      if (!await _network.isOnline()) return (RewardOutcome.offline, null);
    }

    if (_gameplay.requireCompletedRewardedAd) {
      final result = await _ads.showRewardedAd();
      switch (result) {
        case AdResult.rewarded:
          final inv = await _inventoryRepo.grantBooster(
            type,
            _adsConfig.boostersPerCompletedAd,
          );
          _log.i('Booster ${type.displayName} earned via ad');
          return (RewardOutcome.granted, inv);
        case AdResult.cancelled:
          return (RewardOutcome.adCancelled, null);
        case AdResult.failed:
          return (RewardOutcome.adFailed, null);
      }
    }

    final inv = await _inventoryRepo.grantBooster(type, 1);
    return (RewardOutcome.granted, inv);
  }

  /// Use a hint credit from inventory (no ad needed).
  Future<(RewardOutcome, Inventory?)> useHint() async {
    final inv = await _inventoryRepo.useHint();
    if (inv == null) return (RewardOutcome.noInventory, null);
    return (RewardOutcome.granted, inv);
  }

  /// Use a booster from inventory (no ad needed, works offline).
  Future<(RewardOutcome, Inventory?)> useBooster(BoosterType type) async {
    final inv = await _inventoryRepo.useBooster(type);
    if (inv == null) return (RewardOutcome.noInventory, null);
    return (RewardOutcome.granted, inv);
  }
}
