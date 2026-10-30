import 'dart:math' as math;

import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/coin_chip.dart';
import 'package:arrow_escape/features/ads/presentation/map_banner.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/level_map/city_block_painter.dart';
import 'package:arrow_escape/features/progress/application/progress_controller.dart';
import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The campaign as a growing city: one card per 10-level block.
class LevelMapScreen extends ConsumerStatefulWidget {
  const LevelMapScreen({super.key});

  static const blockSize = 10;
  static const blockExtent = 300.0;

  static const streetNames = [
    'Maple Street',
    'Harbor Row',
    'Cherry Lane',
    'Station Square',
    'Lantern Way',
    'Willow Park',
    'Market Hill',
    'Clocktower Close',
    'Riverside',
    'Bakers Alley',
    'Lighthouse Point',
    'Orchard Road',
    'Canal Walk',
    'Old Town',
    'Sunset Boulevard',
    'Garden Terrace',
    'Copper Bridge',
    'Museum Mile',
    'Tram Junction',
    'Skyline Plaza',
  ];

  static String blockName(int block) {
    final name = streetNames[block % streetNames.length];
    final round = block ~/ streetNames.length;
    return round == 0 ? name : '$name ${round + 1}';
  }

  @override
  ConsumerState<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends ConsumerState<LevelMapScreen> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final unlocked = ref.read(progressProvider).unlocked;
    final block = (unlocked - 1) ~/ LevelMapScreen.blockSize;
    // Open on the block being built.
    _scroll = ScrollController(
      initialScrollOffset: math.max(0, block * LevelMapScreen.blockExtent - 24),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(levelRepositoryProvider).count;
    final progress = ref.watch(progressProvider);
    final blocks =
        (count + LevelMapScreen.blockSize - 1) ~/ LevelMapScreen.blockSize;
    final builtBlocks = [
      for (var b = 0; b < blocks; b++)
        if (_blockComplete(progress, b, count)) b,
    ].length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('City map'),
        actions: const [CoinChip(), SizedBox(width: 12)],
      ),
      bottomNavigationBar: const MapBanner(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              '$builtBlocks of $blocks blocks built · '
              '${progress.totalStars} stars',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemExtent: LevelMapScreen.blockExtent,
              itemCount: blocks,
              padding: const EdgeInsets.only(bottom: 24),
              itemBuilder: (context, b) =>
                  _BlockCard(block: b, progress: progress, levelCount: count),
            ),
          ),
        ],
      ),
    );
  }

  static bool _blockComplete(Progress p, int block, int count) {
    final first = block * LevelMapScreen.blockSize + 1;
    final last = math.min(count, first + LevelMapScreen.blockSize - 1);
    for (var n = first; n <= last; n++) {
      if (p.starsFor(n) == 0) return false;
    }
    return true;
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    required this.progress,
    required this.levelCount,
  });

  final int block;
  final Progress progress;
  final int levelCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final first = block * LevelMapScreen.blockSize + 1;
    final levels = [
      for (
        var n = first;
        n < first + LevelMapScreen.blockSize && n <= levelCount;
        n++
      )
        n,
    ];
    final built = [
      for (var i = 0; i < LevelMapScreen.blockSize; i++)
        i < levels.length && progress.starsFor(levels[i]) > 0,
    ];
    final done = built.every((b) => b);
    final locked = first > progress.unlocked;
    final dark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      LevelMapScreen.blockName(block),
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Levels ${levels.first}–${levels.last}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (done) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: Palette.success,
                      size: 20,
                      semanticLabel: 'Block complete',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Opacity(
                  opacity: locked ? 0.45 : 1,
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: CityBlockPainter(
                        block: block,
                        built: built,
                        ground: dark
                            ? Palette.tileDarkEdge
                            : Palette.tileLightEdge,
                        ghost: scheme.outlineVariant,
                        colors: dark
                            ? Palette.vehiclesDark
                            : Palette.vehiclesLight,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Two rows of five keep every node a 44dp tap target.
              for (var row = 0; row < 2; row++)
                Padding(
                  padding: EdgeInsets.only(top: row == 0 ? 0 : 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final n in levels.skip(row * 5).take(5))
                        _LevelNode(
                          number: n,
                          stars: progress.starsFor(n),
                          unlocked: n <= progress.unlocked,
                          current: n == progress.unlocked,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.number,
    required this.stars,
    required this.unlocked,
    required this.current,
  });

  final int number;
  final int stars;
  final bool unlocked;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = current
        ? scheme.primary
        : stars > 0
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = current ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: unlocked,
      enabled: unlocked,
      label:
          'Level $number, ${unlocked ? (stars > 0 ? '$stars stars' : 'not played') : 'locked'}',
      excludeSemantics: true,
      child: InkResponse(
        key: Key('level-$number'),
        onTap: unlocked ? () => context.push(Routes.game(number)) : null,
        radius: 28,
        child: SizedBox(
          width: 48,
          height: 56,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: unlocked
                    ? FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Text(
                            '$number',
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : Icon(Icons.lock_rounded, size: 18, color: scheme.outline),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: i < stars ? Palette.star : scheme.outlineVariant,
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
