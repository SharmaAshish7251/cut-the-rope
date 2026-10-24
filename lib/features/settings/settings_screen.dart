import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final audio = ref.read(audioServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Settings',
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('Audio'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: AppTheme.card3D(),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.music_note_rounded,
                  label: 'Music',
                  value: settings.musicEnabled,
                  onChanged: (v) {
                    notifier.toggleMusic();
                    audio.configure(music: v, sound: settings.soundEnabled);
                  },
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.volume_up_rounded,
                  label: 'Sound Effects',
                  value: settings.soundEnabled,
                  onChanged: (v) {
                    notifier.toggleSound();
                    audio.configure(music: settings.musicEnabled, sound: v);
                  },
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                _SettingsTile(
                  icon: Icons.vibration_rounded,
                  label: 'Vibration',
                  value: settings.vibrationEnabled,
                  onChanged: (_) => notifier.toggleVibration(),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          const _SectionTitle('About'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: AppTheme.card3D(),
            child: Column(
              children: [
                const _InfoTile(icon: Icons.info_outline_rounded, label: 'Version', value: '1.0.2'),
                const Divider(height: 1, color: AppTheme.cardBorder),
                const _InfoTile(icon: Icons.security_rounded, label: 'Privacy Policy', value: ''),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: AppTheme.label.copyWith(
          color: AppTheme.textDark.withValues(alpha: 0.6),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryOrange,
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textDark.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (value.isEmpty)
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}
