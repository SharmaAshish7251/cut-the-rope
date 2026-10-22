import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/inventory_item.dart';

class InventoryRepository {
  static const _key = 'player_inventory_v1';
  final _log = Logger();

  Future<Inventory> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const Inventory();
      return Inventory.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _log.w('Corrupted inventory data, resetting.', error: e);
      return const Inventory();
    }
  }

  Future<void> save(Inventory inventory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(inventory.toJson()));
  }

  /// Atomically grants a booster and persists.
  Future<Inventory> grantBooster(BoosterType type, [int count = 1]) async {
    final inv = await load();
    final updated = inv.addBooster(type, count);
    await save(updated);
    return updated;
  }

  /// Atomically uses a booster if available. Returns null if not available.
  Future<Inventory?> useBooster(BoosterType type) async {
    final inv = await load();
    if (!inv.hasBooster(type)) return null;
    final updated = inv.useBooster(type);
    await save(updated);
    return updated;
  }

  /// Atomically grants hint credits and persists.
  Future<Inventory> grantHints([int count = 1]) async {
    final inv = await load();
    final updated = inv.addHints(count);
    await save(updated);
    return updated;
  }

  /// Atomically uses a hint credit. Returns null if none available.
  Future<Inventory?> useHint() async {
    final inv = await load();
    if (!inv.hasHint) return null;
    final updated = inv.useHint();
    await save(updated);
    return updated;
  }

  /// Records a claim (e.g. daily reward) and persists.
  Future<Inventory> recordClaim(String claimKey) async {
    final inv = await load();
    final updated = inv.recordClaim(claimKey);
    await save(updated);
    return updated;
  }

  /// Removes a claim key and persists (e.g. resetting a streak cycle).
  Future<Inventory> removeClaim(String claimKey) async {
    final inv = await load();
    final updated = inv.removeClaim(claimKey);
    await save(updated);
    return updated;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
