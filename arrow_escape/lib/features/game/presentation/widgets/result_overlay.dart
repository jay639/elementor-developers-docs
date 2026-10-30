import 'package:arrow_escape/core/theme/palette.dart';
import 'package:flutter/material.dart';

/// Win / lose card shown over the board.
class ResultOverlay extends StatelessWidget {
  const ResultOverlay.win({
    super.key,
    required String this.title,
    required int this.stars,
    required this.coins,
    required this.onPrimary,
    required this.onHome,
    required this.hasNext,
    this.onDoubleCoins,
  }) : won = true,
       onExtraHeart = null;

  const ResultOverlay.lose({
    super.key,
    required this.onPrimary,
    required this.onHome,
    this.onExtraHeart,
  }) : won = false,
       title = null,
       stars = null,
       coins = 0,
       hasNext = false,
       onDoubleCoins = null;

  final bool won;
  final String? title;
  final int? stars;
  final int coins;
  final bool hasNext;

  /// Next level when won, retry when lost.
  final VoidCallback onPrimary;
  final VoidCallback onHome;

  /// Rewarded actions; null hides them.
  final VoidCallback? onDoubleCoins;
  final VoidCallback? onExtraHeart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.scrim.withValues(alpha: 0.35),
      child: Center(
        child: SingleChildScrollView(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Card(
              margin: const EdgeInsets.all(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      won ? title! : 'Out of hearts',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (won)
                      _Stars(stars: stars!)
                    else
                      const Icon(
                        Icons.heart_broken_rounded,
                        size: 64,
                        color: Palette.heart,
                        semanticLabel: 'No hearts left',
                      ),
                    const SizedBox(height: 8),
                    if (won && coins > 0)
                      Semantics(
                        label: 'Earned $coins coins',
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: Palette.star,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+$coins',
                              key: const Key('coins-earned'),
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        won
                            ? 'Traffic is flowing again.'
                            : 'Take a breath and try a different order.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    if (onDoubleCoins != null || onExtraHeart != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          key: const Key('result-rewarded'),
                          onPressed: onDoubleCoins ?? onExtraHeart,
                          icon: const Icon(Icons.smart_display_rounded),
                          label: Text(
                            won ? 'Double coins' : 'Continue with +1 heart',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('result-primary'),
                        onPressed: onPrimary,
                        child: Text(
                          won ? (hasNext ? 'Next level' : 'Done') : 'Try again',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('result-home'),
                      onPressed: onHome,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(120, 48),
                      ),
                      child: const Text('Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars of 3 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + i * 160),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: 0.4 + 0.6 * v, child: child),
              child: Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: i == 1 ? 64 : 52,
                color: i < stars
                    ? Palette.star
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}
