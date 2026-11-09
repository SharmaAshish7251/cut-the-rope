import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/player_progress.dart';

const _worldNames = [
  'Candy Garden',
  'Toy Workshop',
  'Sky Islands',
  'Cookie Caves',
  'Jelly Jungle',
  'Frosty Peaks',
  'Lollipop Lairs',
  'Caramel Cosmos',
  'Gummy Galaxy',
  'Candy Citadel',
];

const _worldEmojis = ['🌸', '🔧', '☁️', '🍪', '🌿', '❄️', '🍭', '✨', '🌌', '🏰'];

final _worldGradients = [
  // World 1: Candy Garden
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDF5EA), Color(0xFFF7E2CC), Color(0xFFE8F5E9)],
  ),
  // World 2: Toy Workshop
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2), Color(0xFFFFCC80)],
  ),
  // World 3: Sky Islands
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF80DEEA)],
  ),
  // World 4: Cookie Caves
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8), Color(0xFFBCAAA4)],
  ),
  // World 5: Jelly Jungle
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F8F5), Color(0xFFA3E4D7), Color(0xFF76D7C4)],
  ),
  // World 6: Frosty Peaks
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
  ),
  // World 7: Magic Kingdom
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7), Color(0xFFCE93D8)],
  ),
  // World 8: Cyber City
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC), Color(0xFFB0BEC5)],
  ),
  // World 9: Cosmic Realm
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9), Color(0xFFB39DDB)],
  ),
  // World 10: Candy Citadel
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFE082)],
  ),
];

