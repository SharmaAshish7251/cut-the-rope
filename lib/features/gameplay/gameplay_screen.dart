import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/inventory_item.dart';
import '../../game/candy_game.dart';
import '../../services/reward_service.dart';
import '../hints/hint_overlay.dart';
import '../boosters/booster_overlay.dart';
import '../pause/pause_overlay.dart';
import '../victory/victory_overlay.dart';
import '../victory/grand_finale_screen.dart';
import '../failure/failure_overlay.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  final int levelId;
  const GameplayScreen({super.key, required this.levelId});

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  CandyGame? _game;
  bool _loading = true;
  String? _error;
  GameStatus _status = GameStatus.playing;
  int _score = 0;
  int _stars = 0;
  bool _showPause = false;
  bool _showHintDialog = false;
  bool _showBoosterOverlay = false;
  bool _showOfflineDialog = false;
  String _activeHintText = '';
  bool _showHintBanner = false;

  // Swipe tracking
  Offset? _swipeStart;
  final List<Offset> _swipePoints = [];
  final ValueNotifier<List<Offset>> _swipeNotifier = ValueNotifier<List<Offset>>([]);
  String? _unlockedWorldName;

  @override
  void dispose() {
    _swipeNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLevel();
    ref.read(audioServiceProvider).startBgm();
  }

  Future<void> _loadLevel() async {
    try {
      final level = await ref.read(levelRepositoryProvider).getLevel(widget.levelId);
      final config = await ref.read(gameConfigProvider.future);
      if (!mounted) return;
      setState(() {
        _game = CandyGame(
          level: level,
          ropeCutSensitivity: config.gameplay.ropeCutSensitivityPx,
          onStatusChanged: _onGameStatusChanged,
          audioService: ref.read(audioServiceProvider),
        );
        _activeHintText = level.hintText;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onGameStatusChanged(GameStatus status, int score, int stars) async {
    setState(() {
      _status = status;
      _score = score;
      _stars = stars;
    });
    if (status == GameStatus.victory) {
      final config = await ref.read(gameConfigProvider.future);
      final currentProgress = ref.read(progressProvider).valueOrNull;
      final oldStars = currentProgress?.totalStars ?? 0;
      // Award currency: base 10 + 5 per star
      final currencyReward = 10 + (stars * 5);
      await ref.read(progressProvider.notifier).recordCompletion(
        levelId: widget.levelId,
        score: score,
        stars: stars,
        unlockNext: config.progression.unlockNextLevelOnCompletion,
        maxLevel: config.progression.maxLevel,
        currencyReward: currencyReward,
      );

      // Check if this victory pushed cumulative stars to unlock a new world
      if (!mounted) return;
      final newStars = ref.read(progressProvider).valueOrNull?.totalStars ?? oldStars;
      final reqs = config.progression.worldStarRequirements;
      const worldNames = [
        'Candy Garden', 'Toy Workshop', 'Sky Islands', 'Cookie Caves', 'Jelly Jungle',
        'Frosty Peaks', 'Lollipop Lairs', 'Caramel Cosmos', 'Gummy Galaxy', 'Candy Citadel',
      ];
      for (var i = 1; i < reqs.length; i++) {
        if (oldStars < reqs[i] && newStars >= reqs[i]) {
          setState(() {
            _unlockedWorldName = '${worldNames[i]} (World ${i + 1})';
          });
          break;
        }
      }
    }
  }

  void _restart() {
    setState(() {
      _status = GameStatus.playing;
      _score = 0;
      _stars = 0;
      _showPause = false;
      _showHintDialog = false;
      _showBoosterOverlay = false;
      _showOfflineDialog = false;
      _showHintBanner = false;
      _unlockedWorldName = null;
      _loading = true;
    });
    _loadLevel();
  }

  // ── Hint flow ─────────────────────────────────────────────────────────

  void _onHintTap() {
    if (_status == GameStatus.playing) _game?.pauseGame();
    setState(() => _showHintDialog = true);
  }

  Future<void> _onUseHint() async {
    final rewardService = ref.read(rewardServiceProvider);
    final (outcome, inv) = await rewardService.useHint();
    if (!mounted) return;

    if (outcome == RewardOutcome.granted && inv != null) {
      ref.read(inventoryProvider.notifier).updateInventory(inv);
      ref.read(audioServiceProvider).playBooster();

      final wasFailed = _status == GameStatus.failure;
      if (wasFailed) {
        _restart();
      }

      // Show hint text and highlight rope
      _game?.highlightBestRope();
      setState(() {
        _showHintDialog = false;
        _showHintBanner = true;
      });
      _game?.resumeGame();
    } else {
      // No credits — shouldn't happen since button is guarded, but handle anyway
      setState(() => _showHintDialog = false);
      if (_status == GameStatus.playing) _game?.resumeGame();
    }
  }

  Future<void> _onEarnHint() async {
    final rewardService = ref.read(rewardServiceProvider);
    final (outcome, inv) = await rewardService.earnHint();
    if (!mounted) return;

    switch (outcome) {
      case RewardOutcome.granted:
        if (inv != null) ref.read(inventoryProvider.notifier).updateInventory(inv);
        ref.read(audioServiceProvider).playBooster();
        // Now the player has credits — refresh the dialog
        setState(() {});
        break;
      case RewardOutcome.offline:
        setState(() {
          _showHintDialog = false;
          _showOfflineDialog = true;
        });
        break;
      case RewardOutcome.adCancelled:
      case RewardOutcome.adFailed:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(outcome == RewardOutcome.adCancelled
                  ? 'Ad was cancelled'
                  : 'Ad failed to load. Try again later.'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        break;
      case RewardOutcome.noInventory:
        break;
    }
  }

  // ── Booster flow ──────────────────────────────────────────────────────

  void _onBoosterTap() {
    if (_status == GameStatus.playing) _game?.pauseGame();
    setState(() => _showBoosterOverlay = true);
  }

  Future<void> _onActivateBooster(BoosterType type) async {
    final rewardService = ref.read(rewardServiceProvider);
    final (outcome, inv) = await rewardService.useBooster(type);
    if (!mounted) return;

    if (outcome == RewardOutcome.granted && inv != null) {
      ref.read(inventoryProvider.notifier).updateInventory(inv);

      final wasFailed = _status == GameStatus.failure;
      if (wasFailed) {
        _restart();
      } else {
        setState(() => _showBoosterOverlay = false);
        _game?.resumeGame();
      }

      // Apply booster effect
      switch (type) {
        case BoosterType.ropeCutter:
          _game?.highlightBestRope();
          break;
        case BoosterType.slowMotion:
          _game?.activateSlowMotion();
          break;
        case BoosterType.candyRescue:
          _game?.activateCandyRescue();
          break;
        case BoosterType.trajectoryShow:
          _game?.activateTrajectoryPreview();
          break;
      }
      ref.read(audioServiceProvider).playBooster();
      if (wasFailed) {
        setState(() => _showBoosterOverlay = false);
      }
    }
  }

  Future<void> _onEarnBooster(BoosterType type) async {
    final rewardService = ref.read(rewardServiceProvider);
    final (outcome, inv) = await rewardService.earnBooster(type);
    if (!mounted) return;

    switch (outcome) {
      case RewardOutcome.granted:
        if (inv != null) ref.read(inventoryProvider.notifier).updateInventory(inv);
        ref.read(audioServiceProvider).playBooster();
        setState(() {}); // refresh counts
        break;
      case RewardOutcome.offline:
        setState(() {
          _showBoosterOverlay = false;
          _showOfflineDialog = true;
        });
        break;
      case RewardOutcome.adCancelled:
      case RewardOutcome.adFailed:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(outcome == RewardOutcome.adCancelled
                  ? 'Ad was cancelled'
                  : 'Ad failed to load. Try again later.'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        break;
      case RewardOutcome.noInventory:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load level', style: AppTheme.headline),
              const SizedBox(height: 8),
              Text(_error!, style: AppTheme.caption),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.levelSelection),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final inventoryAsync = ref.watch(inventoryProvider);
    final inventory = inventoryAsync.valueOrNull ?? const Inventory();
    final worldIdx = ((widget.levelId - 1) ~/ 10).clamp(0, 9);
    final theme = _worldThemes[worldIdx];

    return Scaffold(
      backgroundColor: theme.colors.first,
      body: Stack(
        children: [
          // Dynamic World Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.colors,
                ),
              ),
            ),
          ),

          // Decorative World Icons & Shapes
          Positioned(
            top: 70,
            left: -20,
            child: _CloudShape(size: 130, color: Colors.white.withValues(alpha: 0.55)),
          ),
          Positioned(
            top: 140,
            right: -20,
            child: Icon(theme.icon, size: 110, color: theme.shapeColor),
          ),
          Positioned(
            bottom: 220,
            left: 20,
            child: Icon(theme.icon, size: 80, color: theme.shapeColor.withValues(alpha: 0.15)),
          ),

          // Game canvas wrapped with GestureDetector for swipe-to-cut
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                _swipeStart = details.localPosition;
                _swipePoints.clear();
                _swipePoints.add(details.localPosition);
                _swipeNotifier.value = List.of(_swipePoints);
              },
              onPanEnd: (details) {
                _swipeStart = null;
                _swipePoints.clear();
                _swipeNotifier.value = const [];
              },
              onPanCancel: () {
                _swipeStart = null;
                _swipePoints.clear();
                _swipeNotifier.value = const [];
              },
              onPanUpdate: (details) {
                if (_swipeStart != null && _game != null) {
                  _game!.handleSwipe(
                    _swipeStart!.dx,
                    _swipeStart!.dy,
                    details.localPosition.dx,
                    details.localPosition.dy,
                  );
                  _swipeStart = details.localPosition;
                }
                _swipePoints.add(details.localPosition);
                if (_swipePoints.length > 8) {
                  _swipePoints.removeAt(0);
                }
                _swipeNotifier.value = List.of(_swipePoints);
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GameWidget(
                      key: ObjectKey(_game),
                      game: _game!,
                    ),
                  ),
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: ValueListenableBuilder<List<Offset>>(
                        valueListenable: _swipeNotifier,
                        builder: (_, points, __) {
                          if (points.length < 2) return const SizedBox.shrink();
                          return IgnorePointer(
                            child: CustomPaint(
                              painter: _SwipeTrailPainter(points: points),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HUD overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HudButton(
                    icon: Icons.pause_rounded,
                    onTap: () {
                      _game?.pauseGame();
                      ref.read(audioServiceProvider).pauseBgMusic();
                      setState(() => _showPause = true);
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: AppTheme.cardLip, offset: Offset(0, 3), blurRadius: 0),
                      ],
                    ),
                    child: Text(
                      'Level ${widget.levelId}',
                      style: AppTheme.label.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _HudButton(
                        icon: Icons.lightbulb_outline_rounded,
                        onTap: _status == GameStatus.playing ? _onHintTap : null,
                        badge: inventory.hintCredits > 0 ? '${inventory.hintCredits}' : null,
                      ),
                      const SizedBox(width: 6),
                      _HudButton(
                        icon: Icons.bolt_rounded,
                        onTap: _status == GameStatus.playing ? _onBoosterTap : null,
                      ),
                      const SizedBox(width: 6),
                      _HudButton(icon: Icons.refresh_rounded, onTap: _restart),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Star counter
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 56),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.star_rounded,
                      size: 28,
                      color: i < _stars ? AppTheme.accent : Colors.white38,
                    ),
                  )),
                ),
              ),
            ),
          ),

          // Level 1 tutorial overlay for first-time players
          if (widget.levelId == 1 && _status == GameStatus.playing && _game != null && _game!.ropes.length >= 2)
            _Level1TutorialGuideOverlay(),

          // Hint banner (shown after using a hint)
          if (_showHintBanner)
            HintBanner(
              hintText: _activeHintText,
              onDismiss: () {
                setState(() => _showHintBanner = false);
                _game?.clearHighlights();
              },
            ),

          // Victory overlay / Grand Finale
          if (_status == GameStatus.victory)
            Positioned.fill(
              child: widget.levelId == 100
                  ? GrandFinaleScreen(
                      totalStars: ref.watch(progressProvider).asData?.value.totalStars ?? 0,
                      finalScore: _score,
                      onReplay: _restart,
                    )
                  : VictoryOverlay(
                      score: _score,
                      stars: _stars,
                      levelId: widget.levelId,
                      currencyEarned: 10 + (_stars * 5),
                      unlockedWorldName: _unlockedWorldName,
                      onReplay: _restart,
                      onNext: widget.levelId < 100
                          ? () => context.pushReplacement('/play/${widget.levelId + 1}')
                          : null,
                      onLevelMap: () => context.go(AppRoutes.levelSelection),
                    ),
            ),

          // Failure overlay (hidden while interactive dialogs are open)
          if (_status == GameStatus.failure && !_showBoosterOverlay && !_showHintDialog && !_showOfflineDialog)
            Positioned.fill(
              child: FailureOverlay(
                onRetry: _restart,
                onHome: () => context.go(AppRoutes.home),
                onLevelMap: () => context.go(AppRoutes.levelSelection),
                onHint: _onHintTap,
                onBooster: _onBoosterTap,
              ),
            ),

          // Pause overlay
          if (_showPause)
            Positioned.fill(
              child: PauseOverlay(
                onResume: () {
                  _game?.resumeGame();
                  ref.read(audioServiceProvider).resumeBgMusic();
                  setState(() => _showPause = false);
                },
                onRestart: _restart,
                onHome: () => context.go(AppRoutes.home),
                onLevelMap: () => context.go(AppRoutes.levelSelection),
              ),
            ),

          // Booster overlay (Interactive modal rendered in front)
          if (_showBoosterOverlay)
            Positioned.fill(
              child: BoosterOverlay(
                inventory: inventory,
                onActivate: _onActivateBooster,
                onEarn: _onEarnBooster,
                onCancel: () {
                  setState(() => _showBoosterOverlay = false);
                  if (_status == GameStatus.playing) _game?.resumeGame();
                },
              ),
            ),

          // Hint dialog (Interactive modal rendered in front)
          if (_showHintDialog)
            Positioned.fill(
              child: HintDialog(
                hasCredits: inventory.hasHint,
                creditCount: inventory.hintCredits,
                hintText: _activeHintText,
                onUseHint: _onUseHint,
                onEarnHint: _onEarnHint,
                onCancel: () {
                  setState(() => _showHintDialog = false);
                  if (_status == GameStatus.playing) _game?.resumeGame();
                },
              ),
            ),

          // Offline dialog (Interactive modal rendered in front)
          if (_showOfflineDialog)
            Positioned.fill(
              child: HintOfflineDialog(
                onDismiss: () {
                  setState(() => _showOfflineDialog = false);
                  if (_status == GameStatus.playing) _game?.resumeGame();
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── HUD Widgets ──────────────────────────────────────────────────────────────

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? badge;
  const _HudButton({required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(color: AppTheme.cardLip, offset: Offset(0, 4), blurRadius: 0),
              ],
            ),
            child: Icon(
              icon,
              color: onTap != null ? AppTheme.primaryOrange : Colors.grey.shade400,
              size: 24,
            ),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.goldYellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.goldLip, offset: Offset(0, 2), blurRadius: 0),
                  ],
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeTrailPainter extends CustomPainter {
  final List<Offset> points;
  _SwipeTrailPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final progress = (i + 1) / points.length;
      final width = (progress * 6.0) + 1.5;

      // Glow outline
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = const Color(0x66FFD166)
          ..strokeWidth = width + 6.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );

      // Core razor blade
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SwipeTrailPainter oldDelegate) => true;
}

