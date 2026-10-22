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
        title: Text('Settings', style: AppTheme.headline.copyWith(color: AppTheme.primary)),
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('Audio'),
          _SettingsTile(
            icon: Icons.music_note_rounded,
            label: 'Music',
            value: settings.musicEnabled,
            onChanged: (v) {
              notifier.toggleMusic();
              audio.configure(music: v, sound: settings.soundEnabled);
            },
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.volume_up_rounded,
            label: 'Sound Effects',
            value: settings.soundEnabled,
            onChanged: (v) {
              notifier.toggleSound();
              audio.configure(music: settings.musicEnabled, sound: v);
            },
          ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.vibration_rounded,
            label: 'Vibration',
            value: settings.vibrationEnabled,
            onChanged: (_) => notifier.toggleVibration(),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
          const SizedBox(height: 24),
          const _SectionTitle('About'),
          const _InfoTile(icon: Icons.info_outline_rounded, label: 'Version', value: '1.0.0')
              .animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 10),
          const _InfoTile(icon: Icons.privacy_tip_rounded, label: 'Privacy Policy', value: '')
              .animate().fadeIn(delay: 300.ms),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: AppTheme.label.copyWith(color: AppTheme.textDark.withValues(alpha: 0.5))),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.clayBox(color: AppTheme.surface),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: AppTheme.body)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.clayBox(color: AppTheme.surface),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: AppTheme.body)),
          if (value.isNotEmpty)
            Text(value, style: AppTheme.caption.copyWith(color: AppTheme.textDark.withValues(alpha: 0.5))),
          if (value.isEmpty)
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}
