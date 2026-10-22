import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/achievement.dart';
import '../../data/repositories/achievement_repository.dart';

/// Provider for achievement progress.
final achievementRepoProvider = Provider<AchievementRepository>(
  (_) => AchievementRepository(),
);

final achievementProgressProvider = FutureProvider<AchievementProgress>(
  (ref) => ref.watch(achievementRepoProvider).load(),
);

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementAsync = ref.watch(achievementProgressProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Achievements',
            style: AppTheme.headline.copyWith(color: AppTheme.primary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: achievementAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ap) {
          final unlockedCount = ap.unlocked.length;
          final totalCount = allAchievements.length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Progress summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.clayBox(color: AppTheme.primary.withValues(alpha: 0.08)),
                child: Column(
                  children: [
                    Text(
                      '$unlockedCount / $totalCount',
                      style: AppTheme.display.copyWith(color: AppTheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text('Achievements Unlocked',
                        style: AppTheme.label.copyWith(
                          color: AppTheme.textDark.withValues(alpha: 0.5),
                        )),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: unlockedCount / totalCount,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 24),

              // Achievement cards
              ...allAchievements.asMap().entries.map((entry) {
                final i = entry.key;
                final achievement = entry.value;
                final unlocked = ap.unlocked.contains(achievement.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AchievementCard(
                    achievement: achievement,
                    unlocked: unlocked,
                  ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _AchievementCard({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.clayBox(
        color: unlocked ? AppTheme.surface : Colors.grey.shade100,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppTheme.accent.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                unlocked ? achievement.emoji : '🔒',
                style: TextStyle(
                  fontSize: 28,
                  color: unlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: AppTheme.label.copyWith(
                    color: unlocked ? AppTheme.textDark : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: AppTheme.caption.copyWith(
                    color: unlocked
                        ? AppTheme.textDark.withValues(alpha: 0.5)
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Reward
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✓', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('+${achievement.rewardCurrency}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            )
          else
            Text(
              '💰${achievement.rewardCurrency}',
              style: AppTheme.caption.copyWith(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

/// Toast notification shown when an achievement is unlocked.
class AchievementToast extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const AchievementToast({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: AppTheme.clayBox(color: AppTheme.accent, radius: 16),
          child: Row(
            children: [
              Text(achievement.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Achievement Unlocked!',
                        style: AppTheme.caption.copyWith(
                          color: Colors.white70,
                        )),
                    Text(achievement.title,
                        style: AppTheme.label.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Text('+${achievement.rewardCurrency} 💰',
                  style: AppTheme.label.copyWith(color: Colors.white)),
            ],
          ),
        )
            .animate()
            .slideY(begin: -1.5, curve: Curves.easeOutBack, duration: 600.ms)
            .then(delay: 3000.ms)
            .slideY(end: -1.5, duration: 400.ms),
      ),
    );
  }
}