class LevelSelectionScreen extends ConsumerStatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  ConsumerState<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen> {
  final _pageController = PageController();
  int _currentWorld = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressProvider);
    final configAsync = ref.watch(gameConfigProvider);
    final requirements = configAsync.valueOrNull?.progression.worldStarRequirements ??
        const [0, 18, 45, 75, 110, 145, 185, 225, 260, 285];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: _worldGradients[_currentWorld],
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _worldNames[_currentWorld],
            style: AppTheme.headline.copyWith(
              color: AppTheme.primaryOrange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
            if (progressAsync.hasValue)
              Container(
                margin: const EdgeInsets.only(right: 20),
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
                    const Icon(Icons.star_rounded, color: AppTheme.goldYellow, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${progressAsync.value!.totalStars} / 300',
                      style: AppTheme.label.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (progress) => Column(
            children: [
              const SizedBox(height: 8),

              // 3D World selector tabs (aligned with 20px grid padding)
              _WorldTabBar(
                currentWorld: _currentWorld,
                progress: progress,
                requirements: requirements,
                onWorldChanged: (w) {
                  setState(() => _currentWorld = w);
                  _pageController.animateToPage(
                    w,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),

              const SizedBox(height: 12),

              // Level grid
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (w) => setState(() => _currentWorld = w),
                  itemCount: 10,
                  itemBuilder: (_, worldIdx) => _WorldLevelsGrid(
                    worldId: worldIdx + 1,
                    progress: progress,
                    requirements: requirements,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldTabBar extends StatefulWidget {
  final int currentWorld;
  final PlayerProgress progress;
  final List<int> requirements;
  final ValueChanged<int> onWorldChanged;

  const _WorldTabBar({
    required this.currentWorld,
    required this.progress,
    required this.requirements,
    required this.onWorldChanged,
  });

  @override
  State<_WorldTabBar> createState() => _WorldTabBarState();
}

class _WorldTabBarState extends State<_WorldTabBar> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _WorldTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentWorld != widget.currentWorld) {
      _scrollToTab(widget.currentWorld);
    }
  }

  void _scrollToTab(int index) {
    if (!_scrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = (index * 82.0) - (screenWidth / 2) + 50.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: 10,
        itemBuilder: (_, i) {
          final selected = i == widget.currentWorld;
          final unlocked = widget.progress.isWorldUnlocked(i + 1, widget.requirements);

          final bg = selected
              ? AppTheme.primaryOrange
              : unlocked
                  ? Colors.white
                  : const Color(0xFFE2E8F0);

          final lip = selected
              ? AppTheme.orangeLip
              : unlocked
                  ? AppTheme.cardLip
                  : const Color(0xFFCBD5E1);

          return GestureDetector(
            onTap: () {
              widget.onWorldChanged(i);
              _scrollToTab(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? const Color(0xFFFF9E75) : AppTheme.cardBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(color: lip, offset: const Offset(0, 4), blurRadius: 0),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_worldEmojis[i]} ${i + 1}',
                    style: AppTheme.label.copyWith(
                      color: selected ? Colors.white : AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: selected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorldLevelsGrid extends StatelessWidget {
  final int worldId;
  final PlayerProgress progress;
  final List<int> requirements;

  const _WorldLevelsGrid({
    required this.worldId,
    required this.progress,
    required this.requirements,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isWorldUnlocked(worldId, requirements);

    if (!unlocked) {
      final reqStars = requirements[worldId - 1];
      final starsNeeded = progress.starsNeededForWorld(worldId, requirements);
      final currentStars = progress.totalStars;
      final progressFraction = (currentStars / reqStars).clamp(0.0, 1.0);

      // Locked World 3D Card Overlay
      return Center(
        child: Container(
          width: 300,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.card3D(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3D Gold Lock Icon
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.goldYellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.goldLip, offset: Offset(0, 4), blurRadius: 0),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.lock_rounded, size: 38, color: Colors.white),
                ),
              ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),

              const SizedBox(height: 16),

              Text(
                '${_worldEmojis[worldId - 1]} ${_worldNames[worldId - 1]}',
                style: AppTheme.headline.copyWith(color: AppTheme.primaryOrange, fontSize: 22),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Collect $starsNeeded more stars to unlock this world',
                style: AppTheme.body.copyWith(
                  color: AppTheme.textDark.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 12,
                  backgroundColor: AppTheme.goldYellow.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldYellow),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '$currentStars / $reqStars ⭐',
                style: AppTheme.label.copyWith(color: AppTheme.goldLip, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    final start = (worldId - 1) * 10 + 1;
    final levels = List.generate(10, (i) => start + i);
    final itemWidth = (MediaQuery.of(context).size.width - 40 - 32) / 3;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Row 1: 1, 2, 3
        _LevelRow(
          levelIds: levels.sublist(0, 3),
          progress: progress,
          requirements: requirements,
          itemWidth: itemWidth,
        ),
        const SizedBox(height: 18),

        // Row 2: 4, 5, 6
        _LevelRow(
          levelIds: levels.sublist(3, 6),
          progress: progress,
          requirements: requirements,
          itemWidth: itemWidth,
        ),
        const SizedBox(height: 18),

        // Row 3: 7, 8, 9
        _LevelRow(
          levelIds: levels.sublist(6, 9),
          progress: progress,
          requirements: requirements,
          itemWidth: itemWidth,
        ),
        const SizedBox(height: 18),

        // Row 4: Level 10 Centered
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: itemWidth,
              height: 110,
              child: _LevelButton(
                levelId: levels[9],
                lp: progress.levels[levels[9]] ?? LevelProgress.initial(levels[9]),
                isUnlocked: progress.isLevelUnlocked(levels[9], requirements),
              ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.85, 0.85)),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  final List<int> levelIds;
  final PlayerProgress progress;
  final List<int> requirements;
  final double itemWidth;

  const _LevelRow({
    required this.levelIds,
    required this.progress,
    required this.requirements,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: levelIds.map((levelId) {
        final lp = progress.levels[levelId] ?? LevelProgress.initial(levelId);
        final unlocked = progress.isLevelUnlocked(levelId, requirements);
        return SizedBox(
          width: itemWidth,
          height: 110,
          child: _LevelButton(
            levelId: levelId,
            lp: lp,
            isUnlocked: unlocked,
          )
              .animate()
              .fadeIn(delay: ((levelId % 10) * 30).ms)
              .scale(begin: const Offset(0.85, 0.85)),
        );
      }).toList(),
    );
  }
}

class _LevelButton extends ConsumerWidget {
  final int levelId;
  final LevelProgress lp;
  final bool isUnlocked;

  const _LevelButton({
    required this.levelId,
    required this.lp,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = !isUnlocked;
    final completed = lp.completed;

    final bg = locked
        ? const Color(0xFFCBD5E1)
        : completed
            ? AppTheme.successGreen
            : AppTheme.primaryOrange;

    final lip = locked
        ? const Color(0xFF94A3B8)
        : completed
            ? AppTheme.greenLip
            : AppTheme.orangeLip;

    final border = locked
        ? const Color(0xFFE2E8F0)
        : completed
            ? const Color(0xFF7AE58C)
            : const Color(0xFFFF9E75);

    return GestureDetector(
      onTap: locked
          ? null
          : () {
              ref.read(audioServiceProvider).playUiClick();
              context.push('/play/$levelId');
            },
      child: Column(
        children: [
          // 3D Level Button
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border, width: 2),
                boxShadow: [
                  BoxShadow(color: lip, offset: const Offset(0, 5), blurRadius: 0),
                ],
              ),
              child: Center(
                child: locked
                    ? const Icon(Icons.lock_rounded, color: Colors.white, size: 28)
                    : Text(
                        '$levelId',
                        style: AppTheme.title.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // 3 Star Outlines below button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: completed && i < lp.bestStars
                      ? AppTheme.goldYellow
                      : AppTheme.cardLip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
