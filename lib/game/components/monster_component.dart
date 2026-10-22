import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/painting.dart' show RadialGradient, Alignment;
import 'package:flame_forge2d/flame_forge2d.dart';
import '../candy_game.dart';
import 'candy_component.dart';

class MonsterComponent extends BodyComponent<CandyGame> with ContactCallbacks {
  final Vector2 _pos;
  final void Function() onCandyDelivered;
  bool _delivered = false;
  static const double radius = 1.3;

  double _animTime = 0;

  MonsterComponent({required Vector2 position, required this.onCandyDelivered})
      : _pos = position.clone(),
        super(renderBody: false);

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final fixDef = FixtureDef(shape)..isSensor = true;
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = _pos;
    final b = world.createBody(bodyDef)..createFixture(fixDef);
    b.userData = this;
    return b;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (_delivered) return;
    if (other is CandyComponent ||
        (other is Fixture && other.body.userData is CandyComponent) ||
        (other is Body && other.userData is CandyComponent)) {
      _delivered = true;
      onCandyDelivered();
    }
  }

  void triggerDelivered() {
    if (_delivered) return;
    _delivered = true;
    onCandyDelivered();
  }

  @override
  void render(Canvas canvas) {
    const r = radius;

    // 1. Wooden/Cardboard Platform under monster ("keep on object")
    const platformRect = Rect.fromLTWH(-r * 1.3, r * 0.65, r * 2.6, r * 0.45);
    final platformRRect = RRect.fromRectAndRadius(platformRect, const Radius.circular(0.18));
    // Platform shadow
    canvas.drawRRect(
      platformRRect.shift(const Offset(0, 0.08)),
      Paint()..color = const Color(0x33000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15),
    );
    // Cardboard/wood fill
    canvas.drawRRect(
      platformRRect,
      Paint()..color = const Color(0xFFD4A373),
    );
    // Platform top highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-r * 1.25, r * 0.67, r * 2.5, r * 0.12),
        const Radius.circular(0.08),
      ),
      Paint()..color = const Color(0xFFFAEDCD),
    );

    // Glow / Drop Shadow under monster
    canvas.drawCircle(
      const Offset(0, 0.12),
      r * 1.15,
      Paint()
        ..color = const Color(0x338B7CF6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.25),
    );

    // Body
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFAA90FF), Color(0xFF6B50D6)],
          center: Alignment(-0.25, -0.35),
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );

    // Horns / Ears
    final hornPaint = Paint()..color = const Color(0xFFFFD166);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-0.75, -1.0), width: 0.45, height: 0.65),
      hornPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0.75, -1.0), width: 0.45, height: 0.65),
      hornPaint,
    );

    // Candy tracking state
    Vector2? candyPos;
    double distToCandy = 10.0;
    var isFailing = false;
    try {
      if (game.candy.isMounted) {
        candyPos = game.candy.body.position;
        distToCandy = (candyPos - body.position).length;
        isFailing = game.isFailing || (candyPos.y > body.position.y + 1.5);
      }
    } catch (_) {}

    // 2. Eyes & Dynamic Tracking
    final blinkPhase = math.sin(_animTime * 6);
    final isBlinkingNow = _delivered || (blinkPhase > 0.95);

    if (isBlinkingNow) {
      // Happy Blinking Eyes (^ ^)
      final eyeStroke = Paint()
        ..color = const Color(0xFF221133)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.12
        ..strokeCap = StrokeCap.round;

      // Left eye happy arc
      final pathLeft = Path()
        ..addArc(Rect.fromCircle(center: const Offset(-0.38, -0.25), radius: 0.28), math.pi, math.pi);
      canvas.drawPath(pathLeft, eyeStroke);

      // Right eye happy arc
      final pathRight = Path()
        ..addArc(Rect.fromCircle(center: const Offset(0.38, -0.25), radius: 0.28), math.pi, math.pi);
      canvas.drawPath(pathRight, eyeStroke);
    } else if (isFailing) {
      // Sad Drooping Eyes on failure / drop
      canvas.drawCircle(const Offset(-0.38, -0.22), 0.35, Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawCircle(const Offset(0.38, -0.22), 0.35, Paint()..color = const Color(0xFFFFFFFF));
      // Pupils looking down with sadness
      canvas.drawCircle(const Offset(-0.38, -0.15), 0.16, Paint()..color = const Color(0xFF221133));
      canvas.drawCircle(const Offset(0.38, -0.15), 0.16, Paint()..color = const Color(0xFF221133));
      // Tear drops
      canvas.drawCircle(const Offset(-0.38, 0.05), 0.08, Paint()..color = const Color(0xFF60A5FA));
      canvas.drawCircle(const Offset(0.38, 0.05), 0.08, Paint()..color = const Color(0xFF60A5FA));
    } else {
      // Open Eyes with Real-Time Pupil Tracking
      canvas.drawCircle(const Offset(-0.38, -0.25), 0.35, Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawCircle(const Offset(0.38, -0.25), 0.35, Paint()..color = const Color(0xFFFFFFFF));

      // Calculate pupil offset vector tracking candy
      var pupilDx = 0.0;
      var pupilDy = -0.10; // Default slightly looking up
      if (candyPos != null) {
        final diff = candyPos - body.position;
        if (diff.length > 0.1) {
          final unit = diff.normalized();
          pupilDx = (unit.x * 0.13).clamp(-0.14, 0.14);
          pupilDy = (unit.y * 0.13).clamp(-0.16, 0.12);
        }
      }

      // Pupils
      canvas.drawCircle(Offset(-0.38 + pupilDx, -0.25 + pupilDy), 0.18, Paint()..color = const Color(0xFF221133));
      canvas.drawCircle(Offset(0.38 + pupilDx, -0.25 + pupilDy), 0.18, Paint()..color = const Color(0xFF221133));
      // Specular shine
      canvas.drawCircle(Offset(-0.32 + pupilDx * 0.8, -0.30 + pupilDy * 0.8), 0.07, Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawCircle(Offset(0.44 + pupilDx * 0.8, -0.30 + pupilDy * 0.8), 0.07, Paint()..color = const Color(0xFFFFFFFF));
    }

    // 3. Mouth Animation (Anticipation / Chewing / Sad Frown)
    if (isFailing) {
      // Sad inverted frown
      final frownPath = Path()
        ..moveTo(-0.55, 0.55)
        ..quadraticBezierTo(0, 0.35, 0.55, 0.55);
      canvas.drawPath(
        frownPath,
        Paint()
          ..color = const Color(0xFF3D1A6E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.12
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Mouth aperture: widen anticipation when candy approaches
      var mouthHeight = 0.70;
      var tongueWiggle = 0.0;
      final chompOffset = _delivered ? math.sin(_animTime * 12).abs() * 0.18 : 0.0;

      if (!_delivered && distToCandy <= 3.5) {
        final excitement = ((3.5 - distToCandy) / 3.5).clamp(0.0, 1.0);
        mouthHeight += excitement * 0.35; // Opens wider
        tongueWiggle = math.sin(_animTime * 16) * 0.06 * excitement;
      }

      // Mouth cavity
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, 0.42 + chompOffset),
          width: 1.35,
          height: (mouthHeight - chompOffset).clamp(0.2, 1.2),
        ),
        Paint()..color = const Color(0xFF3D1A6E),
      );

      // Tongue
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(tongueWiggle, 0.60 + chompOffset),
          width: 0.68,
          height: 0.40,
        ),
        Paint()..color = const Color(0xFFFF6B81),
      );

      // Teeth
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-0.32, 0.08 + chompOffset, 0.22, 0.22),
          const Radius.circular(0.06),
        ),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.10, 0.08 + chompOffset, 0.22, 0.22),
          const Radius.circular(0.06),
        ),
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }

    // Body highlight
    canvas.drawCircle(
      const Offset(-0.45, -0.45),
      0.35,
      Paint()..color = const Color(0x4DFFFFFF),
    );

    // Pulsing aura ring when waiting
    if (!_delivered && !isFailing) {
      canvas.drawCircle(
        Offset.zero,
        r * 1.08,
        Paint()
          ..color = const Color(0x448B7CF6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.08,
      );
    }
  }
}
