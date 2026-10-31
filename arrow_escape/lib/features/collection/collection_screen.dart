import 'package:arrow_escape/core/widgets/coin_chip.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:arrow_escape/features/collection/pictures_tab.dart';
import 'package:arrow_escape/features/collection/skins_tab.dart';
import 'package:flutter/material.dart';

/// Everything the player collects: picture puzzles (opened with stars)
/// and arrow skins (bought with coins).
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Backdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Collection'),
            actions: const [CoinChip(), SizedBox(width: 12)],
          ),
          // The tabs stay put; only the content below them scrolls.
          body: const Column(
            children: [
              _Tabs(),
              Expanded(
                child: ClipRect(
                  child: TabBarView(children: [PicturesTab(), SkinsTab()]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: dark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF7B5CFF), Color(0xFFB04DFF)],
            ),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: scheme.onSurfaceVariant,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          tabs: const [
            Tab(key: Key('tab-pictures'), icon: null, text: 'Wonders'),
            Tab(key: Key('tab-skins'), text: 'Arrow skins'),
          ],
        ),
      ),
    );
  }
}
