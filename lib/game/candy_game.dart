import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import '../data/models/level_model.dart';
import '../services/audio_service.dart';
import 'components/candy_component.dart';
import 'components/rope_component.dart';
import 'components/star_component.dart';
import 'components/monster_component.dart';
import 'components/obstacle_component.dart';
import 'components/particle_effect_component.dart';
import 'systems/level_state_manager.dart';

enum GameStatus { playing, paused, victory, failure }

/// The main Forge2D game for Cut the Cable.
/// Fixed world playfield (12x18m) with dynamic viewport scaling.
class CandyGame extends Forge2DGame {
  final LevelModel level;
  final double ropeCutSensitivity;
  final void Function(GameStatus status, int score, int stars) onStatusChanged;
  final AudioService? audioService;

  static const double playfieldWidth = 12.0;
  static const double playfieldHeight = 18.0;

  late CandyComponent candy;
  late MonsterComponent monster;
  final List<RopeComponent> ropes = [];
  final List<StarComponent> stars = [];
  final List<ObstacleComponent> obstacles = [];
  late LevelStateManager _stateManager;

  GameStatus _status = GameStatus.playing;
  bool get isPlaying => _status == GameStatus.playing;
  bool get isFailing => _isFailing;

  // ── Booster state ──────────────────────────────────────────────────────
  double _timeScale = 1.0;
  double _slowMotionRemaining = 0;
  bool _candyRescueActive = false;
  bool _isFailing = false;
  double _failTimer = 0;

  CandyGame({
    required this.level,
    required this.onStatusChanged,
    this.ropeCutSensitivity = 20.0,
    this.audioService,
  }) : super(
          gravity: Vector2(
            0,
            (level.physicsOverrides['gravity'] as num?)?.toDouble().abs() ?? 16.0,
          ),
        );

  @override
  Color backgroundColor() => const Color(0x00000000);

  void _updateCamera() {
    if (size.x <= 0 || size.y <= 0) return;
    // Scale to fit the playfield inside the screen with top & bottom margins
    final scaleX = size.x / (playfieldWidth + 2.0);
    final scaleY = size.y / (playfieldHeight + 3.5);
    final zoom = math.min(scaleX, scaleY).clamp(8.0, 120.0);

    camera.viewfinder.zoom = zoom;
    camera.viewfinder.position = Vector2(playfieldWidth / 2, playfieldHeight / 2);
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateCamera();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _updateCamera();

    // 1. Candy
    candy = CandyComponent(
      position: Vector2(
        level.candy.x * playfieldWidth,
        level.candy.y * playfieldHeight,
      ),
    );
    await world.add(candy);

    // 2. Monster
    monster = MonsterComponent(
      position: Vector2(
        level.monster.x * playfieldWidth,
        level.monster.y * playfieldHeight,
      ),
      onCandyDelivered: _handleVictory,
    );
    await world.add(monster);

    // 3. Ropes
    for (final rd in level.ropes) {
      final rope = RopeComponent(
        id: rd.id,
        anchorPosition: Vector2(
          rd.anchorX * playfieldWidth,
          rd.anchorY * playfieldHeight,
        ),
        candyBody: candy.body,
        length: rd.length,
        cuttable: rd.cuttable,
      );
      ropes.add(rope);
      await world.add(rope);
    }

    // 4. Stars
    for (final sd in level.stars) {
      final star = StarComponent(
        id: sd.id,
        position: Vector2(
          sd.x * playfieldWidth,
          sd.y * playfieldHeight,
        ),
        onCollected: _handleStarCollected,
      );
      stars.add(star);
      await world.add(star);
    }

    // 5. Obstacles
    for (final od in level.obstacles) {
      if (od.type == 'none') continue;
      final obstacle = ObstacleComponent(
        type: od.type,
        position: Vector2(
          od.x * playfieldWidth,
          od.y * playfieldHeight,
        ),
        width: od.width * playfieldWidth,
        height: od.height * playfieldHeight,
      );
      obstacles.add(obstacle);
      await world.add(obstacle);
    }

    // 6. Boundaries
    await _addBoundaries(playfieldWidth, playfieldHeight);

    // 7. State manager
    _stateManager = LevelStateManager(
      level: level,
      totalStars: level.stars.length,
      onVictory: _handleVictory,
      onFailure: _handleFailure,
    );
  }

