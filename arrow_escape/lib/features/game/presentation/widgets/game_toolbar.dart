import 'package:flutter/material.dart';

/// Bottom controls: undo, show paths, restart. Large targets throughout.
class GameToolbar extends StatelessWidget {
  const GameToolbar({
    super.key,
    required this.canUndo,
    required this.undosLeft,
    required this.showPaths,
    required this.onUndo,
    required this.onTogglePaths,
    required this.onRestart,
    required this.onHint,
  });

  final bool canUndo;
  final int undosLeft;
  final bool showPaths;
  final VoidCallback onUndo;
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
            key: const Key('undo'),
            icon: Icons.undo_rounded,
            label: 'Undo',
            semanticLabel: undosLeft > 0 ? 'Undo, $undosLeft free' : 'Undo',
            badge: undosLeft > 0 ? '$undosLeft' : null,
            onPressed: canUndo ? onUndo : null,
          ),
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
              label: 'Hint',
              semanticLabel: 'Hint, watch a video',
              badge: '▶',
              onPressed: onHint,
            ),
          _ToolButton(
            key: const Key('restart'),
            icon: Icons.refresh_rounded,
            label: 'Restart',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.badge,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String? badge;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = IconButton.filledTonal(
      onPressed: onPressed,
      isSelected: selected,
      iconSize: 28,
      style: IconButton.styleFrom(
        minimumSize: const Size(64, 56),
        backgroundColor: selected ? scheme.primaryContainer : null,
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
            if (badge == null)
              button
            else
              Badge(
                label: Text(badge!),
                backgroundColor: scheme.tertiary,
                textColor: scheme.onTertiary,
                child: button,
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
