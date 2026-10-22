import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/inventory_item.dart';

/// Bottom sheet overlay for selecting and activating a booster during gameplay.
class BoosterOverlay extends StatelessWidget {
  final Inventory inventory;
  final void Function(BoosterType type) onActivate;
  final void Function(BoosterType type) onEarn;
  final VoidCallback onCancel;

  const BoosterOverlay({
    super.key,
    required this.inventory,
    required this.onActivate,
    required this.onEarn,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Boosters',
                  style: AppTheme.headline.copyWith(color: AppTheme.secondary)),
              const SizedBox(height: 16),

              ...BoosterType.values.asMap().entries.map((entry) {
                final i = entry.key;
                final type = entry.value;
                final count = inventory.boosterCount(type);
                return _BoosterCard(
                  type: type,
                  count: count,
                  onActivate: count > 0 ? () => onActivate(type) : null,
                  onEarn: () => onEarn(type),
                ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.15);
              }),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onCancel,
                  child: Text('Cancel',
                      style: AppTheme.label.copyWith(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: 1.0, curve: Curves.easeOutCubic, duration: 400.ms),
      ),
    );
  }
}

class _BoosterCard extends StatelessWidget {
  final BoosterType type;
  final int count;
  final VoidCallback? onActivate;
  final VoidCallback onEarn;

  const _BoosterCard({
    required this.type,
    required this.count,
    required this.onActivate,
    required this.onEarn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.clayBox(color: AppTheme.surface),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: AppTheme.clayBox(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              radius: 14,
            ),
            child: Center(
              child: Text(type.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(type.displayName, style: AppTheme.label),
                    const SizedBox(width: 8),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '×$count',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  type.description,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (count > 0)
            _SmallButton(
              label: 'Use',
              color: AppTheme.primary,
              onTap: onActivate!,
            )
          else
            _SmallButton(
              label: '🎬 Earn',
              color: AppTheme.accent,
              onTap: onEarn,
            ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label,
          style: AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}