  Future<void> _addBoundaries(double w, double h) async {
    // Ceiling
    await world.add(_Wall(Vector2(0, 0), Vector2(w, 0)));
    // Left
    await world.add(_Wall(Vector2(0, 0), Vector2(0, h + 2.0)));
    // Right
    await world.add(_Wall(Vector2(w, 0), Vector2(w, h + 2.0)));
    // Floor (set slightly below the monster)
    await world.add(_Wall(Vector2(0, h + 2.0), Vector2(w, h + 2.0)));
  }

  void _handleStarCollected(String id) {
    _stateManager.recordStarCollected(id);
    HapticFeedback.mediumImpact();
    audioService?.playStarCollect();
  }

  void _handleVictory() {
    if (_status != GameStatus.playing) return;
    _status = GameStatus.victory;
    world.add(
      ParticleEffectComponent(
        origin: candy.body.position,
        type: FxParticleType.candyCrumbs,
      ),
    );
    pauseEngine();
    HapticFeedback.heavyImpact();
    audioService?.playNomNom();
    audioService?.playLevelComplete();
    final score = _stateManager.calculateScore();
    final s = _stateManager.calculateStars(score);
    onStatusChanged(GameStatus.victory, score, s);
  }

  void handleObstacleHit() {
    if (_status != GameStatus.playing) return;
    _handleFailure();
  }

  void _handleFailure() {
    if (_status != GameStatus.playing) return;

    // Candy rescue: prevent one failure
    if (_candyRescueActive) {
      _candyRescueActive = false;
      _rescueCandy();
      audioService?.playBooster();
      return;
    }

    _status = GameStatus.failure;
    pauseEngine();
    HapticFeedback.vibrate();
    audioService?.playLevelFail();
    onStatusChanged(GameStatus.failure, 0, 0);
  }

  void _rescueCandy() {
    _isFailing = false;
    _failTimer = 0;
    candy.body.setTransform(
      Vector2(level.candy.x * playfieldWidth, level.candy.y * playfieldHeight),
      0,
    );
    candy.body.linearVelocity = Vector2.zero();
    candy.body.angularVelocity = 0;
  }

  /// Called from Flutter gesture layer with screen-space coordinates.
  void handleSwipe(double startX, double startY, double endX, double endY) {
    if (!isPlaying) return;
    final worldStart = screenToWorld(Vector2(startX, startY));
    final worldEnd   = screenToWorld(Vector2(endX,   endY));

    // Pop bubble if swipe passes near candy inside bubble
    if (candy.isMounted && candy.inBubble) {
      final candyPos = candy.body.position;
      if ((candyPos - worldEnd).length <= CandyComponent.radius * 2.2) {
        candy.inBubble = false;
        audioService?.playBubblePop();
        HapticFeedback.lightImpact();
      }
    }

    for (final rope in List<RopeComponent>.from(ropes)) {
      if (!rope.cuttable || rope.isCut) continue;
      if (rope.intersectsSwipe(worldStart, worldEnd, ropeCutSensitivity)) {
        rope.cut();
        ropes.remove(rope);
        world.add(
          ParticleEffectComponent(
            origin: (worldStart + worldEnd) / 2,
            type: FxParticleType.ropeSparks,
          ),
        );
        HapticFeedback.lightImpact();
        audioService?.playRopeCut();
        break;
      }
    }
  }

  void pauseGame() {
    if (_status != GameStatus.playing) return;
    _status = GameStatus.paused;
    pauseEngine();
  }

  void resumeGame() {
    if (_status != GameStatus.paused) return;
    _status = GameStatus.playing;
    resumeEngine();
  }

  // ── Booster actions ────────────────────────────────────────────────────

  void activateSlowMotion({double seconds = 5.0}) {
    _timeScale = 0.35;
    _slowMotionRemaining = seconds;
    audioService?.playBooster();
  }

  void activateCandyRescue() {
    _candyRescueActive = true;
    audioService?.playBooster();
  }

  void activateTrajectoryPreview() {
    audioService?.playBooster();
  }

  void highlightRope(String ropeId) {
    for (final rope in ropes) {
      rope.highlighted = rope.id == ropeId;
    }
  }

