import 'dart:math' as math;
import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'candy_component.dart';
import 'particle_effect_component.dart';

class StarComponent extends BodyComponent with ContactCallbacks {
  final String id;
  final Vector2 _pos;
  final void Function(String id) onCollected;
  bool _collected = false;
  static const double radius = 0.55;

  StarComponent({
    required this.id,
    required Vector2 position,
    required this.onCollected,
  })  : _pos = position.clone(),
        super(renderBody: false);

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final fixDef = FixtureDef(shape)..isSensor = true;
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = _pos;
    return world.createBody(bodyDef)..createFixture(fixDef);
  }

  double _animTime = 0;

  bool get isCollected => _collected;

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    world.add(ParticleEffectComponent(origin: body.position, type: FxParticleType.starDust));
    onCollected(id);
    removeFromParent();
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (_collected) return;
    if (other is CandyComponent ||
        (other is Fixture && other.body.userData is CandyComponent) ||
        (other is Body && other.userData is CandyComponent)) {
      collect();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_collected) return;
    final pulse = 1.0 + 0.08 * math.sin(_animTime * 4);
    final size = radius * pulse;

    _drawStar(
      canvas,
      Offset.zero,
      size * 1.35,
      Paint()
        ..color = const Color(0x66FFD166)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.2),
    );
    _drawStar(canvas, Offset.zero, size, Paint()..color = const Color(0xFFFFD166));
    _drawStar(
      canvas,
      const Offset(-0.05, -0.05),
      size * 0.5,
      Paint()..color = const Color(0x80FFFFFF),
    );
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? size : size * 0.4;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
