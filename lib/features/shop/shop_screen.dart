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
        backgroundColor: Colors.transparent,
        title: Text(
          'Shop',
          style: AppTheme.headline.copyWith(color: AppTheme.primaryOrange, fontSize: 26),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          // Currency 3D Chip
          progressAsync.when(
            data: (p) => Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: AppTheme.cardLip, offset: Offset(0, 3), blurRadius: 0),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '${p.currency}',
                    style: AppTheme.label.copyWith(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            // 3D Featured Purple Starter Pack Banner
            _StarterPackBanner().animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 24),

            // Hints section
            const _SectionHeader(title: 'Hints', emoji: '💡'),
            const SizedBox(height: 12),
            _HintCard(
              credits: inventory.hintCredits,
              onEarn: () => _earnHint(context, ref),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),

            const SizedBox(height: 24),

            // Boosters section
            const _SectionHeader(title: 'Boosters', emoji: '⚡'),
            const SizedBox(height: 12),
            ...BoosterType.values.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ShopBoosterCard(
                    type: e.value,
                    count: inventory.boosterCount(e.value),
                    onEarn: () => _earnBooster(context, ref, e.value),
                  ).animate().fadeIn(delay: ((e.key + 1) * 80).ms).slideX(begin: 0.1),
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
              backgroundColor: AppTheme.successGreen,
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
              backgroundColor: AppTheme.successGreen,
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

class _StarterPackBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B7CF6), Color(0xFF6D52E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4C38B2), offset: Offset(0, 6), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Starter Pack',
                  style: AppTheme.title.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldYellow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: AppTheme.goldLip, offset: Offset(0, 3), blurRadius: 0),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '3 / 500',
                        style: AppTheme.label.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Text('🎁', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;
  const _SectionHeader({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.title.copyWith(
            color: AppTheme.primaryOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      decoration: AppTheme.card3D(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldYellow, width: 1.5),
            ),
            child: const Center(
              child: Text('💡', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Hints', style: AppTheme.label.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.goldYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '×$credits',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.goldLip,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Shows the best rope to cut next',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _3DEarnButton(onTap: onEarn),
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
      decoration: AppTheme.card3D(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.secondary, width: 1.5),
            ),
            child: Center(
              child: Text(type.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type.displayName,
                      style: AppTheme.label.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '×$count',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  type.description,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _3DEarnButton(onTap: onEarn),
        ],
      ),
    );
  }
}

class _3DEarnButton extends StatelessWidget {
  final VoidCallback onTap;
  const _3DEarnButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.goldYellow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(color: AppTheme.goldLip, offset: Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎬', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              'Earn',
              style: AppTheme.caption.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