  void highlightBestRope() {
    final target = ropes.where((r) => r.cuttable && !r.isCut).firstOrNull;
    if (target != null) highlightRope(target.id);
  }

  void clearHighlights() {
    for (final rope in ropes) {
      rope.highlighted = false;
    }
  }

  @override
  void update(double dt) {
    if (_status == GameStatus.playing) {
      // Bubble buoyancy (floating upward when enclosed in a bubble)
      if (candy.isMounted && candy.inBubble) {
        candy.body.applyForce(Vector2(0, -22.0));
      }

      // If only 1 rope remains, motion must NOT be slow (full momentum swing)
      // so the player must time their slice well to launch into the monster.
      final activeRopes = ropes.where((r) => !r.isCut).toList();
      if (activeRopes.length == 1 && candy.isMounted) {
        if (_slowMotionRemaining <= 0) {
          _timeScale = 1.0;
        }
        candy.body.linearDamping = 0.0;
        candy.body.angularDamping = 0.0;

        final lastRope = activeRopes.first;
        final toCandy = candy.body.position - lastRope.anchorPosition;
        final dist = toCandy.length;
        if (dist > 0.2) {
          final tangent = Vector2(-toCandy.y, toCandy.x).normalized();
          final speedAlongTangent = candy.body.linearVelocity.dot(tangent);

          // Angle ratio from vertical (0 at bottom, ~0.7 at 45 degrees)
          final sinTheta = (toCandy.x / dist).abs();
          final isNearBottom = sinTheta < 0.55;

          // Target dynamic swing speed based on rope length
          final targetSpeed = math.sqrt(2.0 * 16.0 * dist * 0.22).clamp(3.5, 6.0);
          final isStalled = speedAlongTangent.abs() < 0.3;
          final isTooSlow = speedAlongTangent.abs() < targetSpeed;

          if (isStalled || (isNearBottom && isTooSlow)) {
            double swingDir;
            if (speedAlongTangent.abs() > 0.2) {
              swingDir = speedAlongTangent > 0 ? 1.0 : -1.0;
            } else {
              final towardsMonsterX = monster.body.position.x - candy.body.position.x;
              swingDir = (towardsMonsterX * tangent.x > 0) ? 1.0 : -1.0;
            }
            final forceMag = candy.body.mass * 14.0;
            candy.body.applyForce(tangent * (swingDir * forceMag));
          }
        }
      }

      final scaledDt = dt * _timeScale;
      super.update(scaledDt);

      if (_slowMotionRemaining > 0) {
        _slowMotionRemaining -= dt;
        if (_slowMotionRemaining <= 0) {
          _timeScale = 1.0;
          _slowMotionRemaining = 0;
        }
      }

      // Proximity check for star collection
      for (final star in List<StarComponent>.from(stars)) {
        if (!star.isCollected && candy.isMounted && star.isMounted) {
          final dist = (candy.body.position - star.body.position).length;
          if (dist <= (StarComponent.radius + CandyComponent.radius * 0.9)) {
            star.collect();
          }
        }
      }

      // Proximity check for monster catching candy
      if (candy.isMounted && monster.isMounted) {
        final dist = (candy.body.position - monster.body.position).length;
        if (dist <= (MonsterComponent.radius + CandyComponent.radius * 0.95)) {
          _handleVictory();
          return;
        }
      }

      // Floor check for game over: let ball hit/bounce on floor before showing failure overlay
      if (candy.isMounted && candy.body.position.y >= playfieldHeight - 0.8) {
        if (!_isFailing) {
          _isFailing = true;
          HapticFeedback.vibrate();
          audioService?.playLevelFail();
        }
        _failTimer += scaledDt;
        if (_failTimer >= 0.45) {
          _handleFailure();
          return;
        }
      }

      _stateManager.tick(
        scaledDt,
        candy,
        playfieldWidth: playfieldWidth,
        playfieldHeight: playfieldHeight,
      );
    } else {
      super.update(dt);
    }
  }
}

class _Wall extends BodyComponent {
  final Vector2 _s, _e;
  _Wall(this._s, this._e) : super(renderBody: false);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(_s, _e);
    final bodyDef = BodyDef()..type = BodyType.static;
    return world.createBody(bodyDef)
      ..createFixture(FixtureDef(shape)..friction = 0.3);
  }
}
