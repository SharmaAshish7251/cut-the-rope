import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/inventory_item.dart';
import '../shop/daily_rewards.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(audioServiceProvider).startBgm();
    // Check and show daily reward after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDailyReward());
  }

  Future<void> _checkDailyReward() async {
    final invAsync = ref.read(inventoryProvider);
    final inv = invAsync.valueOrNull ?? const Inventory();
    final today = DateTime.now();
    final claimKey = 'daily_${today.year}-${today.month}-${today.day}';

    if (!inv.hasClaimed(claimKey) && mounted) {
      _showDailyRewardSheet(inv, claimKey);
    }
  }

  void _showDailyRewardSheet(Inventory inv, String claimKey) {
    // Calculate current streak day (1-7 cycling)
    int streakDay = 1;
    for (int d = 1; d <= 7; d++) {
      final key = 'daily_streak_$d';
      if (inv.hasClaimed(key)) streakDay = d + 1;
    }
    if (streakDay > 7) streakDay = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DailyRewardSheet(
        currentDay: streakDay,
        alreadyClaimed: false,
        onClaim: () async {
          Navigator.pop(context);
          await _claimDailyReward(streakDay, claimKey);
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _claimDailyReward(int day, String claimKey) async {
    final reward = dailyRewards[day - 1];
    final invRepo = ref.read(inventoryRepositoryProvider);

    // Grant rewards
    if (reward.currency != null && reward.currency! > 0) {
      await ref.read(progressProvider.notifier).addCurrency(reward.currency!);
    }
    if (reward.hints != null && reward.hints! > 0) {
      await invRepo.grantHints(reward.hints!);
    }
    if (reward.booster != null) {
      await invRepo.grantBooster(reward.booster!);
    }

    // Record claim
    await invRepo.recordClaim(claimKey);
    await invRepo.recordClaim('daily_streak_$day');

    // When the full 7-day cycle completes, clear all streak markers so the
    // next login starts a fresh Day-1 cycle instead of looping on Day 1 forever.
    if (day == 7) {
      for (int d = 1; d <= 7; d++) {
        await invRepo.removeClaim('daily_streak_$d');
      }
    }

    // Play celebration chime
    ref.read(audioServiceProvider).playLevelComplete();

    // Refresh providers
    ref.read(inventoryProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎁 Day $day reward claimed: ${reward.label}'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF4E8), Color(0xFFFFE0CC)],
              ),
            ),
          ),
          // Decorative clouds
          Positioned(top: 60, left: -20,
            child: _CloudShape(size: 120, color: Colors.white.withValues(alpha: 0.7))),
          Positioned(top: 100, right: -30,
            child: _CloudShape(size: 90, color: Colors.white.withValues(alpha: 0.5))),
          Positioned(top: 200, left: 40,
            child: _CloudShape(size: 70, color: Colors.white.withValues(alpha: 0.4))),

          Positioned.fill(
            child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Title
                Text(
                  'Cut the Cable',
                  style: AppTheme.display.copyWith(color: AppTheme.primary),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),

                const SizedBox(height: 8),
                progressAsync.when(
                  data: (p) => Text(
                    '${p.levels.values.where((l) => l.completed).length} / 100 levels completed',
                    style: AppTheme.body.copyWith(color: AppTheme.textDark.withValues(alpha: 0.65)),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ).animate().fadeIn(delay: 200.ms),

                const Spacer(),

                // Monster character
                _MonsterWidget()
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -12, duration: 1200.ms, curve: Curves.easeInOut),

                const Spacer(),

                // Stars + Currency display
                progressAsync.when(
                  data: (p) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stars
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: AppTheme.clayBox(
                          color: AppTheme.accent.withValues(alpha: 0.12),
                          radius: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppTheme.accent, size: 22),
                            const SizedBox(width: 4),
                            Text('${p.totalStars}',
                                style: AppTheme.label.copyWith(color: AppTheme.accent)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Currency
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: AppTheme.clayBox(
                          color: AppTheme.success.withValues(alpha: 0.12),
                          radius: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💰', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text('${p.currency}',
                                style: AppTheme.label.copyWith(color: AppTheme.success)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),

                // Play / Continue button
                _ClayButton(
                  label: 'Play!',
                  color: AppTheme.primary,
                  icon: Icons.play_arrow_rounded,
                  onTap: () {
                    ref.read(audioServiceProvider).playUiClick();
                    context.push(AppRoutes.levelSelection);
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),

                const SizedBox(height: 16),

                // Secondary actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SmallClayButton(
                      icon: Icons.storefront_rounded,
                      label: 'Shop',
                      color: AppTheme.secondary,
                      onTap: () {
                        ref.read(audioServiceProvider).playUiClick();
                        context.push(AppRoutes.shop);
                      },
                    ),
                    const SizedBox(width: 12),
                    _SmallClayButton(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Daily',
                      color: AppTheme.success,
                      onTap: () {
                        ref.read(audioServiceProvider).playUiClick();
                        final inv = ref.read(inventoryProvider).valueOrNull ?? const Inventory();
                        final today = DateTime.now();
                        final claimKey = 'daily_${today.year}-${today.month}-${today.day}';
                        _showDailyRewardSheet(inv, claimKey);
                      },
                    ),
                    const SizedBox(width: 12),
                    _SmallClayButton(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      color: AppTheme.accent,
                      onTap: () {
                        ref.read(audioServiceProvider).playUiClick();
                        context.push(AppRoutes.settings);
                      },
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 48),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _MonsterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('👾', style: TextStyle(fontSize: 96)),
      ),
    );
  }
}

class _ClayButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ClayButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 60,
        decoration: AppTheme.clayBox(color: color, radius: AppTheme.buttonCorner),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.title.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _SmallClayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallClayButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 50,
        decoration: AppTheme.clayBox(color: color.withValues(alpha: 0.15), radius: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            Text(label, style: AppTheme.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _CloudShape extends StatelessWidget {
  final double size;
  final Color color;

  const _CloudShape({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
