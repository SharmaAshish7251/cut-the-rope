import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final bool alreadyClaimed = inv.hasClaimed(claimKey);

    // Calculate current streak day (1-7 cycling)
    int streakDay = 1;
    if (alreadyClaimed) {
      for (int d = 1; d <= 7; d++) {
        final key = 'daily_streak_$d';
        if (inv.hasClaimed(key)) streakDay = d;
      }
    } else {
      for (int d = 1; d <= 7; d++) {
        final key = 'daily_streak_$d';
        if (inv.hasClaimed(key)) streakDay = d + 1;
      }
      if (streakDay > 7) streakDay = 1;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DailyRewardSheet(
        currentDay: streakDay,
        alreadyClaimed: alreadyClaimed,
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

    if (reward.currency != null && reward.currency! > 0) {
      await ref.read(progressProvider.notifier).addCurrency(reward.currency!);
    }
    if (reward.hints != null && reward.hints! > 0) {
      await invRepo.grantHints(reward.hints!);
    }
    if (reward.booster != null) {
      await invRepo.grantBooster(reward.booster!);
    }

    await invRepo.recordClaim(claimKey);
    await invRepo.recordClaim('daily_streak_$day');

    if (day == 7) {
      for (int d = 1; d <= 7; d++) {
        await invRepo.removeClaim('daily_streak_$d');
      }
    }

    ref.read(audioServiceProvider).playLevelComplete();
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
          // Background warm clay gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFDF5EA), Color(0xFFF7E2CC)],
                ),
              ),
            ),
          ),

          // Decorative 3D clouds
          Positioned(top: 50, left: -20, child: _CloudShape(size: 130, color: Colors.white.withValues(alpha: 0.75))),
          Positioned(top: 110, right: -30, child: _CloudShape(size: 100, color: Colors.white.withValues(alpha: 0.6))),
          Positioned(top: 240, left: 30, child: _CloudShape(size: 80, color: Colors.white.withValues(alpha: 0.45))),

          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Title: 3D Bevel Text "Cut the Cable"
                  Text(
                    'Cut the\nCable',
                    textAlign: TextAlign.center,
                    style: AppTheme.display.copyWith(
                      color: AppTheme.primaryOrange,
                      fontSize: 42,
                      height: 0.95,
                      shadows: const [
                        Shadow(color: AppTheme.orangeLip, offset: Offset(0, 4), blurRadius: 0),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

                  const SizedBox(height: 8),

                  progressAsync.when(
                    data: (p) => Text(
                      '${p.levels.values.where((l) => l.completed).length} / 100 levels completed',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textDark.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  // Currency & Stars 3D Pill Chips
                  progressAsync.when(
                    data: (p) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Star Chip
                        _3DPillChip(
                          icon: const Icon(Icons.star_rounded, color: AppTheme.goldYellow, size: 22),
                          text: '${p.totalStars}',
                        ),
                        const SizedBox(width: 14),
                        // Coin Chip
                        _3DPillChip(
                          icon: const Text('🪙', style: TextStyle(fontSize: 18)),
                          text: '${p.currency}',
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const Spacer(),

                  // Center 3D Illustration: Nomi with current Level badge & game hurdles!
                  progressAsync.when(
                    data: (p) => _CenterNomiIllustration(nextLevel: p.nextLevel),
                    loading: () => const _CenterNomiIllustration(nextLevel: 1),
                    error: (_, __) => const _CenterNomiIllustration(nextLevel: 1),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .moveY(begin: 0, end: -8, duration: 1400.ms, curve: Curves.easeInOut),

                  const Spacer(),

                  // 3D Orange CTA Button: "Play!"
                  GestureDetector(
                    onTap: () {
                      ref.read(audioServiceProvider).playUiClick();
                      context.push(AppRoutes.levelSelection);
                    },
                    child: Container(
                      width: 220,
                      height: 64,
                      decoration: AppTheme.primaryButton3D(),
                      child: Center(
                        child: Text(
                          'Play!',
                          style: AppTheme.title.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),

                  const SizedBox(height: 24),

                  // 3 Individual Pastel 3D Nav Buttons: Shop, Daily, Settings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _3DNavButton(
                        icon: Icons.storefront_rounded,
                        label: 'Shop',
                        bgColor: const Color(0xFFEDE7F6),
                        contentColor: const Color(0xFF8B7CF6),
                        lipColor: const Color(0xFFD1C4E9),
                        onTap: () {
                          ref.read(audioServiceProvider).playUiClick();
                          context.push(AppRoutes.shop);
                        },
                      ),
                      const SizedBox(width: 14),
                      _3DNavButton(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Daily',
                        bgColor: const Color(0xFFE8F5E9),
                        contentColor: const Color(0xFF4CD964),
                        lipColor: const Color(0xFFC8E6C9),
                        onTap: () {
                          ref.read(audioServiceProvider).playUiClick();
                          final inv = ref.read(inventoryProvider).valueOrNull ?? const Inventory();
                          final today = DateTime.now();
                          final claimKey = 'daily_${today.year}-${today.month}-${today.day}';
                          _showDailyRewardSheet(inv, claimKey);
                        },
                      ),
                      const SizedBox(width: 14),
                      _3DNavButton(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        bgColor: const Color(0xFFFFF8E1),
                        contentColor: const Color(0xFFFFC837),
                        lipColor: const Color(0xFFFFECB3),
                        onTap: () {
                          ref.read(audioServiceProvider).playUiClick();
                          context.push(AppRoutes.settings);
                        },
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3D UI Helpers ─────────────────────────────────────────────────────────────

class _3DPillChip extends StatelessWidget {
  final Widget icon;
  final String text;
  const _3DPillChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          icon,
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.label.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _3DNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color contentColor;
  final Color lipColor;
  final VoidCallback onTap;

  const _3DNavButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.contentColor,
    required this.lipColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 62,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: lipColor, offset: const Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: contentColor, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: contentColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNomiIllustration extends StatelessWidget {
  final int nextLevel;
  const _CenterNomiIllustration({this.nextLevel = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Soft 3D Sun Circle Cutout
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1AE2D0BE),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // 1. Current Level Badge overlay at top center
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppTheme.orangeLip, offset: Offset(0, 3.5), blurRadius: 0),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    'Level $nextLevel',
                    style: AppTheme.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Game Hurdle 1: Floating Portal (Swirling Violet Ring) on Left
          Positioned(
            top: 45,
            left: 22,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF8B7CF6), Color(0xFF6D52E6), Color(0xFF4C38B2)],
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x668B7CF6), blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: const Center(
                child: Icon(Icons.blur_circular_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),

          // 3. Game Hurdle 2: Floating Anti-Gravity Bubble on Right with 3D Candy
          Positioned(
            top: 75,
            right: 22,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x408B7CF6),
                border: Border.all(color: const Color(0xCC8B7CF6), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x338B7CF6), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 6,
                    left: 8,
                    child: Container(
                      width: 10,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/candy/candy.png',
                    width: 26,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text('🍬', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),

          // 4. Game Hurdle 3: Bouncy Bumper / Cushion on Bottom Right
          Positioned(
            bottom: 25,
            right: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.successGreen,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppTheme.greenLip, offset: Offset(0, 3.5), blurRadius: 0),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.unfold_more_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 3),
                  Text('BOUNCE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 5. Game Hurdle 4: Floating 3D Star along cable path
          Positioned(
            top: 50,
            right: 125,
            child: const Icon(
              Icons.star_rounded,
              color: AppTheme.goldYellow,
              size: 28,
              shadows: [
                Shadow(color: AppTheme.goldLip, offset: Offset(0, 2), blurRadius: 0),
              ],
            ),
          ),

          // 6. Nomi Character (Vector SVG / Asset)
          Positioned(
            bottom: 0,
            left: 15,
            child: SvgPicture.asset(
              'assets/images/characters/nomi.svg',
              width: 175,
              height: 175,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => Image.asset(
                'assets/images/characters/nomi.png',
                width: 175,
                height: 175,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 7. Cable Rope & High-Res 3D Candy Image Asset
          Positioned(
            top: 25,
            right: 40,
            child: Column(
              children: [
                // Anchor Pin
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8D6E63),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFF5D4037), offset: Offset(0, 2.5), blurRadius: 0),
                    ],
                  ),
                ),
                // Braided Cable Line
                Container(
                  width: 3.5,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4935A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // High-Res 3D Swirl Candy Image Asset
                Image.asset(
                  'assets/images/candy/candy.png',
                  width: 88,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('🍬', style: TextStyle(fontSize: 48)),
                ),
              ],
            ),
          ),
        ],
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
      height: size * 0.55,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
