import 'package:arrow_escape/core/theme/palette.dart';
import 'package:flutter/material.dart';

/// Remaining hearts; a lost heart pops and fades.
class HeartsBar extends StatelessWidget {
  const HeartsBar({super.key, required this.hearts, required this.max});

  final int hearts;
  final int max;

  @override
  Widget build(BuildContext context) {
    final count = hearts > max ? hearts : max;
    return Semantics(
      label: '$hearts of $max hearts left',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedScale(
                scale: i < hearts ? 1 : 0.8,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Icon(
                  i < hearts
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: i < hearts
                      ? Palette.heart
                      : Theme.of(context).colorScheme.outlineVariant,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
