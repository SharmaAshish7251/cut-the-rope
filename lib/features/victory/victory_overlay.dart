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
            decoration: AppTheme.card3D(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D Celebration Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFFC8E6C9), offset: Offset(0, 4), blurRadius: 0),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎉', style: TextStyle(fontSize: 44)),
                  ),
                ).animate().scale(begin: const Offset(0, 0), curve: Curves.elasticOut, duration: 800.ms),

                const SizedBox(height: 10),

                Text(
                  levelId == 100 ? '🏆 Game Complete!' : 'Level Complete!',
                  style: AppTheme.headline.copyWith(
                    color: AppTheme.successGreen,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // Crisp 3D Star Podium (Center star elevated, crisp 3D styling)
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
                      child: Icon(
                        Icons.star_rounded,
                        size: size,
                        color: isEarned
                            ? AppTheme.goldYellow
                            : const Color(0xFFE2E8F0),
                        shadows: isEarned
                            ? const [
                                Shadow(
                                  color: AppTheme.goldLip,
                                  offset: Offset(0, 3),
                                  blurRadius: 0,
                                ),
                              ]
                            : const [
                                Shadow(
                                  color: Color(0xFFCBD5E1),
                                  offset: Offset(0, 2),
                                  blurRadius: 0,
                                ),
                              ],
                      ).animate(delay: (i * 180).ms)
                        .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
                    );
                  }),
                ),

                const SizedBox(height: 14),

                // 3D Score & Coins Capsule Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: AppTheme.cardLip, offset: Offset(0, 3), blurRadius: 0),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'SCORE',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textDark.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$score',
                            style: AppTheme.title.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1.5, height: 32, color: AppTheme.cardBorder),
                      Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 6),
                          Text(
                            '+$currencyEarned',
                            style: AppTheme.title.copyWith(
                              color: AppTheme.goldLip,
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
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
                      color: AppTheme.goldYellow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: AppTheme.goldLip, offset: Offset(0, 3), blurRadius: 0),
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
                              color: AppTheme.textDark,
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

                const SizedBox(height: 20),

                // 3D Primary Hero Action: Next Level
                if (onNext != null)
                  GestureDetector(
                    onTap: onNext!,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: AppTheme.successButton3D(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next Level',
                            style: AppTheme.title.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // 3D Navigation Row: Replay and Level Map
                Row(
                  children: [
                    Expanded(
                      child: _3DVictoryNavButton(
                        label: 'Replay',
                        icon: Icons.replay_rounded,
                        bgColor: AppTheme.secondary,
                        lipColor: const Color(0xFF6D52E6),
                        textColor: Colors.white,
                        onTap: onReplay,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _3DVictoryNavButton(
                        label: 'Levels',
                        icon: Icons.grid_view_rounded,
                        bgColor: const Color(0xFFF1F5F9),
                        lipColor: const Color(0xFFCBD5E1),
                        textColor: AppTheme.textDark,
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

class _3DVictoryNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color lipColor;
  final Color textColor;
  final VoidCallback onTap;

  const _3DVictoryNavButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.lipColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: lipColor, offset: const Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.label.copyWith(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
