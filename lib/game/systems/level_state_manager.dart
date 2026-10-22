import '../../data/models/level_model.dart';
import '../components/candy_component.dart';

typedef VoidCallback = void Function();

class LevelStateManager {
  final LevelModel level;
  final int totalStars;
  final VoidCallback onVictory;
  final VoidCallback onFailure;

  final Set<String> _collectedStars = {};
  double _elapsed = 0;
  bool _ended = false;

  LevelStateManager({
    required this.level,
    required this.totalStars,
    required this.onVictory,
    required this.onFailure,
  });

  void recordStarCollected(String id) => _collectedStars.add(id);

  void tick(
    double dt,
    CandyComponent candy, {
    double playfieldWidth = 12.0,
    double playfieldHeight = 18.0,
  }) {
    if (_ended) return;
    _elapsed += dt;
    // Side & ceiling out-of-bounds check only.
    // Floor failure is handled exclusively by CandyGame._failTimer so the
    // candy's bounce animation plays for ~0.45s before the failure overlay appears.
    final pos = candy.body.position;
    if (pos.x < -3.0 ||
        pos.x > playfieldWidth + 3.0 ||
        pos.y < -4.0) {
      _ended = true;
      onFailure();
    }
  }

  int calculateScore() {
    const base      = 3000;
    final starBonus = _collectedStars.length * 800;
    final timeBonus = (30 - _elapsed).clamp(0, 30).toInt() * 50;
    return base + starBonus + timeBonus;
  }

  int calculateStars([int? score]) {
    // In Cut the Rope, stars earned on victory directly represent the physical
    // stars collected in the level. Collecting all 3 stars guarantees 3 stars.
    if (totalStars > 0 || _collectedStars.isNotEmpty) {
      return _collectedStars.length.clamp(0, 3);
    }
    if (score != null) {
      return level.scoring.starsForScore(score).clamp(0, 3);
    }
    return 0;
  }
}
