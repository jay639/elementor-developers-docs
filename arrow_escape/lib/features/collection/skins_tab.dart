import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/ads/presentation/rewarded.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
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
        childAspectRatio: 0.7,
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
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SkinPreviewPainter(
                    skin.colors(theme.brightness),
                    theme.brightness == Brightness.dark
                        ? Palette.tileDark
                        : Palette.tileLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(skin.name, style: theme.textTheme.titleMedium),
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
                label: const Text('Free with video'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Three little arrows in the skin's colours.
class _SkinPreviewPainter extends CustomPainter {
  _SkinPreviewPainter(this.colors, this.tile);

  final List<Color> colors;
  final Color tile;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      Paint()..color = tile,
    );
    final s = size.shortestSide;
    for (var i = 0; i < 3; i++) {
      final c = colors[i % colors.length];
      final y = size.height * (0.25 + i * 0.25);
      final x0 = size.width * 0.2 + (i.isOdd ? s * 0.1 : 0);
      final x1 = size.width * 0.68 + (i.isOdd ? s * 0.1 : 0);
      canvas.drawLine(
        Offset(x0, y),
        Offset(x1, y),
        Paint()
          ..color = c
          ..strokeWidth = s * 0.11
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x1 + s * 0.12, y)
          ..lineTo(x1, y - s * 0.09)
          ..lineTo(x1, y + s * 0.09)
          ..close(),
        Paint()..color = c,
      );
    }
  }

  @override
  bool shouldRepaint(_SkinPreviewPainter old) =>
      old.colors != colors || old.tile != tile;
}
