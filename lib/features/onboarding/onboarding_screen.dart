import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';

/// Interactive onboarding tutorial.
/// Walks the player through core mechanics with animated guidance panels.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentStep = 0;

  static const _steps = [
    _TutorialStep(
      emoji: '🍬',
      title: 'Welcome to Cut the Cable!',
      body:
          'Help the candy reach the hungry monster by cutting ropes with your finger.',
      gesture: _GestureType.none,
    ),
    _TutorialStep(
      emoji: '✂️',
      title: 'Swipe to Cut',
      body:
          'Swipe across a rope to cut it. The candy will swing or fall based on physics!',
      gesture: _GestureType.swipe,
    ),
    _TutorialStep(
      emoji: '⭐',
      title: 'Collect Stars',
      body:
          'Guide the candy through stars before it reaches the monster. Collect all 3 for a perfect score!',
      gesture: _GestureType.none,
    ),
    _TutorialStep(
      emoji: '👾',
      title: 'Feed the Monster',
      body:
          'The monster is waiting at the bottom! Deliver the candy to its mouth to complete the level.',
      gesture: _GestureType.none,
    ),
    _TutorialStep(
      emoji: '💡',
      title: 'Use Hints & Boosters',
      body:
          'Stuck? Tap the hint button 💡 or booster button ⚡ during gameplay. Watch a short ad to earn them!',
      gesture: _GestureType.none,
    ),
    _TutorialStep(
      emoji: '🎮',
      title: "You're Ready!",
      body: "Let's start your sweet puzzle adventure. Good luck!",
      gesture: _GestureType.none,
    ),
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _skip() => _complete();

  Future<void> _complete() async {
    await ref.read(progressProvider.notifier).markTutorialDone();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentStep == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text('Skip',
                      style: AppTheme.label.copyWith(
                        color: AppTheme.textDark.withValues(alpha: 0.5),
                      )),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentStep = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _TutorialPage(step: _steps[i]),
              ),
            ),

            // Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  final active = i == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Next / Start button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? AppTheme.success : AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.buttonCorner),
                    ),
                  ),
                  child: Text(
                    isLast ? "Let's Go! 🎮" : 'Next',
                    style: AppTheme.title.copyWith(color: Colors.white),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

enum _GestureType { none, swipe }

class _TutorialStep {
  final String emoji;
  final String title;
  final String body;
  final _GestureType gesture;

  const _TutorialStep({
    required this.emoji,
    required this.title,
    required this.body,
    required this.gesture,
  });
}

// ── Page widget ─────────────────────────────────────────────────────────────

class _TutorialPage extends StatelessWidget {
  final _TutorialStep step;
  const _TutorialPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big emoji
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(step.emoji, style: const TextStyle(fontSize: 72)),
            ),
          )
              .animate()
              .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 600.ms),

          const SizedBox(height: 32),

          // Title
          Text(
            step.title,
            style: AppTheme.headline.copyWith(color: AppTheme.primary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Body
          Text(
            step.body,
            style: AppTheme.body.copyWith(
              color: AppTheme.textDark.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 250.ms),

          // Animated gesture hint
          if (step.gesture == _GestureType.swipe) ...[
            const SizedBox(height: 32),
            _SwipeGestureHint(),
          ],
        ],
      ),
    );
  }
}

class _SwipeGestureHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rope line
          Container(
            width: 160,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4935A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Animated finger icon
          const Icon(Icons.touch_app_rounded, size: 36, color: AppTheme.primary)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveX(begin: -40, end: 40, duration: 1200.ms, curve: Curves.easeInOut),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
