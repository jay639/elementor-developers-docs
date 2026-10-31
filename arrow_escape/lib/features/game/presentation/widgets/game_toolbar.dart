import 'package:arrow_escape/core/theme/palette.dart';
import 'package:flutter/material.dart';

/// Bottom controls: show paths, hint, restart. Large targets throughout.
class GameToolbar extends StatelessWidget {
  const GameToolbar({
    super.key,
    required this.showPaths,
    required this.onTogglePaths,
    required this.onRestart,
    required this.onHint,
    this.onSkip,
  });

  /// Pay coins to skip the level; null hides the button.
  final VoidCallback? onSkip;

  final bool showPaths;
  final VoidCallback onTogglePaths;
  final VoidCallback onRestart;

  /// Rewarded hint; null hides the button.
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolButton(
            key: const Key('paths'),
            icon: showPaths ? Icons.route_rounded : Icons.alt_route_rounded,
            label: showPaths ? 'Hide paths' : 'Show paths',
            selected: showPaths,
            onPressed: onTogglePaths,
          ),
          if (onHint != null)
            _ToolButton(
              key: const Key('hint'),
              icon: Icons.lightbulb_rounded,
              color: Palette.sun,
              label: 'Hint',
              semanticLabel: 'Hint, watch a video',
              videoBadge: true,
              onPressed: onHint,
            ),
          if (onSkip != null)
            _ToolButton(
              key: const Key('skip'),
              icon: Icons.skip_next_rounded,
              color: Palette.tertiary,
              label: 'Skip',
              semanticLabel: 'Skip level for coins',
              onPressed: onSkip,
            ),
          _ToolButton(
            key: const Key('restart'),
            icon: Icons.refresh_rounded,
            color: Palette.secondary,
            label: 'Restart',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

Widget _shadowed(Widget child) => DecoratedBox(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Palette.primary.withValues(alpha: 0.18),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
  ),
  child: child,
);

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.videoBadge = false,
    this.semanticLabel,
    this.color = Palette.primary,
  });

  final Color color;

  final IconData icon;
  final String label;

  /// Marks actions that play a rewarded video.
  final bool videoBadge;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final button = IconButton(
      onPressed: onPressed,
      isSelected: selected,
      iconSize: 30,
      style: IconButton.styleFrom(
        minimumSize: const Size(64, 58),
        backgroundColor: selected
            ? Palette.primary
            : (dark ? Palette.tileDark : Colors.white),
        foregroundColor: selected ? Colors.white : color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      icon: Icon(icon),
    );
    return Expanded(
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        toggled: selected ? true : null,
        label: semanticLabel ?? label,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!videoBadge)
              _shadowed(button)
            else
              Badge(
                label: const Icon(
                  Icons.play_arrow_rounded,
                  size: 12,
                  color: Colors.white,
                ),
                backgroundColor: scheme.tertiary,
                textColor: scheme.onTertiary,
                child: _shadowed(button),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: onPressed == null ? scheme.outline : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
