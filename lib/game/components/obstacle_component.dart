import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import '../candy_game.dart';
import 'candy_component.dart';
import 'rope_component.dart';

class ObstacleComponent extends BodyComponent<CandyGame> with ContactCallbacks {
  final String type;
  final Vector2 _pos;
  final double width;
  final double height;

  Vector2 _moveDir = Vector2(1, 0);
  double _moveDist = 0;
  final double _maxDist = 3.0;
  final double _speed = 1.5;
  bool get _isMoving => type.contains('moving');

  // Obstacle specific animations and states
  double _animTime = 0.0;
  double _laserTimer = 0.0;
  double _teleportCooldown = 0.0;

  bool get isLaserActive => (type.contains('laser')) ? (_laserTimer % 3.5) < 2.0 : false;
  double get sawRadius => width / 2;

  ObstacleComponent({
    required this.type,
    required Vector2 position,
    required this.width,
    required this.height,
  })  : _pos = position.clone(),
        super(renderBody: false);

  @override
  void beginContact(Object other, Contact contact) {
    if (other is CandyComponent) {
      if (type.contains('spike')) {
        game.handleObstacleHit();
      } else if (type.contains('saw')) {
        game.handleObstacleHit();
      } else if (type.contains('laser')) {
        if (isLaserActive) {
          game.handleObstacleHit();
        }
      } else if (type.contains('portal')) {
        _handlePortalTeleport(other);
      } else if (type.contains('bounce') || type.contains('bumper')) {
        _handleBumperBounce(other);
      } else if (type.contains('bubble')) {
        other.inBubble = true;
        game.audioService?.playBubblePop();
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handlePortalTeleport(CandyComponent candy) {
    if (_teleportCooldown > 0) return;
    _teleportCooldown = 0.6;

    // Find other portal in game
    ObstacleComponent? otherPortal;
    for (final obs in game.obstacles) {
      if (obs != this && obs.type.contains('portal')) {
        otherPortal = obs;
        break;
      }
    }

    if (otherPortal != null) {
      otherPortal._teleportCooldown = 0.6;
      final targetPos = otherPortal.body.position;
      final currentVel = candy.body.linearVelocity;
      candy.body.setTransform(targetPos + Vector2(0, 0.6), 0);
      // Preserve velocity magnitude with slight boost
      candy.body.linearVelocity = currentVel.length > 1.0 ? currentVel * 1.1 : Vector2(0, 4.0);
    } else {
      // Single portal: upward boost warp
      final currentVel = candy.body.linearVelocity;
      final newY = math.max(2.5, body.position.y - 5.5);
      candy.body.setTransform(Vector2(body.position.x, newY), 0);
      candy.body.linearVelocity = Vector2(currentVel.x * 0.7, -9.0);
    }

    HapticFeedback.mediumImpact();
    game.audioService?.playBubblePop();
  }

  void _handleBumperBounce(CandyComponent candy) {
    game.audioService?.playBubblePop();
    HapticFeedback.lightImpact();
    // Apply outward bounce impulse
    final diff = candy.body.position - body.position;
    final dir = diff.length > 0.05 ? diff.normalized() : Vector2(0, -1);
    candy.body.applyLinearImpulse(dir * 18.0);
  }

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(width / 2, height / 2, Vector2.zero(), 0);
    final fixDef = FixtureDef(shape)
      ..restitution = (type.contains('bounce') || type.contains('bumper')) ? 0.95 : 0.1
      ..friction = 0.3
      ..isSensor = type.contains('portal') || type.contains('gravity_well');
    final bodyDef = BodyDef()
      ..type = _isMoving ? BodyType.kinematic : BodyType.static
      ..position = _pos;
    return world.createBody(bodyDef)..createFixture(fixDef);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
    if (_teleportCooldown > 0) {
      _teleportCooldown = math.max(0.0, _teleportCooldown - dt);
    }

    // Moving obstacle path logic
    if (_isMoving) {
      _moveDist += _speed * dt;
      if (_moveDist > _maxDist) {
        _moveDir = -_moveDir;
        _moveDist = 0;
      }
      body.linearVelocity = _moveDir * _speed;
    }

    // Laser cycle logic
    if (type.contains('laser')) {
      _laserTimer += dt;
      if (isLaserActive && game.candy.isMounted) {
        // Proximity check for laser beam hazard
        final candyPos = game.candy.body.position;
        final myPos = body.position;
        if ((candyPos.x - myPos.x).abs() <= (width / 2 + CandyComponent.radius * 0.8) &&
            (candyPos.y - myPos.y).abs() <= (height / 2 + CandyComponent.radius * 0.8)) {
          game.handleObstacleHit();
        }
      }
    }

    // Saw blade rope cutting logic
    if (type.contains('saw')) {
      final sawCenter = body.position;
      final cutRadius = sawRadius + 0.15;
      for (final rope in List<RopeComponent>.from(game.ropes)) {
        if (!rope.cuttable || rope.isCut) continue;
        final dist = _distToSegment(sawCenter, rope.segmentStart, rope.segmentEnd);
        if (dist <= cutRadius) {
          rope.cut();
          game.ropes.remove(rope);
          HapticFeedback.lightImpact();
          game.audioService?.playRopeCut();
        }
      }
    }

    // Gravity well radial attraction logic
    if (type.contains('gravity_well') && game.candy.isMounted) {
      final wellPos = body.position;
      final candyPos = game.candy.body.position;
      final diff = wellPos - candyPos;
      final dist = diff.length;
      const influenceRadius = 4.5;
      if (dist < influenceRadius && dist > 0.2) {
        final dir = diff.normalized();
        final forceMagnitude = (35.0 / (dist * dist).clamp(0.6, 16.0)).clamp(2.0, 30.0);
        game.candy.body.applyForce(dir * forceMagnitude);
      }
    }
  }

  double _distToSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final lengthSquared = ab.length2;
    if (lengthSquared == 0) return (p - a).length;
    final t = ((p - a).dot(ab) / lengthSquared).clamp(0.0, 1.0);
    final projection = a + ab * t;
    return (p - projection).length;
  }

  @override
  void render(Canvas canvas) {
    final w = width;
    final h = height;

    if (type.contains('bubble')) {
      _renderBubble(canvas, w);
    } else if (type.contains('spike')) {
      _renderSpikes(canvas, w, h);
    } else if (type.contains('saw')) {
      _renderSaw(canvas, w);
    } else if (type.contains('laser')) {
      _renderLaser(canvas, w, h);
    } else if (type.contains('portal')) {
      _renderPortal(canvas, w, h);
    } else if (type.contains('gravity_well')) {
      _renderGravityWell(canvas, w);
    } else {
      _renderBumper(canvas, w, h);
    }
  }

  void _renderBubble(Canvas canvas, double w) {
    final r = w / 2;
    // Bubble outer glow
    canvas.drawCircle(
      Offset.zero,
      r * 1.1,
      Paint()
        ..color = const Color(0x338B7CF6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15),
    );
    // Bubble body
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = const Color(0x4D8B7CF6),
    );
    // Bubble iris ring
    canvas.drawCircle(
      Offset.zero,
      r * 0.95,
      Paint()
        ..color = const Color(0x80C4B5FD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.06,
    );
    // Specular glint
    canvas.drawCircle(
      Offset(-r * 0.35, -r * 0.35),
      r * 0.28,
      Paint()..color = const Color(0x99FFFFFF),
    );
    canvas.drawCircle(
      Offset(r * 0.35, r * 0.35),
      r * 0.12,
      Paint()..color = const Color(0x66FFFFFF),
    );
  }

  void _renderSpikes(Canvas canvas, double w, double h) {
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);

    // Base bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top + h * 0.6, w, h * 0.4),
        const Radius.circular(0.04),
      ),
      Paint()..color = const Color(0xFF4A1525),
    );

    // Spikes
    const count = 4;
    final step = w / count;
    final spikePath = Path();
    for (var i = 0; i < count; i++) {
      final leftX = rect.left + i * step;
      final midX = leftX + step / 2;
      final rightX = leftX + step;
      spikePath.moveTo(leftX, rect.top + h * 0.6);
      spikePath.lineTo(midX, rect.top);
      spikePath.lineTo(rightX, rect.top + h * 0.6);
    }
    spikePath.close();

    canvas.drawPath(
      spikePath,
      Paint()..color = const Color(0xFFEF4444),
    );
    canvas.drawPath(
      spikePath,
      Paint()
        ..color = const Color(0xFFFCA5A5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03,
    );
  }

  void _renderSaw(Canvas canvas, double w) {
    final r = w / 2;
    final rot = _animTime * (math.pi * 4); // Spinning motion

    canvas.save();
    canvas.rotate(rot);

    // Saw teeth
    const toothCount = 8;
    final sawPath = Path();
    for (var i = 0; i < toothCount; i++) {
      final angle = (i * 2 * math.pi) / toothCount;
      final nextAngle = ((i + 1) * 2 * math.pi) / toothCount;
      final midAngle = angle + (nextAngle - angle) * 0.4;

      final tipR = r * 1.12;
      final baseR = r * 0.85;

      final x1 = math.cos(angle) * baseR;
      final y1 = math.sin(angle) * baseR;
      final x2 = math.cos(midAngle) * tipR;
      final y2 = math.sin(midAngle) * tipR;
      final x3 = math.cos(nextAngle) * baseR;
      final y3 = math.sin(nextAngle) * baseR;

      if (i == 0) {
        sawPath.moveTo(x1, y1);
      }
      sawPath.lineTo(x2, y2);
      sawPath.lineTo(x3, y3);
    }
    sawPath.close();

    // Saw body steel fill
    canvas.drawPath(
      sawPath,
      Paint()..color = const Color(0xFF94A3B8),
    );
    // Blade circular inner core
    canvas.drawCircle(
      Offset.zero,
      r * 0.75,
      Paint()..color = const Color(0xFF64748B),
    );
    // Specular radial shine
    canvas.drawCircle(
      Offset.zero,
      r * 0.55,
      Paint()..color = const Color(0xFFCBD5E1),
    );
    // Center bolt
    canvas.drawCircle(
      Offset.zero,
      r * 0.28,
      Paint()..color = const Color(0xFF334155),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.12,
      Paint()..color = const Color(0xFFE2E8F0),
    );

    canvas.restore();
  }

  void _renderLaser(Canvas canvas, double w, double h) {
    final active = isLaserActive;
    final leftX = -w / 2;
    final rightX = w / 2;

    // Laser emitter poles
    final polePaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(leftX, 0), width: 0.18, height: h * 1.2),
        const Radius.circular(0.04),
      ),
      polePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(rightX, 0), width: 0.18, height: h * 1.2),
        const Radius.circular(0.04),
      ),
      polePaint,
    );

    if (active) {
      // Outer laser glow
      canvas.drawLine(
        Offset(leftX, 0),
        Offset(rightX, 0),
        Paint()
          ..color = const Color(0x9900F0FF)
          ..strokeWidth = 0.22
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.12),
      );
      // Main laser beam
      canvas.drawLine(
        Offset(leftX, 0),
        Offset(rightX, 0),
        Paint()
          ..color = const Color(0xFF00E5FF)
          ..strokeWidth = 0.10
          ..strokeCap = StrokeCap.round,
      );
      // Bright white laser core
      canvas.drawLine(
        Offset(leftX, 0),
        Offset(rightX, 0),
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 0.04
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Inactive warning blinking dots
      final blink = (math.sin(_animTime * 8) > 0);
      final diodeColor = blink ? const Color(0xFFFFB703) : const Color(0xFF553311);
      canvas.drawCircle(Offset(leftX, 0), 0.05, Paint()..color = diodeColor);
      canvas.drawCircle(Offset(rightX, 0), 0.05, Paint()..color = diodeColor);
    }
  }

  void _renderPortal(Canvas canvas, double w, double h) {
    final rX = w / 2;
    final rY = h / 2;
    final rot = _animTime * 3.0;

    // Outer glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 1.2, height: h * 1.2),
      Paint()
        ..color = const Color(0x663B82F6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.20),
    );

    // Portal vortex body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Paint()..color = const Color(0xFF1D4ED8),
    );

    canvas.save();
    canvas.rotate(rot);

    // Inner swirling spiral lines
    final strokePaint = Paint()
      ..color = const Color(0xFF67E8F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04;

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rX * 1.4, height: rY * 0.9),
      strokePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rX * 0.8, height: rY * 0.5),
      strokePaint..color = const Color(0xFFFFFFFF),
    );

    canvas.restore();
  }

  void _renderGravityWell(Canvas canvas, double w) {
    final r = w / 2;
    final rot = _animTime * -2.5;

    // Event horizon outer aura
    canvas.drawCircle(
      Offset.zero,
      r * 1.3,
      Paint()
        ..color = const Color(0x448B5CF6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.25),
    );

    // Black hole / core
    canvas.drawCircle(
      Offset.zero,
      r * 0.85,
      Paint()..color = const Color(0xFF2E1065),
    );

    // Rotating spiral particle arms
    canvas.save();
    canvas.rotate(rot);
    final spiralPaint = Paint()
      ..color = const Color(0xFFD946EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;

    for (var i = 0; i < 4; i++) {
      final angle = (i * math.pi) / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
        angle,
        math.pi / 2.2,
        false,
        spiralPaint,
      );
    }
    canvas.restore();

    // Central bright singularity
    canvas.drawCircle(
      Offset.zero,
      r * 0.2,
      Paint()..color = const Color(0xFFFAF5FF),
    );
  }

  void _renderBumper(Canvas canvas, double w, double h) {
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(0.12));

    canvas.drawRRect(
      rrect,
      Paint()..color = type.contains('bounce') ? const Color(0xFF10B981) : const Color(0xFF8B5E3C),
    );
    // Highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 0.05, rect.top + 0.05, w * 0.4, h * 0.35),
        const Radius.circular(0.05),
      ),
      Paint()..color = const Color(0x4DFFFFFF),
    );
  }
}
