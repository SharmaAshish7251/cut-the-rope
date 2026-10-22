import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/inventory_item.dart';
import '../../services/reward_service.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final progressAsync = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Shop', style: AppTheme.headline.copyWith(color: AppTheme.primary)),
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
        actions: [
          // Currency display
          progressAsync.when(
            data: (p) => Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: AppTheme.clayBox(
                color: AppTheme.accent.withValues(alpha: 0.15),
                radius: 16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('${p.currency}',
                      style: AppTheme.label.copyWith(color: AppTheme.accent)),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (inventory) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Hint credits section
            const _SectionHeader(title: 'Hints', emoji: '💡'),
            const SizedBox(height: 12),
            _HintCard(
              credits: inventory.hintCredits,
              onEarn: () => _earnHint(context, ref),
            ).animate().fadeIn(delay: 80.ms).slideX(begin: 0.2),

            const SizedBox(height: 28),

            // Boosters section
            const _SectionHeader(title: 'Boosters', emoji: '⚡'),
            const SizedBox(height: 12),
            ...BoosterType.values.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShopBoosterCard(
                type: e.value,
                count: inventory.boosterCount(e.value),
                onEarn: () => _earnBooster(context, ref, e.value),
              ).animate().fadeIn(delay: ((e.key + 1) * 80).ms).slideX(begin: 0.2),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _earnHint(BuildContext context, WidgetRef ref) async {
    final rewardService = ref.read(rewardServiceProvider);
    final (outcome, inv) = await rewardService.earnHint();

    if (inv != null) ref.read(inventoryProvider.notifier).updateInventory(inv);

    if (context.mounted) {
      switch (outcome) {
        case RewardOutcome.granted:
          ref.read(audioServiceProvider).playBooster();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💡 Hint earned!'),
              backgroundColor: AppTheme.success,
            ),
          );
          break;
        case RewardOutcome.offline:
          _showOfflineDialog(context);
          break;
        case RewardOutcome.adCancelled:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad was cancelled'),
              backgroundColor: AppTheme.danger,
            ),
          );
          break;
        case RewardOutcome.adFailed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad failed to load. Try again later.'),
              backgroundColor: AppTheme.danger,
            ),
          );
          break;
        case RewardOutcome.noInventory:
          break;
      }
    }
  }

  Future<void> _earnBooster(BuildContext context, WidgetRef ref, BoosterType type) async {
    final rewardService = ref.read(rewardServiceProvider);
    final (outcome, inv) = await rewardService.earnBooster(type);

    if (inv != null) ref.read(inventoryProvider.notifier).updateInventory(inv);

    if (context.mounted) {
      switch (outcome) {
        case RewardOutcome.granted:
          ref.read(audioServiceProvider).playBooster();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${type.emoji} ${type.displayName} earned!'),
              backgroundColor: AppTheme.success,
            ),
          );
          break;
        case RewardOutcome.offline:
          _showOfflineDialog(context);
          break;
        case RewardOutcome.adCancelled:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad was cancelled'),
              backgroundColor: AppTheme.danger,
            ),
          );
          break;
        case RewardOutcome.adFailed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad failed to load. Try again later.'),
              backgroundColor: AppTheme.danger,
            ),
          );
          break;
        case RewardOutcome.noInventory:
          break;
      }
    }
  }

  void _showOfflineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('📡 No Connection'),
        content: const Text('An internet connection is needed to watch an ad and earn rewards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;
  const _SectionHeader({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.title.copyWith(color: AppTheme.secondary)),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  final int credits;
  final VoidCallback onEarn;
  const _HintCard({required this.credits, required this.onEarn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.clayBox(color: AppTheme.surface),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: AppTheme.clayBox(
              color: AppTheme.accent.withValues(alpha: 0.15),
              radius: 16,
            ),
            child: const Center(
              child: Text('💡', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Hints', style: AppTheme.label),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: credits > 0
                            ? AppTheme.success.withValues(alpha: 0.15)
                            : AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '×$credits',
                        style: AppTheme.caption.copyWith(
                          color: credits > 0 ? AppTheme.success : AppTheme.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Shows you which rope to cut next',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textDark.withValues(alpha: 0.6),
                    )),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onEarn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('🎬 Earn',
                style: AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ShopBoosterCard extends StatelessWidget {
  final BoosterType type;
  final int count;
  final VoidCallback onEarn;
  const _ShopBoosterCard({
    required this.type,
    required this.count,
    required this.onEarn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.clayBox(color: AppTheme.surface),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: AppTheme.clayBox(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              radius: 16,
            ),
            child: Center(
              child: Text(type.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(type.displayName, style: AppTheme.label),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? AppTheme.success.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '×$count',
                        style: AppTheme.caption.copyWith(
                          color: count > 0 ? AppTheme.success : Colors.grey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(type.description,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textDark.withValues(alpha: 0.6),
                    )),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onEarn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('🎬 Earn',
                style: AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
