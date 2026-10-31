import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/ads/presentation/rewarded.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/skins/skin_paint.dart';
import 'package:arrow_escape/features/skins/skins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arrow colour themes, bought with coins or a video.
class SkinsTab extends ConsumerWidget {
  const SkinsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveProvider);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 330,
      ),
      itemCount: Skins.all.length,
      itemBuilder: (context, i) {
        final skin = Skins.all[i];
        return _SkinCard(
          skin: skin,
          owned: save.owns(skin.id),
          selected: save.selectedSkin == skin.id,
          affordable: save.coins >= skin.price,
        );
      },
    );
  }
}

class _SkinCard extends ConsumerWidget {
  const _SkinCard({
    required this.skin,
    required this.owned,
    required this.selected,
    required this.affordable,
  });

  final VehicleSkin skin;
  final bool owned;
  final bool selected;
  final bool affordable;

  Future<void> _unlockWithAd(BuildContext context, WidgetRef ref) async {
    if (await watchRewarded(context, ref, RewardKind.unlockSkin)) {
      ref.read(saveProvider.notifier)
        ..grantSkin(skin.id)
        ..selectSkin(skin.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final save = ref.read(saveProvider.notifier);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? scheme.primary : Colors.transparent,
          width: 3,
        ),
      ),
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: ExcludeSemantics(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SkinPreviewPainter(
                    skin.colors(theme.brightness),
                    theme.brightness == Brightness.dark
                        ? const Color(0xFF0B0B10)
                        : Palette.tileLight,
                    skin.effect,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(skin.name, style: theme.textTheme.titleMedium),
            Text(
              skin.tagline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: switch ((owned, selected)) {
                (true, true) => FilledButton.tonalIcon(
                  key: Key('skin-${skin.id}-selected'),
                  onPressed: null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('In use'),
                ),
                (true, false) => FilledButton.tonal(
                  key: Key('skin-${skin.id}-select'),
                  onPressed: () => save.selectSkin(skin.id),
                  child: const Text('Use'),
                ),
                _ => FilledButton.icon(
                  key: Key('skin-${skin.id}-buy'),
                  onPressed: affordable
                      ? () => save.buySkin(skin.id, skin.price)
                      : null,
                  icon: const Icon(Icons.monetization_on_rounded),
                  label: Text('${skin.price}'),
                ),
              },
            ),
            if (!owned && skin.adUnlock)
              TextButton.icon(
                key: Key('skin-${skin.id}-ad'),
                onPressed: () => _unlockWithAd(context, ref),
                icon: const Icon(Icons.smart_display_rounded, size: 18),
                label: const Text('Free'),
              ),
          ],
        ),
      ),
    );
  }
}

/// A few bent arrows drawn exactly as the board draws this skin.
class _SkinPreviewPainter extends CustomPainter {
  _SkinPreviewPainter(this.colors, this.tile, this.effect);

  final List<Color> colors;
  final Color tile;
  final SkinEffect effect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      Paint()..color = tile,
    );
    final u = size.shortestSide / 6;
    final o = Offset((size.width - u * 6) / 2, (size.height - u * 6) / 2);
    Offset p(double x, double y) => o + Offset(x * u, y * u);
    final arrows = <List<Offset>>[
      [p(1, 1), p(4, 1), p(4, 2.5)],
      [p(1, 2.5), p(1, 4), p(3, 4), p(3, 2.5)],
      [p(5, 5), p(2, 5)],
      [p(5, 1.2), p(5, 4)],
    ];
    final stroke = u * 0.22;
    for (var i = 0; i < arrows.length; i++) {
      final pts = arrows[i];
      final body = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final q in pts.skip(1)) {
        body.lineTo(q.dx, q.dy);
      }
      final end = pts.last;
      final dir = end - pts[pts.length - 2];
      final t = dir / dir.distance;
      final n = Offset(-t.dy, t.dx);
      final len = stroke * 3.2;
      final tip = end + t * len;
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(end.dx + n.dx * len * 0.52, end.dy + n.dy * len * 0.52)
        ..lineTo(end.dx - n.dx * len * 0.52, end.dy - n.dy * len * 0.52)
        ..close();
      paintArrow(
        canvas,
        body: body,
        head: head,
        tail: pts.first,
        tip: tip,
        color: colors[i % colors.length],
        stroke: stroke,
        effect: effect,
      );
    }
  }

  @override
  bool shouldRepaint(_SkinPreviewPainter old) =>
      old.colors != colors || old.tile != tile || old.effect != effect;
}
