import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';

class FailureOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback onLevelMap;
  final VoidCallback onHint;
  final VoidCallback onBooster;

  const FailureOverlay({
    super.key,
    required this.onRetry,
    required this.onHome,
    required this.onLevelMap,
    required this.onHint,
    required this.onBooster,
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
                // 3D Sad Emoji Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFFFFCDD2), offset: Offset(0, 4), blurRadius: 0),
                    ],
                  ),
                  child: const Center(
                    child: Text('😢', style: TextStyle(fontSize: 44)),
                  ),
                ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 700.ms),

                const SizedBox(height: 14),

                Text(
                  'Oh no!',
                  style: AppTheme.headline.copyWith(
                    color: AppTheme.danger,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "The candy didn't make it to Nomi!",
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 22),

                // Primary 3D Hero Action: Try Again
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: AppTheme.primaryButton3D(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.replay_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: AppTheme.title.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3D Helpers Row: Hint and Boosters
                Row(
                  children: [
                    Expanded(
                      child: _3DChipButton(
                        label: 'Hint',
                        icon: Icons.lightbulb_rounded,
                        bgColor: AppTheme.goldYellow,
                        lipColor: AppTheme.goldLip,
                        textColor: AppTheme.textDark,
                        onTap: onHint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _3DChipButton(
                        label: 'Boosters',
                        icon: Icons.bolt_rounded,
                        bgColor: AppTheme.secondary,
                        lipColor: const Color(0xFF6D52E6),
                        textColor: Colors.white,
                        onTap: onBooster,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3D Navigation Footer Row: Level Map and Home
                Row(
                  children: [
                    Expanded(
                      child: _3DChipButton(
                        label: 'Levels',
                        icon: Icons.grid_view_rounded,
                        bgColor: const Color(0xFFF1F5F9),
                        lipColor: const Color(0xFFCBD5E1),
                        textColor: AppTheme.textDark,
                        onTap: onLevelMap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _3DChipButton(
                        label: 'Home',
                        icon: Icons.home_rounded,
                        bgColor: const Color(0xFFF1F5F9),
                        lipColor: const Color(0xFFCBD5E1),
                        textColor: AppTheme.textDark,
                        onTap: onHome,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, duration: 400.ms),
        ),
      ),
    );
  }
}

class _3DChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color lipColor;
  final Color textColor;
  final VoidCallback onTap;

  const _3DChipButton({
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
        height: 46,
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
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.label.copyWith(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
