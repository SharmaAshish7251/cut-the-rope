import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';

/// Full-screen Grand Finale celebration when completing Level 100.
class GrandFinaleScreen extends ConsumerStatefulWidget {
  final int totalStars;
  final int finalScore;
  final VoidCallback onReplay;

  const GrandFinaleScreen({
    super.key,
    required this.totalStars,
    required this.finalScore,
    required this.onReplay,
  });

  @override
  ConsumerState<GrandFinaleScreen> createState() => _GrandFinaleScreenState();
}

class _GrandFinaleScreenState extends ConsumerState<GrandFinaleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    ref.read(audioServiceProvider).playLevelComplete();
    _confettiController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();

    for (int i = 0; i < 45; i++) {
      _particles.add(_ConfettiParticle(
        x: _rnd.nextDouble(),
        y: _rnd.nextDouble() * -0.5,
        speed: 0.15 + _rnd.nextDouble() * 0.35,
        size: 6 + _rnd.nextDouble() * 10,
        color: [
          AppTheme.primary,
          AppTheme.secondary,
          AppTheme.accent,
          AppTheme.success,
          Colors.pinkAccent,
          Colors.amber,
        ][_rnd.nextInt(6)],
        rotation: _rnd.nextDouble() * 2 * pi,
        rotationSpeed: (_rnd.nextDouble() - 0.5) * 6,
      ));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Animated confetti particles
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                ),
              );
            },
          ),

          // Central Trophy Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E1A47), Color(0xFF1B162B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shimmering Golden Trophy
                    const Text('🏆', style: TextStyle(fontSize: 84))
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.08, 1.08),
                          duration: 1200.ms,
                          curve: Curves.easeInOut,
                        ),
                    const SizedBox(height: 12),

                    Text(
                      'CONGRATULATIONS!',
                      style: AppTheme.title.copyWith(
                        color: AppTheme.accent,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                    const SizedBox(height: 6),
                    Text(
                      'Grand Cable Master',
                      style: AppTheme.headline.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 8),
                    Text(
                      'You conquered all 100 levels and fed the monster across every single world!',
                      textAlign: TextAlign.center,
                      style: AppTheme.body.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 24),

                    // Stats row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(
                            icon: '⭐',
                            label: 'Total Stars',
                            value: '${widget.totalStars} / 300',
                          ),
                          Container(width: 1, height: 40, color: Colors.white24),
                          _StatColumn(
                            icon: '🎯',
                            label: 'Lvl 100 Score',
                            value: '${widget.finalScore}',
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms).scale(),

                    const SizedBox(height: 28),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.levelSelection),
                        icon: const Icon(Icons.map_rounded, color: Colors.white),
                        label: Text(
                          'View Level Map',
                          style: AppTheme.label.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onReplay,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Replay Level'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go(AppRoutes.home),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Home'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1100.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTheme.title.copyWith(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.caption.copyWith(color: Colors.white60)),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  final double speed;
  final double size;
  final Color color;
  double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = ((p.y + progress * p.speed * 2) % 1.2) * size.height;
      final currentX = p.x * size.width + sin(progress * 2 * pi + p.x * 10) * 15;
      final currentRot = p.rotation + progress * p.rotationSpeed * 2 * pi;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRot);

      final paint = Paint()..color = p.color;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
