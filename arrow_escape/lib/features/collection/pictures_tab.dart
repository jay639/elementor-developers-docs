import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/puzzles/puzzle_progress.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Outlines are computed once; they never change.
final _masks = <String, ShapeMask>{};
ShapeMask _maskOf(PuzzleShape s) => _masks[s.id] ??= s.mask;

/// Colours per picture, so the gallery looks like a sticker book.
const _pictureColors = <List<Color>>[
  [Color(0xFF6EC6FF), Color(0xFF3F7BFF)],
  [Color(0xFFFFA8D9), Color(0xFFB04DFF)],
  [Color(0xFFFFE08A), Color(0xFFFF9A3D)],
  [Color(0xFFFFD25E), Color(0xFFFF6B5B)],
  [Color(0xFF7CE3B5), Color(0xFF0FAF86)],
  [Color(0xFFFF9EC7), Color(0xFFE23D93)],
  [Color(0xFFB9E3FF), Color(0xFF5AA8F0)],
  [Color(0xFFFFB86B), Color(0xFFF2425B)],
  [Color(0xFFFFE27A), Color(0xFFE0A100)],
  [Color(0xFF8FF0E0), Color(0xFF0597B8)],
  [Color(0xFFD7F2FF), Color(0xFF6AA6FF)],
  [Color(0xFFFFF07A), Color(0xFFF08A00)],
  [Color(0xFFC9B6FF), Color(0xFF7A4DF0)],
  [Color(0xFFFFC48A), Color(0xFFB0602E)],
  [Color(0xFFB6F08A), Color(0xFF4BA82E)],
  [Color(0xFFB98BFF), Color(0xFF2B1A6E)],
];

List<Color> pictureColors(PuzzleShape s) =>
    _pictureColors[ShapePuzzles.all.indexOf(s) % _pictureColors.length];

