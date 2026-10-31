import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings as a board of boxes: theme cards with a mini preview, then
/// two-column toggle tiles you tap anywhere to switch.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);

    return Backdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const _Header('Look', Icons.palette_rounded),
            Row(
              key: const Key('theme-mode'),
              children: [
                for (final (mode, label, icon) in const [
                  (ThemeMode.system, 'Auto', Icons.brightness_auto_rounded),
                  (ThemeMode.light, 'Light', Icons.light_mode_rounded),
                  (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
                ]) ...[
                  if (mode != ThemeMode.system) const SizedBox(width: 10),
                  Expanded(
                    child: _ThemeCard(
                      mode: mode,
                      label: label,
                      icon: icon,
                      selected: s.themeMode == mode,
                      onTap: () => c.setThemeMode(mode),
                    ),
                  ),
                ],
              ],
            ),
            const _Header('Accessibility', Icons.accessibility_new_rounded),
            _TileGrid(
              children: [
                _ToggleTile(
                  key: const Key('thick-arrows'),
                  icon: Icons.line_weight_rounded,
                  colors: const [Color(0xFF9B87FF), Palette.primary],
                  title: 'Thick arrows',
                  subtitle: 'Bolder, easier to tap',
                  value: s.thickArrows,
                  onChanged: c.setThickArrows,
                ),
                _ToggleTile(
                  key: const Key('high-contrast'),
                  icon: Icons.contrast_rounded,
                  colors: const [Color(0xFF6B7280), Color(0xFF1F2937)],
                  title: 'High contrast',
                  subtitle: 'Stronger colours',
                  value: s.highContrast,
                  onChanged: c.setHighContrast,
                ),
                _ToggleTile(
                  key: const Key('colorblind'),
                  icon: Icons.visibility_rounded,
                  colors: const [Color(0xFF56B4E9), Color(0xFF0072B2)],
                  title: 'Colorblind',
                  subtitle: 'Safe palette + symbols',
                  value: s.colorblind,
                  onChanged: c.setColorblind,
                ),
                _ToggleTile(
                  key: const Key('reduce-motion'),
                  icon: Icons.slow_motion_video_rounded,
                  colors: const [Color(0xFF7CE3B5), Palette.tertiary],
                  title: 'Reduce motion',
                  subtitle: 'Calmer animations',
                  value: s.reduceMotion,
                  onChanged: c.setReduceMotion,
                ),
              ],
            ),
            const _Header('Feedback', Icons.graphic_eq_rounded),
            _TileGrid(
              children: [
                _ToggleTile(
                  key: const Key('sound'),
                  icon: s.sound
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  colors: const [Color(0xFFFFD25E), Palette.sun],
                  title: 'Sound',
                  subtitle: 'Soft move effects',
                  value: s.sound,
                  onChanged: c.setSound,
                ),
                _ToggleTile(
                  key: const Key('haptics'),
                  icon: Icons.vibration_rounded,
                  colors: const [Color(0xFFFF9A7A), Palette.secondary],
                  title: 'Vibration',
                  subtitle: 'Gentle haptics',
                  value: s.haptics,
                  onChanged: c.setHaptics,
                ),
              ],
            ),
            const _Header('Privacy', Icons.lock_rounded),
            _TileGrid(
              children: [
                _ToggleTile(
                  key: const Key('share-analytics'),
                  icon: Icons.insights_rounded,
                  colors: const [Color(0xFFFFA8D9), Palette.pink],
                  title: 'Share usage analytics',
                  subtitle: 'Anonymous stats',
                  value: s.shareAnalytics,
                  onChanged: c.setShareAnalytics,
                ),
              ],
            ),
            const _Header('Account', Icons.person_rounded),
            _ActionTile(
              key: const Key('open-shop'),
              icon: Icons.restore_rounded,
              colors: const [Color(0xFF7CC8FF), Palette.sky],
              title: 'Shop & restore purchases',
              onTap: () => context.push(Routes.shop),
            ),
            FutureBuilder<bool>(
              future: ref.read(adServiceProvider).privacyOptionsRequired(),
              builder: (context, snap) => snap.data == true
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ActionTile(
                        key: const Key('privacy-options'),
                        icon: Icons.privacy_tip_rounded,
                        colors: const [Color(0xFFC9B6FF), Palette.primary],
                        title: 'Privacy options',
                        subtitle: 'Change your ad consent choices.',
                        onTap: () =>
                            ref.read(adServiceProvider).showPrivacyOptions(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              text.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 1.6,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two boxes per row; a lone last box stays half width.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final w = (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}

/// A box that is the switch: tap anywhere to toggle. On shows a coloured
/// border and an "On" pill.
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    super.key,
    required this.icon,
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      toggled: value,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: value ? colors.last : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: SoftCard(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          onTap: () => onChanged(!value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBubble(
                    icon: icon,
                    colors: value
                        ? colors
                        : const [Color(0xFFC9C5D8), Color(0xFF9C97B0)],
                    size: 40,
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: value
                          ? colors.last
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      value ? 'On' : 'Off',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: value ? Colors.white : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                style: theme.textTheme.titleMedium?.copyWith(height: 1.15),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light / dark / auto as cards with a tiny preview of the screen.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget half(Color bg, Color fg) => Expanded(
      child: Container(
        color: bg,
        child: Center(
          child: Icon(Icons.north_east_rounded, color: fg, size: 18),
        ),
      ),
    );
    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (mode != ThemeMode.dark)
              half(Palette.washTop, Palette.primaryDeep),
            if (mode != ThemeMode.light) half(Colors.black, Colors.white),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? Palette.primary : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(8),
          onTap: onTap,
          child: Column(
            children: [
              preview,
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    size: 18,
                    color: selected
                        ? Palette.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.colors,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            IconBubble(icon: icon, colors: colors, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle != null)
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
