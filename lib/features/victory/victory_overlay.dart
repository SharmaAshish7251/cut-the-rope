import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';

class VictoryOverlay extends StatelessWidget {
  final int score;
  final int stars;
  final int levelId;
  final int currencyEarned;
  final String? unlockedWorldName;
  final VoidCallback onReplay;
  final VoidCallback? onNext;
  final VoidCallback onLevelMap;

  const VictoryOverlay({
    super.key,
    required this.score,
    required this.stars,
    required this.levelId,
    required this.currencyEarned,
    this.unlockedWorldName,
    required this.onReplay,
    required this.onNext,
    required this.onLevelMap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.88).clamp(290.0, 340.0);

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  offset: const Offset(0, 16),
                  blurRadius: 36,
                ),
                BoxShadow(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.success.withValues(alpha: 0.20),
                        AppTheme.accent.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎉', style: TextStyle(fontSize: 44)),
                  ),
                ).animate()
                  .scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 800.ms),

                const SizedBox(height: 10),
                Text(
                  levelId == 100 ? '🏆 Game Complete!' : 'Level Complete!',
                  style: AppTheme.headline.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),

                // Star Podium (Center star elevated)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(3, (i) {
                    final isCenter = i == 1;
                    final size = isCenter ? 54.0 : 42.0;
                    final isEarned = i < stars;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: isCenter ? 0 : 8,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isEarned)
                            Container(
                              width: size * 0.85,
                              height: size * 0.85,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD166).withValues(alpha: 0.6),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          Icon(
                            Icons.star_rounded,
                            size: size,
                            color: isEarned
                                ? const Color(0xFFFFB703)
                                : const Color(0xFFE2E8F0),
                          ),
                        ],
                      ).animate(delay: (i * 180).ms)
                        .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
                    );
                  }),
                ),

                const SizedBox(height: 14),

                // Score & Coins Capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('SCORE',
                              style: AppTheme.caption.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              )),
                          Text(
                            '$score',
                            style: AppTheme.title.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: Colors.grey.shade300),
                      Row(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            '+$currencyEarned',
                            style: AppTheme.title.copyWith(
                              color: const Color(0xFFD49100),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),

                if (unlockedWorldName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD166), Color(0xFFFF8A65)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8A65).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌍', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'New World Unlocked!\n$unlockedWorldName',
                            style: AppTheme.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                ],

                if (levelId == 100) ...[
                  const SizedBox(height: 12),
                  Text('🏆 You completed all 100 levels!',
                      style: AppTheme.label.copyWith(color: AppTheme.success),
                      textAlign: TextAlign.center),
                ],

                const SizedBox(height: 18),

                // Primary Hero Action: Next Level (or Replay on 100)
                if (onNext != null)
                  _HeroVictoryButton(
                    label: 'Next Level',
                    icon: Icons.arrow_forward_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF65C98B), Color(0xFF48B671)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shadowColor: const Color(0xFF65C98B).withValues(alpha: 0.4),
                    onTap: onNext!,
                  ),

                const SizedBox(height: 10),

                // Navigation Row: Replay and Level Map
                Row(
                  children: [
                    Expanded(
                      child: _VictoryNavButton(
                        label: 'Replay',
                        icon: Icons.replay_rounded,
                        color: const Color(0xFFEDE9FE),
                        textColor: const Color(0xFF5B21B6),
                        borderColor: const Color(0xFF8B7CF6).withValues(alpha: 0.5),
                        onTap: onReplay,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VictoryNavButton(
                        label: 'Levels',
                        icon: Icons.grid_view_rounded,
                        color: const Color(0xFFF1F3F5),
                        textColor: const Color(0xFF4B5563),
                        borderColor: Colors.grey.shade300,
                        onTap: onLevelMap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().slideY(begin: 0.35, curve: Curves.easeOutBack, duration: 450.ms),
        ),
      ),
    );
  }
}

class _HeroVictoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _HeroVictoryButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTheme.label.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _VictoryNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _VictoryNavButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTheme.label.copyWith(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
