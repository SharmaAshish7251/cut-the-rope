/// Booster types available in the game.
enum BoosterType {
  ropeCutter,    // Highlights the best rope to cut
  slowMotion,    // Slows physics for 5 seconds
  candyRescue,   // Saves candy from one failure
  trajectoryShow, // Previews candy path
}

extension BoosterTypeX on BoosterType {
  String get displayName {
    switch (this) {
      case BoosterType.ropeCutter:    return 'Rope Cutter';
      case BoosterType.slowMotion:    return 'Slow Motion';
      case BoosterType.candyRescue:   return 'Candy Rescue';
      case BoosterType.trajectoryShow: return 'Trajectory Show';
    }
  }

  String get emoji {
    switch (this) {
      case BoosterType.ropeCutter:    return '🪄';
      case BoosterType.slowMotion:    return '⏱';
      case BoosterType.candyRescue:   return '🛡';
      case BoosterType.trajectoryShow: return '🎯';
    }
  }

  String get description {
    switch (this) {
      case BoosterType.ropeCutter:    return 'Highlights the best rope to cut next';
      case BoosterType.slowMotion:    return 'Slows time for 5 seconds';
      case BoosterType.candyRescue:   return 'Saves the candy if it falls';
      case BoosterType.trajectoryShow: return 'Preview candy path before cutting';
    }
  }

  String get key => name; // serialization key
}

/// Player's inventory of consumable items.
class Inventory {
  final Map<BoosterType, int> boosters;
  final int hintCredits;
  final Map<String, DateTime> claimHistory; // e.g. "daily_2024-01-15"

  const Inventory({
    this.boosters = const {},
    this.hintCredits = 0,
    this.claimHistory = const {},
  });

  int boosterCount(BoosterType type) => boosters[type] ?? 0;
  bool hasBooster(BoosterType type) => boosterCount(type) > 0;
  bool get hasHint => hintCredits > 0;

  Inventory copyWith({
    Map<BoosterType, int>? boosters,
    int? hintCredits,
    Map<String, DateTime>? claimHistory,
  }) =>
      Inventory(
        boosters: boosters ?? Map.from(this.boosters),
        hintCredits: hintCredits ?? this.hintCredits,
        claimHistory: claimHistory ?? Map.from(this.claimHistory),
      );

  Inventory addBooster(BoosterType type, [int count = 1]) {
    final updated = Map<BoosterType, int>.from(boosters);
    updated[type] = (updated[type] ?? 0) + count;
    return copyWith(boosters: updated);
  }

  Inventory useBooster(BoosterType type) {
    final current = boosterCount(type);
    if (current <= 0) return this;
    final updated = Map<BoosterType, int>.from(boosters);
    updated[type] = current - 1;
    return copyWith(boosters: updated);
  }

  Inventory addHints([int count = 1]) =>
      copyWith(hintCredits: hintCredits + count);

  Inventory useHint() {
    if (hintCredits <= 0) return this;
    return copyWith(hintCredits: hintCredits - 1);
  }

  Inventory recordClaim(String claimKey) {
    final updated = Map<String, DateTime>.from(claimHistory);
    updated[claimKey] = DateTime.now();
    return copyWith(claimHistory: updated);
  }

  /// Removes a previously recorded claim key (e.g., to reset a streak cycle).
  Inventory removeClaim(String claimKey) {
    final updated = Map<String, DateTime>.from(claimHistory);
    updated.remove(claimKey);
    return copyWith(claimHistory: updated);
  }

  bool hasClaimed(String claimKey) => claimHistory.containsKey(claimKey);

  // ── Serialization ────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'boosters': boosters.map((k, v) => MapEntry(k.key, v)),
        'hintCredits': hintCredits,
        'claimHistory': claimHistory.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
      };

  factory Inventory.fromJson(Map<String, dynamic> j) {
    final rawBoosters = j['boosters'] as Map<String, dynamic>? ?? {};
    final boosters = <BoosterType, int>{};
    for (final entry in rawBoosters.entries) {
      final type = BoosterType.values.where((t) => t.key == entry.key).firstOrNull;
      if (type != null) boosters[type] = entry.value as int;
    }

    final rawClaims = j['claimHistory'] as Map<String, dynamic>? ?? {};
    final claims = rawClaims.map(
      (k, v) => MapEntry(k, DateTime.tryParse(v as String) ?? DateTime.now()),
    );

    return Inventory(
      boosters: boosters,
      hintCredits: j['hintCredits'] as int? ?? 0,
      claimHistory: claims,
    );
  }
}