/// Picture puzzles: each opens at a star count and has three layers that
/// get harder. Cleared layers colour the picture in.
class PicturesTab extends ConsumerWidget {
  const PicturesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(saveProvider.select((s) => s.progress));
    final next = nextLockedPuzzle(progress);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          sliver: SliverToBoxAdapter(
            child: _PointsHeader(points: progress.points, next: next),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemCount: ShapePuzzles.all.length,
            itemBuilder: (context, i) {
              final shape = ShapePuzzles.all[i];
              return _PictureCard(
                shape: shape,
                unlocked: progress.puzzleUnlocked(shape),
                layersDone: progress.layersDone(shape),
                stars: progress.puzzleStarsOf(shape),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PointsHeader extends StatelessWidget {
  const _PointsHeader({required this.points, required this.next});

  final int points;
  final PuzzleShape? next;

  @override
  Widget build(BuildContext context) {
    final next = this.next;
    final prevGoal = next == null
        ? 0
        : ShapePuzzles.all
              .where((s) => s.starsToUnlock < next.starsToUnlock)
              .fold<int>(
                0,
                (a, s) => s.starsToUnlock > a ? s.starsToUnlock : a,
              );
    final share = next == null
        ? 1.0
        : ((points - prevGoal) / (next.starsToUnlock - prevGoal)).clamp(
            0.0,
            1.0,
          );
    const white = TextStyle(color: Colors.white);
    return Semantics(
      container: true,
      label: next == null
          ? '$points stars. Every picture is open.'
          : '$points stars. ${next.name} opens at ${next.starsToUnlock}.',
      excludeSemantics: true,
      child: SoftCard(
        gradient: const LinearGradient(colors: Palette.heroGradient),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Palette.star, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$points stars',
                    style: white.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next == null
                        ? 'Every picture is open. Master their layers!'
                        : '${next.name} opens at ${next.starsToUnlock} stars',
                    style: white.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Palette.star),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PictureCard extends StatelessWidget {
  const _PictureCard({
    required this.shape,
    required this.unlocked,
    required this.layersDone,
    required this.stars,
  });

  final PuzzleShape shape;
  final bool unlocked;
  final int layersDone;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = pictureColors(shape);
    final complete = layersDone == PuzzleShape.layerCount;
    return Semantics(
      button: unlocked,
      label: unlocked
          ? '${shape.name}, $layersDone of ${PuzzleShape.layerCount} layers'
          : '${shape.name}, locked, opens at ${shape.starsToUnlock} stars',
      excludeSemantics: true,
      child: SoftCard(
        key: Key('picture-${shape.id}'),
        padding: const EdgeInsets.all(10),
        onTap: unlocked ? () => _openLayers(context, shape) : null,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PicturePainter(
                        mask: _maskOf(shape),
                        colors: colors,
                        filled: unlocked
                            ? layersDone / PuzzleShape.layerCount
                            : 0,
                        locked: !unlocked,
                        dark: theme.brightness == Brightness.dark,
                      ),
                    ),
                  ),
                  if (!unlocked)
                    const Center(
                      child: IconBubble(
                        icon: Icons.lock_rounded,
                        colors: [Color(0xFF9C95B8), Color(0xFF6B6385)],
                        size: 40,
                      ),
                    ),
                  if (complete)
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: Palette.star,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              shape.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            if (unlocked)
              _LayerPips(done: layersDone)
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Palette.star, size: 18),
                  const SizedBox(width: 2),
                  Text(
                    '${shape.starsToUnlock}',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LayerPips extends StatelessWidget {
  const _LayerPips({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < PuzzleShape.layerCount; i++)
        Container(
          width: 22,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: i < done
                ? Palette.tertiary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
    ],
  );
}

String layerLabel(int layer) => switch (layer) {
  1 => 'Layer 1 · Hard',
  2 => 'Layer 2 · Harder',
  _ => 'Layer 3 · Expert',
};

Future<void> _openLayers(BuildContext context, PuzzleShape shape) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _LayersSheet(shape: shape),
    );

class _LayersSheet extends ConsumerWidget {
  const _LayersSheet({required this.shape});

  final PuzzleShape shape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(saveProvider.select((s) => s.progress));
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: const Size(160, 120),
                painter: PicturePainter(
                  mask: _maskOf(shape),
                  colors: pictureColors(shape),
                  filled: progress.layersDone(shape) / PuzzleShape.layerCount,
                  locked: false,
                  dark: theme.brightness == Brightness.dark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(shape.name, style: theme.textTheme.headlineSmall),
            Text(
              'Each layer is bigger and harder. Clear one to open the next.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (var layer = 1; layer <= PuzzleShape.layerCount; layer++) ...[
              _LayerRow(
                shape: shape,
                layer: layer,
                open: progress.layerOpen(shape, layer),
                stars: progress.puzzleStarsFor(
                  ShapePuzzles.key(shape.id, layer),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.shape,
    required this.layer,
    required this.open,
    required this.stars,
  });

  final PuzzleShape shape;
  final int layer;
  final bool open;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = switch (layer) {
      1 => const [Color(0xFF7CC8FF), Palette.sky],
      2 => const [Color(0xFFFFB86B), Color(0xFFFF6B5B)],
      _ => const [Color(0xFFFF7CC0), Color(0xFF8B2BE2)],
    };
    return SoftCard(
      key: Key('layer-${shape.id}-$layer'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      onTap: open
          ? () {
              Navigator.of(context).pop();
              context.push(Routes.puzzleGame(shape.id, layer));
            }
          : null,
      child: Row(
        children: [
          IconBubble(
            icon: open ? Icons.layers_rounded : Icons.lock_rounded,
            colors: open
                ? colors
                : const [Color(0xFFB8B2CC), Color(0xFF8A839F)],
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(layerLabel(layer), style: theme.textTheme.titleMedium),
                Text(
                  open
                      ? '+${20 + 20 * layer}–${50 + 20 * layer} coins'
                      : 'Clear layer ${layer - 1} first',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          for (var i = 0; i < 3; i++)
            Icon(
              Icons.star_rounded,
              size: 22,
              color: i < stars
                  ? Palette.star
                  : theme.colorScheme.outlineVariant,
            ),
          const SizedBox(width: 4),
          Icon(
            open ? Icons.play_circle_fill_rounded : Icons.lock_rounded,
            color: open ? Palette.primary : theme.disabledColor,
            size: 32,
          ),
        ],
      ),
    );
  }
}

/// Draws a picture outline as a mosaic of rounded tiles. [filled] (0..1)
/// colours it in from the bottom, one band per cleared layer.
class PicturePainter extends CustomPainter {
  PicturePainter({
    required this.mask,
    required this.colors,
    required this.filled,
    required this.locked,
    required this.dark,
  });

  final ShapeMask mask;
  final List<Color> colors;
  final double filled;
  final bool locked;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    // Downsample to a chunky mosaic that reads at card size.
    const rows = 16;
    final cols = (rows * mask.aspect).round().clamp(6, 22);
    final small = mask.resample(cols, rows);
    final cell = (size.width / small.width).clamp(
      0.0,
      size.height / small.height,
    );
    final ox = (size.width - cell * small.width) / 2;
    final oy = (size.height - cell * small.height) / 2;
    final empty = locked
        ? (dark ? const Color(0xFF3A3452) : const Color(0xFFE3DFEE))
        : colors.first.withValues(alpha: dark ? 0.25 : 0.3);
    final fillFrom = small.height * (1 - filled);
    for (var y = 0; y < small.height; y++) {
      for (var x = 0; x < small.width; x++) {
        if (!small.cells[y * small.width + x]) continue;
        final t = small.height <= 1 ? 0.0 : y / (small.height - 1);
        final color = !locked && y >= fillFrom
            ? Color.lerp(colors.first, colors.last, t)!
            : empty;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              ox + x * cell + cell * 0.08,
              oy + y * cell + cell * 0.08,
              cell * 0.84,
              cell * 0.84,
            ),
            Radius.circular(cell * 0.25),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PicturePainter old) =>
      old.mask != mask ||
      old.filled != filled ||
      old.locked != locked ||
      old.dark != dark;
}
