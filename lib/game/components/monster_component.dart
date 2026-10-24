import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart' show RadialGradient, Alignment;
import '../candy_game.dart';
import 'candy_component.dart';

class MonsterComponent extends BodyComponent<CandyGame> with ContactCallbacks {
  final Vector2 _pos;
  final void Function() onCandyDelivered;
  bool _delivered = false;
  static const double radius = 1.3;
  Sprite? _monsterSprite;

  double _animTime = 0;

  MonsterComponent({required Vector2 position, required this.onCandyDelivered})
      : _pos = position.clone(),
        super(renderBody: false);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _monsterSprite = await Sprite.load('characters/nomi.png');
    } catch (_) {}
  }

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

    // 1. Wooden/Cardboard Platform under monster
    const platformRect = Rect.fromLTWH(-r * 1.3, r * 0.65, r * 2.6, r * 0.45);
    final platformRRect = RRect.fromRectAndRadius(platformRect, const Radius.circular(0.18));
    // Platform shadow
    canvas.drawRRect(
      platformRRect.shift(const Offset(0, 0.08)),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15),
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
      const Offset(0, 0.45),
      r * 0.95,
      Paint()
        ..color = const Color(0x443A186E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.25),
    );

    // Render High-Res Nomi Sprite
    if (_monsterSprite != null) {
      _monsterSprite!.renderRect(
        canvas,
        Rect.fromCenter(center: const Offset(0, -0.15), width: r * 2.8, height: r * 2.8),
      );
    } else {
      // Fallback 3D Body
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFAA90FF), Color(0xFF6B50D6)],
            center: Alignment(-0.25, -0.35),
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
      );
    }
  }
}
