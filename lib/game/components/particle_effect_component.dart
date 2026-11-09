import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';

enum FxParticleType { starDust, candyCrumbs, ropeSparks }

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;
  double life;
  final double maxLife;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.life,
  }) : maxLife = life;
}

/// Dynamic particle burst system for Star Dust, Candy Crumbs, and Rope Cut Sparks.
class ParticleEffectComponent extends Component {
  final Vector2 origin;
  final FxParticleType type;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  ParticleEffectComponent({
    required this.origin,
    required this.type,
  }) {
    _spawnParticles();
  }

  void _spawnParticles() {
    switch (type) {
      case FxParticleType.starDust:
        // 14 glowing golden star particles expanding radially
        const count = 14;
        const colors = [
          Color(0xFFFFD166),
          Color(0xFFFFE29A),
          Color(0xFFFFF4D2),
          Color(0xFFFFAA00),
        ];
        for (var i = 0; i < count; i++) {
          final angle = (i * (2 * math.pi) / count) + (_random.nextDouble() * 0.4 - 0.2);
          final speed = 2.0 + _random.nextDouble() * 3.5;
          _particles.add(
            _Particle(
              x: origin.x,
              y: origin.y,
              vx: math.cos(angle) * speed,
              vy: math.sin(angle) * speed,
              radius: 0.08 + _random.nextDouble() * 0.08,
              color: colors[i % colors.length],
              life: 0.45 + _random.nextDouble() * 0.25,
            ),
          );
        }
        break;

      case FxParticleType.candyCrumbs:
        // Sweet candy crumbs bursting with gravity
        const count = 16;
        const colors = [
          Color(0xFFFF6B6B),
          Color(0xFFFFD166),
          Color(0xFF4ECDC4),
          Color(0xFFFFFFFF),
          Color(0xFFFF8A65),
        ];
        for (var i = 0; i < count; i++) {
          final angle = _random.nextDouble() * 2 * math.pi;
          final speed = 1.5 + _random.nextDouble() * 4.0;
          _particles.add(
            _Particle(
              x: origin.x + (_random.nextDouble() - 0.5) * 0.4,
              y: origin.y + (_random.nextDouble() - 0.5) * 0.4,
              vx: math.cos(angle) * speed,
              vy: math.sin(angle) * speed - 2.0, // slight upward pop
              radius: 0.06 + _random.nextDouble() * 0.08,
              color: colors[i % colors.length],
              life: 0.5 + _random.nextDouble() * 0.35,
            ),
          );
        }
        break;

      case FxParticleType.ropeSparks:
        // Cable snap sparks & frayed fiber flecks
        const count = 10;
        const colors = [
          Color(0xFFFFD166),
          Color(0xFF8B5E3C),
          Color(0xFFC0A080),
          Color(0xFFFFAA66),
        ];
        for (var i = 0; i < count; i++) {
          final angle = _random.nextDouble() * 2 * math.pi;
          final speed = 1.2 + _random.nextDouble() * 2.8;
          _particles.add(
            _Particle(
              x: origin.x,
              y: origin.y,
              vx: math.cos(angle) * speed,
              vy: math.sin(angle) * speed,
              radius: 0.04 + _random.nextDouble() * 0.06,
              color: colors[i % colors.length],
              life: 0.25 + _random.nextDouble() * 0.2,
            ),
          );
        }
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    var hasAlive = false;

    for (final p in _particles) {
      if (p.life > 0) {
        hasAlive = true;
        p.life -= dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;

        // Apply gentle gravity to candy crumbs
        if (type == FxParticleType.candyCrumbs) {
          p.vy += 9.8 * dt;
        } else if (type == FxParticleType.starDust) {
          // Slight air resistance
          p.vx *= 0.94;
          p.vy *= 0.94;
        }
      }
    }

    if (!hasAlive) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      if (p.life <= 0) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final r = p.radius * alpha;

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha);

      canvas.drawCircle(Offset(p.x, p.y), r, paint);

      // Star dust specular glint
      if (type == FxParticleType.starDust && alpha > 0.4) {
        canvas.drawCircle(
          Offset(p.x, p.y),
          r * 1.6,
          Paint()
            ..color = const Color(0x66FFFFFF).withValues(alpha: alpha * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.05),
        );
      }
    }
  }
}
