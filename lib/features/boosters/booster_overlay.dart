import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/inventory_item.dart';

/// 3D Bottom sheet overlay for selecting and activating a booster during gameplay.
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.black54,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
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
              // Handle bar
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
                'Boosters',
                style: AppTheme.headline.copyWith(
                  color: AppTheme.primaryOrange,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

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

              const SizedBox(height: 16),

              GestureDetector(
                onTap: onCancel,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFFCBD5E1), offset: Offset(0, 4), blurRadius: 0),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: AppTheme.label.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.card3D(),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
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

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(type.displayName, style: AppTheme.label.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 6),
                    if (count > 0)
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

          // Actions
          if (count > 0)
            _3DSmallButton(
              label: 'Use',
              bgColor: AppTheme.primaryOrange,
              lipColor: AppTheme.orangeLip,
              onTap: onActivate!,
            )
          else
            _3DSmallButton(
              label: '🎬 Earn',
              bgColor: AppTheme.goldYellow,
              lipColor: AppTheme.goldLip,
              textColor: AppTheme.textDark,
              onTap: onEarn,
            ),
        ],
      ),
    );
  }
}

class _3DSmallButton extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color lipColor;
  final Color textColor;
  final VoidCallback onTap;

  const _3DSmallButton({
    required this.label,
    required this.bgColor,
    required this.lipColor,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: lipColor, offset: const Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
