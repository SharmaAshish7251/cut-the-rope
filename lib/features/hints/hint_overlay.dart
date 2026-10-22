import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';

/// Claymorphism dialog shown when the player taps the Hint button.
/// Handles three flows:
///   1. Player has hint credits → use one and reveal hint
///   2. Player has no credits → offer to earn via rewarded ad
///   3. Offline → show offline message
class HintDialog extends StatelessWidget {
  final bool hasCredits;
  final int creditCount;
  final String hintText;
  final VoidCallback onUseHint;
  final VoidCallback onEarnHint;
  final VoidCallback onCancel;

  const HintDialog({
    super.key,
    required this.hasCredits,
    required this.creditCount,
    required this.hintText,
    required this.onUseHint,
    required this.onEarnHint,
    required this.onCancel,
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
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.25),
                        AppTheme.primary.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('💡', style: TextStyle(fontSize: 40)),
                  ),
                ).animate()
                  .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 700.ms),

                const SizedBox(height: 14),

                Text('Need a Hint?',
                    style: AppTheme.headline.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),

                if (hasCredits) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Text(
                      hintText,
                      style: AppTheme.body.copyWith(
                        color: const Color(0xFF6B4700),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$creditCount hint credit${creditCount == 1 ? '' : 's'} available',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DialogButton(
                    label: 'Reveal Hint',
                    color: AppTheme.primary,
                    onTap: onUseHint,
                  ),
                ] else ...[
                  Text(
                    'Watch a quick ad to unlock the hint for this level!',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.textDark.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  _DialogButton(
                    label: '🎬 Watch Ad for Hint',
                    color: AppTheme.accent,
                    onTap: onEarnHint,
                  ),
                ],

                const SizedBox(height: 10),
                _DialogButton(
                  label: 'Dismiss',
                  color: Colors.grey.shade400,
                  onTap: onCancel,
                ),
              ],
            ),
          ).animate().scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, duration: 400.ms),
        ),
      ),
    );
  }
}

/// Shown when the user is offline and tries to earn a hint.
class HintOfflineDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  const HintOfflineDialog({super.key, required this.onDismiss});

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
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📡', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('No Connection',
                    style: AppTheme.title.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'An internet connection is needed to watch an ad and earn a hint.',
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _DialogButton(label: 'OK', color: AppTheme.primary, onTap: onDismiss),
              ],
            ),
          ).animate().scale(begin: const Offset(0.85, 0.85)),
        ),
      ),
    );
  }
}

/// Compact visual hint banner shown over the gameplay area after using a hint credit.
class HintBanner extends StatelessWidget {
  final String hintText;
  final VoidCallback onDismiss;

  const HintBanner({super.key, required this.hintText, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: AppTheme.clayBox(color: AppTheme.accent, radius: 16),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hintText,
                  style: AppTheme.label.copyWith(color: Colors.white),
                ),
              ),
              const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            ],
          ),
        ).animate().slideY(begin: 1.0, curve: Curves.easeOutBack, duration: 500.ms),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DialogButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(label, style: AppTheme.label.copyWith(color: Colors.white)),
      ),
    );
  }
}
