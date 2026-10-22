import 'dart:ui';
import 'package:flutter/painting.dart' show RadialGradient, Alignment;
import 'package:flame_forge2d/flame_forge2d.dart';

class CandyComponent extends BodyComponent {
  final Vector2 _initPos;
  static const double radius = 0.7;

  CandyComponent({required Vector2 position})
      : _initPos = position.clone(),
        super(renderBody: false);

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
    canvas.drawCircle(const Offset(0, 0.08), r,
        Paint()..color = const Color(0x40FF6B3D)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3));

    // Body gradient
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFAA80), Color(0xFFFF6B3D)],
        center: Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, bodyPaint);

    // Highlight
    canvas.drawCircle(const Offset(-r * 0.3, -r * 0.3), r * 0.3,
        Paint()..color = const Color(0x80FFFFFF));

    // Swirl
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.6),
      -1.2, 2.0, false,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = r * 0.15
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
}
