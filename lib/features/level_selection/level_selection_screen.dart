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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_worldNames[_currentWorld],
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
        actions: [
          if (progressAsync.hasValue)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: AppTheme.clayBox(color: AppTheme.surface, radius: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${progressAsync.value!.totalStars} / 300',
                    style: AppTheme.label.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
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
            // World selector tabs
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
                if (!progress.isWorldUnlocked(w + 1, requirements)) {
                  final needed = progress.starsNeededForWorld(w + 1, requirements);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔒 Collect $needed more stars to unlock ${_worldNames[w]}!'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.textDark,
                    ),
                  );
                }
              },
            ),
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
    );
  }
}

class _WorldTabBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 10,
        itemBuilder: (_, i) {
          final selected = i == currentWorld;
          final unlocked = progress.isWorldUnlocked(i + 1, requirements);

          return GestureDetector(
            onTap: () => onWorldChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary
                    : unlocked
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_worldEmojis[i]} ${i + 1}',
                    style: AppTheme.label.copyWith(
                      color: selected
                          ? Colors.white
                          : unlocked
                              ? AppTheme.primary
                              : Colors.grey,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: selected ? Colors.white70 : Colors.grey.shade500,
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

      return Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.clayBox(color: AppTheme.surface),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 56, color: AppTheme.accent)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1200.ms),
              const SizedBox(height: 12),
              Text(
                '${_worldEmojis[worldId - 1]} ${_worldNames[worldId - 1]}',
                style: AppTheme.headline.copyWith(color: AppTheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Collect $starsNeeded more stars to unlock this world',
                style: AppTheme.body.copyWith(color: AppTheme.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 12,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$currentStars / $reqStars ⭐',
                style: AppTheme.label.copyWith(color: AppTheme.accent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    final start = (worldId - 1) * 10 + 1;
    final levels = List.generate(10, (i) => start + i);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: levels.length,
      itemBuilder: (context, i) {
        final levelId = levels[i];
        final lp = progress.levels[levelId] ?? LevelProgress.initial(levelId);
        return _LevelButton(levelId: levelId, lp: lp)
            .animate()
            .fadeIn(delay: (i * 40).ms)
            .scale(begin: const Offset(0.8, 0.8));
      },
    );
  }
}

class _LevelButton extends ConsumerWidget {
  final int levelId;
  final LevelProgress lp;

  const _LevelButton({required this.levelId, required this.lp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = !lp.unlocked;
    final completed = lp.completed;

    final bg = locked
        ? Colors.grey.shade300
        : completed
            ? AppTheme.success
            : AppTheme.primary;

    return GestureDetector(
      onTap: locked
          ? null
          : () {
              ref.read(audioServiceProvider).playUiClick();
              context.push('/play/$levelId');
            },
      child: Container(
        decoration: AppTheme.clayBox(color: bg, radius: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked)
              const Icon(Icons.lock_rounded, color: Colors.grey, size: 20)
            else
              Text('$levelId',
                  style: AppTheme.title.copyWith(color: Colors.white, fontSize: 18)),
            if (completed) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: i < lp.bestStars ? AppTheme.accent : Colors.white38,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
