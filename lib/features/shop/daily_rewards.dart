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

/// Bottom sheet for daily reward claiming.
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            offset: Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Daily Rewards',
              style: AppTheme.headline.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 4),
          Text('Come back every day for free rewards!',
              style: AppTheme.caption.copyWith(
                color: AppTheme.textDark.withValues(alpha: 0.5),
              )),
          const SizedBox(height: 20),

          // 7-day grid
          Wrap(
            spacing: 6,
            runSpacing: 9,
            children: dailyRewards.map((r) {
              final isCurrent = r.day == currentDay;
              final isPast = r.day < currentDay;

              return _DayCard(
                reward: r,
                state: isPast
                    ? _DayState.claimed
                    : isCurrent
                        ? (alreadyClaimed ? _DayState.claimed : _DayState.available)
                        : _DayState.locked,
              ).animate().fadeIn(delay: (r.day * 60).ms).scale(
                    begin: const Offset(0.8, 0.8),
                    curve: Curves.easeOut,
                  );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Claim button
          Padding(
            padding: const EdgeInsets.only(bottom:32),
          child:
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: alreadyClaimed ? null : onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: alreadyClaimed ? Colors.grey : AppTheme.primary,
              ),
              child: Text(
                alreadyClaimed ? 'Already Claimed Today ✓' : 'Claim Today\'s Reward!',
                style: AppTheme.label.copyWith(color: Colors.white),
              ),
            ),
          ),),

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
    final width = (MediaQuery.of(context).size.width - 40 - 24) / 3;
    final Color bg;
    final Color border;
    switch (state) {
      case _DayState.claimed:
        bg = AppTheme.success.withValues(alpha: 0.1);
        border = AppTheme.success;
        break;
      case _DayState.available:
        bg = AppTheme.accent.withValues(alpha: 0.15);
        border = AppTheme.accent;
        break;
      case _DayState.locked:
        bg = Colors.grey.withValues(alpha: 0.05);
        border = Colors.grey.shade300;
        break;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: state == _DayState.available ? 2 : 1),
      ),
      child: Column(
        children: [
          Text('Day ${reward.day}',
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: state == _DayState.locked ? Colors.grey : AppTheme.textDark,
              )),
          const SizedBox(height: 4),
          Text(
            state == _DayState.claimed ? '✓' : reward.emoji,
            style: TextStyle(
              fontSize: 24,
              color: state == _DayState.locked ? Colors.grey.shade400 : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reward.label,
            style: AppTheme.caption.copyWith(
              fontSize: 10,
              color: state == _DayState.locked
                  ? Colors.grey.shade400
                  : AppTheme.textDark.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
