import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
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
    this.nextLabel = 'Next level',
    this.unlocked = const [],
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
       onDoubleCoins = null,
       nextLabel = '',
       unlocked = const [];

  final bool won;
  final String? title;
  final int? stars;
  final int coins;
  final bool hasNext;

  /// Primary button text when there is a next level.
  final String nextLabel;

  /// Names of pictures this win unlocked.
  final List<String> unlocked;

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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SoftCard(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
                radius: 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      won ? title! : 'Out of hearts',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: won ? Palette.primaryDeep : Palette.secondary,
                      ),
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
                    for (final name in unlocked) ...[
                      const SizedBox(height: 14),
                      SoftCard(
                        key: Key('unlocked-$name'),
                        gradient: const LinearGradient(
                          colors: Palette.heroGradient,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Palette.star,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'New picture unlocked: $name!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    CandyButton(
                      key: const Key('result-primary'),
                      height: 58,
                      fontSize: 20,
                      colors: won ? Palette.playGradient : Palette.heroGradient,
                      onPressed: onPrimary,
                      label: won ? (hasNext ? nextLabel : 'Done') : 'Try again',
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
