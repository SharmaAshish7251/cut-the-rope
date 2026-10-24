import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';

/// 3D Claymorphism dialog shown when the player taps the Hint button.
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
            decoration: AppTheme.card3D(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D Lightbulb Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.goldLip, offset: Offset(0, 4), blurRadius: 0),
                    ],
                  ),
                  child: const Center(
                    child: Text('💡', style: TextStyle(fontSize: 42)),
                  ),
                ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut, duration: 700.ms),

                const SizedBox(height: 14),

                Text(
                  'Need a Hint?',
                  style: AppTheme.headline.copyWith(
                    color: AppTheme.primaryOrange,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (hasCredits) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.goldYellow, width: 1.5),
                    ),
                    child: Text(
                      hintText,
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _3DDialogButton(
                    label: 'Reveal Hint',
                    bgColor: AppTheme.primaryOrange,
                    lipColor: AppTheme.orangeLip,
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
                  _3DDialogButton(
                    label: '🎬 Watch Ad for Hint',
                    bgColor: AppTheme.goldYellow,
                    lipColor: AppTheme.goldLip,
                    textColor: AppTheme.textDark,
                    onTap: onEarnHint,
                  ),
                ],

                const SizedBox(height: 10),

                _3DDialogButton(
                  label: 'Dismiss',
                  bgColor: const Color(0xFFF1F5F9),
                  lipColor: const Color(0xFFCBD5E1),
                  textColor: AppTheme.textDark,
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
            decoration: AppTheme.card3D(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📡', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'No Connection',
                  style: AppTheme.title.copyWith(color: AppTheme.danger, fontWeight: FontWeight.bold),
                ),
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
                _3DDialogButton(
                  label: 'OK',
                  bgColor: AppTheme.primaryOrange,
                  lipColor: AppTheme.orangeLip,
                  onTap: onDismiss,
                ),
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
          decoration: BoxDecoration(
            color: AppTheme.goldYellow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(color: AppTheme.goldLip, offset: Offset(0, 4), blurRadius: 0),
            ],
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hintText,
                  style: AppTheme.label.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.close_rounded, color: AppTheme.textDark, size: 20),
            ],
          ),
        ).animate().slideY(begin: 1.0, curve: Curves.easeOutBack, duration: 500.ms),
      ),
    );
  }
}

class _3DDialogButton extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color lipColor;
  final Color textColor;
  final VoidCallback onTap;

  const _3DDialogButton({
    required this.label,
    required this.bgColor,
    required this.lipColor,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: lipColor, offset: const Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.label.copyWith(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
