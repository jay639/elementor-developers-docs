import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    Widget toggle(
      String key,
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile(
      key: Key(key),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<ThemeMode>(
              key: const Key('theme-mode'),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded),
                  label: Text('Auto'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded),
                  label: Text('Dark'),
                ),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => c.setThemeMode(v.first),
            ),
          ),
          header('Accessibility'),
          toggle(
            'thick-arrows',
            'Thick arrows',
            'Bolder vehicles that are easier to see and tap.',
            s.thickArrows,
            c.setThickArrows,
          ),
          toggle(
            'high-contrast',
            'High contrast',
            'Stronger colours and outlines.',
            s.highContrast,
            c.setHighContrast,
          ),
          toggle(
            'colorblind',
            'Colorblind mode',
            'Colour-safe palette plus symbols on lights and paths.',
            s.colorblind,
            c.setColorblind,
          ),
          toggle(
            'reduce-motion',
            'Reduce motion',
            'Shorter, calmer animations.',
            s.reduceMotion,
            c.setReduceMotion,
          ),
          header('Feedback'),
          toggle(
            'sound',
            'Sound',
            'Soft effects when cars move.',
            s.sound,
            c.setSound,
          ),
          toggle(
            'haptics',
            'Vibration',
            'Gentle haptics on moves and bumps.',
            s.haptics,
            c.setHaptics,
          ),
        ],
      ),
    );
  }
}
