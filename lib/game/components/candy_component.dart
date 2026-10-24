import 'dart:ui';
import 'package:flutter/painting.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class CandyComponent extends BodyComponent {
  final Vector2 _initPos;
  static const double radius = 0.7;
  bool inBubble = false;
  Sprite? _candySprite;

  CandyComponent({required Vector2 position})
      : _initPos = position.clone(),
        super(renderBody: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _candySprite = await Sprite.load('candy/candy.png');
    } catch (_) {}
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final fixDef = FixtureDef(shape)
      ..restitution = 0.35
      ..density = 1.2
      ..friction = 0.3;
    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position = _initPos
      ..linearDamping = 0.0
      ..angularDamping = 0.02
      ..bullet = true;
    final b = world.createBody(bodyDef)..createFixture(fixDef);
    b.userData = this;
    return b;
  }

  @override
  void render(Canvas canvas) {
    const r = radius;

    // Shadow
    canvas.drawCircle(
      const Offset(0, 0.08),
      r,
      Paint()
        ..color = const Color(0x40FF6B3D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3),
    );

    if (_candySprite != null) {
      // Render high-res 3D candy sprite
      _candySprite!.renderRect(
        canvas,
        Rect.fromCenter(center: Offset.zero, width: r * 3.0, height: r * 2.2),
      );
    } else {
      // Fallback 3D Gradient Sphere
      final bodyPaint = Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFFAA80), Color(0xFFFF6B3D)],
          center: const Alignment(-0.3, -0.3),
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
      canvas.drawCircle(Offset.zero, r, bodyPaint);
    }

    if (inBubble) {
      // Floating bubble enclosure
      const br = r * 1.4;
      canvas.drawCircle(
        Offset.zero,
        br,
        Paint()..color = const Color(0x4D8B7CF6),
      );
      canvas.drawCircle(
        Offset.zero,
        br,
        Paint()
          ..color = const Color(0x80C4B5FD)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.08,
      );
      canvas.drawCircle(
        const Offset(-br * 0.35, -br * 0.35),
        br * 0.28,
        Paint()..color = const Color(0x99FFFFFF),
      );
    }
  }
}
