import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startInit();
  }

  Future<void> _startInit() async {
    // Load config
    await ref.read(gameConfigProvider.future);
    if (!mounted) return;

    // Configure audio with loaded settings
    final settings = ref.read(settingsProvider);
    ref.read(audioServiceProvider).configure(
          music: settings.musicEnabled,
          sound: settings.soundEnabled,
        );

    // Minimum splash time
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _navigated) return;

    _navigated = true;
    // Route to onboarding if tutorial not completed, otherwise home
    final progress = ref.read(progressProvider).valueOrNull;
    if (progress != null && !progress.tutorialCompleted) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SizedBox.expand(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text(
                '\u{1F36C}', // 🍬
                style: TextStyle(fontSize: 80),
              )
                  .animate(controller: _bounce)
                  .moveY(begin: 0, end: -16, curve: Curves.easeInOut),
              const SizedBox(height: 24),
              Text(
                'Cut the Cable',
                style: AppTheme.display.copyWith(
                  color: AppTheme.primary,
                  shadows: [
                    Shadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
              const SizedBox(height: 8),
              Text(
                'A sweet puzzle adventure',
                style: AppTheme.body
                    .copyWith(color: AppTheme.textDark.withValues(alpha: 0.6)),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              const Spacer(flex: 2),
              Container(
                width: 160,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