class _CloudShape extends StatelessWidget {
  final double size;
  final Color color;
  const _CloudShape({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

class _Level1TutorialGuideOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dashed guide line
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  10,
                  (_) => Container(
                    width: 10,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Interactive gesture badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppTheme.accent, size: 22)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveX(begin: -18, end: 18, duration: 800.ms),
                    const SizedBox(width: 8),
                    Text(
                      'Slide your finger to cut the rope!',
                      style: AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldTheme {
  final List<Color> colors;
  final IconData icon;
  final Color shapeColor;

  const _WorldTheme({
    required this.colors,
    required this.icon,
    required this.shapeColor,
  });
}

final _worldThemes = [
  // World 1: Candy Garden
  _WorldTheme(
    colors: [Color(0xFFFFF4E8), Color(0xFFFFE8D6), Color(0xFFE8F5E9)],
    icon: Icons.grass_rounded,
    shapeColor: Color(0x3381C784),
  ),
  // World 2: Toy Workshop
  _WorldTheme(
    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2), Color(0xFFFFCC80)],
    icon: Icons.extension_rounded,
    shapeColor: Color(0x33FFB74D),
  ),
  // World 3: Sky Islands
  _WorldTheme(
    colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF80DEEA)],
    icon: Icons.cloud_rounded,
    shapeColor: Color(0x4480DEEA),
  ),
  // World 4: Cookie Caves
  _WorldTheme(
    colors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8), Color(0xFFBCAAA4)],
    icon: Icons.cookie_rounded,
    shapeColor: Color(0x33A1887F),
  ),
  // World 5: Jelly Jungle
  _WorldTheme(
    colors: [Color(0xFFE8F8F5), Color(0xFFA3E4D7), Color(0xFF76D7C4)],
    icon: Icons.forest_rounded,
    shapeColor: Color(0x3348C9B0),
  ),
  // World 6: Frosty Peaks
  _WorldTheme(
    colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
    icon: Icons.ac_unit_rounded,
    shapeColor: Color(0x4438BDF8),
  ),
  // World 7: Magic Kingdom
  _WorldTheme(
    colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7), Color(0xFFCE93D8)],
    icon: Icons.auto_awesome_rounded,
    shapeColor: Color(0x33AB47BC),
  ),
  // World 8: Cyber City
  _WorldTheme(
    colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC), Color(0xFFB0BEC5)],
    icon: Icons.memory_rounded,
    shapeColor: Color(0x3378909C),
  ),
  // World 9: Cosmic Realm
  _WorldTheme(
    colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9), Color(0xFFB39DDB)],
    icon: Icons.auto_awesome_mosaic_rounded,
    shapeColor: Color(0x337E57C2),
  ),
  // World 10: Candy Citadel
  _WorldTheme(
    colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFE082)],
    icon: Icons.fort_rounded,
    shapeColor: Color(0x33FFCA28),
  ),
];



