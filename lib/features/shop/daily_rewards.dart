import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/inventory_item.dart';

/// Daily reward schedule — 7-day cycle.
class DailyRewardDef {
  final int day;
  final String emoji;
  final String label;
  final int? currency;
  final BoosterType? booster;
  final int? hints;

  const DailyRewardDef({
    required this.day,
    required this.emoji,
    required this.label,
    this.currency,
    this.booster,
    this.hints,
  });
}

const dailyRewards = [
  DailyRewardDef(day: 1, emoji: '💰', label: '25 Coins', currency: 25),
  DailyRewardDef(day: 2, emoji: '💡', label: '1 Hint', hints: 1),
  DailyRewardDef(day: 3, emoji: '💰', label: '50 Coins', currency: 50),
  DailyRewardDef(day: 4, emoji: '⏱', label: 'Slow Motion', booster: BoosterType.slowMotion),
  DailyRewardDef(day: 5, emoji: '💰', label: '75 Coins', currency: 75),
  DailyRewardDef(day: 6, emoji: '🛡', label: 'Candy Rescue', booster: BoosterType.candyRescue),
  DailyRewardDef(day: 7, emoji: '🎁', label: '100 Coins + Hint', currency: 100, hints: 1),
];

/// Bottom sheet for daily reward claiming matching 3D design.
class DailyRewardSheet extends StatelessWidget {
  final int currentDay; // 1-7
  final bool alreadyClaimed;
  final VoidCallback onClaim;
  final VoidCallback onDismiss;

  const DailyRewardSheet({
    super.key,
    required this.currentDay,
    required this.alreadyClaimed,
    required this.onClaim,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final days1To6 = dailyRewards.sublist(0, 6);
    final day7 = dailyRewards.last;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, -6),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Daily Rewards',
            style: AppTheme.headline.copyWith(
              color: AppTheme.primaryOrange,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Come back every day for free rewards!',
            style: AppTheme.caption.copyWith(
              color: AppTheme.textDark.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          // Days 1-6 Grid (3 columns)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: days1To6.map((r) {
              final isCurrent = r.day == currentDay;
              final isPast = r.day < currentDay;

              return _DayCard(
                reward: r,
                state: isPast
                    ? _DayState.claimed
                    : isCurrent
                        ? (alreadyClaimed ? _DayState.claimed : _DayState.available)
                        : _DayState.locked,
              ).animate().fadeIn(delay: (r.day * 50).ms).scale(
                    begin: const Offset(0.85, 0.85),
                    curve: Curves.easeOut,
                  );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Day 7 Grand Gold Chest Banner
          _Day7Banner(
            reward: day7,
            state: currentDay < 7
                ? _DayState.locked
                : (alreadyClaimed ? _DayState.claimed : _DayState.available),
          ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 24),

          // 3D Orange Claim Button
          GestureDetector(
            onTap: alreadyClaimed ? null : onClaim,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: alreadyClaimed
                  ? BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(999),
                    )
                  : AppTheme.primaryButton3D(),
              child: Center(
                child: Text(
                  alreadyClaimed ? 'Already Claimed Today ✓' : 'Claim',
                  style: AppTheme.title.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DayState { claimed, available, locked }

class _DayCard extends StatelessWidget {
  final DailyRewardDef reward;
  final _DayState state;
  const _DayCard({required this.reward, required this.state});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 40 - 20) / 3;
    final Color bg;
    final Color border;
    final Color lip;

    switch (state) {
      case _DayState.claimed:
        bg = const Color(0xFFE8F5E9);
        border = AppTheme.successGreen;
        lip = AppTheme.greenLip;
        break;
      case _DayState.available:
        bg = const Color(0xFFFFF8E1);
        border = AppTheme.goldYellow;
        lip = AppTheme.goldLip;
        break;
      case _DayState.locked:
        bg = Colors.white;
        border = AppTheme.cardBorder;
        lip = AppTheme.cardLip;
        break;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: state == _DayState.available ? 2 : 1.5),
        boxShadow: [
          BoxShadow(color: lip, offset: const Offset(0, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Day ${reward.day}',
            style: AppTheme.caption.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: state == _DayState.locked ? Colors.grey : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state == _DayState.claimed ? '✓' : reward.emoji,
            style: TextStyle(
              fontSize: 26,
              color: state == _DayState.claimed ? AppTheme.greenLip : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reward.label,
            style: AppTheme.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: state == _DayState.locked
                  ? Colors.grey
                  : AppTheme.textDark.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Day7Banner extends StatelessWidget {
  final DailyRewardDef reward;
  final _DayState state;

  const _Day7Banner({required this.reward, required this.state});

  @override
  Widget build(BuildContext context) {
    final bool available = state == _DayState.available;
    final bool claimed = state == _DayState.claimed;

    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: available
              ? const [Color(0xFFFFD54F), Color(0xFFFFB300)]
              : claimed
                  ? const [Color(0xFF81C784), Color(0xFF4CAF50)]
                  : const [Color(0xFFFFE082), Color(0xFFFFD54F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: AppTheme.goldLip, offset: Offset(0, 5), blurRadius: 0),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day 7',
                  style: AppTheme.title.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  reward.label,
                  style: AppTheme.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 10,
            child: const Text('🎁', style: TextStyle(fontSize: 54)),
          ),
        ],
      ),
    );
  }
}
