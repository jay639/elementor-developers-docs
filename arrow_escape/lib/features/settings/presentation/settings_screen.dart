import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/review/data/review_service.dart';
import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Settings as inset grouped lists: the pattern both iOS Settings and
/// Android's settings use, so it feels native on each. Rows have a small
/// coloured icon tile, a title, an optional hint and a platform switch.
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
            _Group(
              title: 'Appearance',
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _ThemePicker(
                    value: s.themeMode,
                    onChanged: c.setThemeMode,
                  ),
                ),
              ],
            ),
            _Group(
              title: 'Accessibility',
              footer:
                  'Colorblind and high-contrast modes replace skin '
                  'colours so every arrow stays easy to tell apart.',
              children: [
                _SwitchRow(
                  key: const Key('thick-arrows'),
                  icon: Icons.line_weight_rounded,
                  color: Palette.primary,
                  title: 'Thick arrows',
                  subtitle: 'Bolder lines, easier to tap',
                  value: s.thickArrows,
                  onChanged: c.setThickArrows,
                ),
                _SwitchRow(
                  key: const Key('high-contrast'),
                  icon: Icons.contrast_rounded,
                  color: const Color(0xFF374151),
                  title: 'High contrast',
                  subtitle: 'Stronger colours and outlines',
                  value: s.highContrast,
                  onChanged: c.setHighContrast,
                ),
                _SwitchRow(
                  key: const Key('colorblind'),
                  icon: Icons.visibility_rounded,
                  color: const Color(0xFF0072B2),
                  title: 'Colorblind mode',
                  subtitle: 'Safe palette plus symbols',
                  value: s.colorblind,
                  onChanged: c.setColorblind,
                ),
                _SwitchRow(
                  key: const Key('reduce-motion'),
                  icon: Icons.slow_motion_video_rounded,
                  color: Palette.tertiary,
                  title: 'Reduce motion',
                  subtitle: 'Shorter, calmer animations',
                  value: s.reduceMotion,
                  onChanged: c.setReduceMotion,
                ),
              ],
            ),
            _Group(
              title: 'Sound & feel',
              children: [
                _SwitchRow(
                  key: const Key('sound'),
                  icon: s.sound
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: Palette.sun,
                  title: 'Sound',
                  value: s.sound,
                  onChanged: c.setSound,
                ),
                _SwitchRow(
                  key: const Key('haptics'),
                  icon: Icons.vibration_rounded,
                  color: Palette.secondary,
                  title: 'Vibration',
                  value: s.haptics,
                  onChanged: c.setHaptics,
                ),
              ],
            ),
            _Group(
              title: 'Privacy',
              footer:
                  'Anonymous gameplay stats help us tune level '
                  'difficulty. No personal data is collected.',
              children: [
                _SwitchRow(
                  key: const Key('share-analytics'),
                  icon: Icons.insights_rounded,
                  color: Palette.pink,
                  title: 'Share usage analytics',
                  value: s.shareAnalytics,
                  onChanged: c.setShareAnalytics,
                ),
                FutureBuilder<bool>(
                  future: ref.read(adServiceProvider).privacyOptionsRequired(),
                  builder: (context, snap) => snap.data == true
                      ? _LinkRow(
                          key: const Key('privacy-options'),
                          icon: Icons.privacy_tip_rounded,
                          color: const Color(0xFF7A4DF0),
                          title: 'Privacy options',
                          subtitle: 'Change your ad consent choices',
                          onTap: () =>
                              ref.read(adServiceProvider).showPrivacyOptions(),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            _Group(
              title: 'Account',
              children: [
                _LinkRow(
                  key: const Key('open-shop'),
                  icon: Icons.restore_rounded,
                  color: Palette.sky,
                  title: 'Shop & restore purchases',
                  onTap: () => context.push(Routes.shop),
                ),
                _LinkRow(
                  key: const Key('rate-app'),
                  icon: Icons.star_rounded,
                  color: Palette.secondary,
                  title: 'Rate Arrow Escape',
                  subtitle: 'Enjoying it? A review helps a lot',
                  onTap: () =>
                      ref.read(reviewServiceProvider).openStoreListing(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled, rounded card of rows with hairline dividers between them.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children, this.footer});

  final String title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final divider = Divider(
      height: 1,
      thickness: 0.6,
      indent: 60,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.1,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Material(
            color: dark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) divider,
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The small rounded-square icon used by system settings on both
/// platforms.
class _IconTile extends StatelessWidget {
  const _IconTile(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: Colors.white, size: 18),
  );
}

class _RowText extends StatelessWidget {
  const _RowText(this.title, this.subtitle);

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// A row that is a switch: the whole row toggles, with the platform's own
/// switch (Cupertino on iOS, Material on Android) on the right.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            child: Row(
              children: [
                _IconTile(icon, color),
                const SizedBox(width: 16),
                Expanded(child: _RowText(title, subtitle)),
                Switch.adaptive(
                  value: value,
                  activeTrackColor: Palette.primary,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
            child: Row(
              children: [
                _IconTile(icon, color),
                const SizedBox(width: 16),
                Expanded(child: _RowText(title, subtitle)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Auto / Light / Dark as a sliding segmented control, which reads as
/// native on both platforms.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [
    (ThemeMode.system, 'Auto', Icons.brightness_auto_rounded),
    (ThemeMode.light, 'Light', Icons.light_mode_rounded),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      key: const Key('theme-mode'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFEFEDF6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final (mode, label, icon) in _options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == mode,
                label: '$label theme',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    decoration: BoxDecoration(
                      color: value == mode
                          ? (dark ? const Color(0xFF636366) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: value == mode && !dark
                          ? const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 6),
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
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
