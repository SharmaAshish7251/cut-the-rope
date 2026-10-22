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
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated sad monster / candy badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.danger.withValues(alpha: 0.18),
                        AppTheme.primary.withValues(alpha: 0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.danger.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('😢', style: TextStyle(fontSize: 44)),
                  ),
                ).animate()
                  .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 700.ms),

                const SizedBox(height: 12),
                Text(
                  'Oh no!',
                  style: AppTheme.headline.copyWith(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "The candy didn't make it to Om Nom!",
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Primary Hero Action: Try Again
                _HeroActionButton(
                  label: 'Try Again',
                  icon: Icons.replay_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A65), Color(0xFFFF6E40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shadowColor: const Color(0xFFFF6E40).withValues(alpha: 0.4),
                  onTap: onRetry,
                ),

                const SizedBox(height: 12),

                // Helpers Row: Hint and Boosters (No text wrap, crisp icons)
                Row(
                  children: [
                    Expanded(
                      child: _ChipButton(
                        label: 'Hint',
                        icon: Icons.lightbulb_rounded,
                        bgColor: const Color(0xFFFFF3D6),
                        iconColor: const Color(0xFFD49100),
                        textColor: const Color(0xFF7A5400),
                        borderColor: const Color(0xFFFFD166).withValues(alpha: 0.6),
                        onTap: onHint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChipButton(
                        label: 'Boosters',
                        icon: Icons.bolt_rounded,
                        bgColor: const Color(0xFFEDE9FE),
                        iconColor: const Color(0xFF7C3AED),
                        textColor: const Color(0xFF5B21B6),
                        borderColor: const Color(0xFF8B7CF6).withValues(alpha: 0.6),
                        onTap: onBooster,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Sleek Navigation Footer Row: Level Map and Home
                Row(
                  children: [
                    Expanded(
                      child: _NavButton(
                        label: 'Levels',
                        icon: Icons.grid_view_rounded,
                        onTap: onLevelMap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _NavButton(
                        label: 'Home',
                        icon: Icons.home_rounded,
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

class _HeroActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _HeroActionButton({
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
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.label.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
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
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: AppTheme.label.copyWith(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
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
                Icon(icon, color: const Color(0xFF6B7280), size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTheme.label.copyWith(
                    color: const Color(0xFF4B5563),
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
