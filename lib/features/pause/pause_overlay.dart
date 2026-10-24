import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback onLevelMap;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
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
                // 3D Pause Icon Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE7F6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFFD1C4E9), offset: Offset(0, 4), blurRadius: 0),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.pause_rounded, size: 42, color: AppTheme.secondary),
                  ),
                ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 700.ms),

                const SizedBox(height: 14),

                Text(
                  'Game Paused',
                  style: AppTheme.headline.copyWith(
                    color: AppTheme.primaryOrange,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Take a breath, Nomi is waiting!',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 22),

                // 3D Hero Primary Action: Resume Game
                GestureDetector(
                  onTap: onResume,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: AppTheme.successButton3D(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          'Resume Game',
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

                // 3D Action: Restart Level
                _3DPauseChipButton(
                  label: 'Restart Level',
                  icon: Icons.replay_rounded,
                  bgColor: AppTheme.primaryOrange,
                  lipColor: AppTheme.orangeLip,
                  textColor: Colors.white,
                  onTap: onRestart,
                ),

                const SizedBox(height: 12),

                // 3D Navigation Row: Levels and Home
                Row(
                  children: [
                    Expanded(
                      child: _3DPauseChipButton(
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
                      child: _3DPauseChipButton(
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

class _3DPauseChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color lipColor;
  final Color textColor;
  final VoidCallback onTap;

  const _3DPauseChipButton({
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
            Icon(icon, color: textColor, size: 20),
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
