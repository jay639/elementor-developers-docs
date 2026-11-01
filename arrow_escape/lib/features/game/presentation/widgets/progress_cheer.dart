import 'dart:async';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:flutter/material.dart';

/// A short, non-blocking cheer when the player gets through a big board:
/// "Halfway there!" at 50% and, on Hard / Super Hard levels, "Almost
/// there!" at 90%. Each shows once per attempt (a restart re-arms them).
class ProgressCheer extends StatefulWidget {
  const ProgressCheer({
    super.key,
    required this.total,
    required this.remaining,
    required this.tier,
    this.reduceMotion = false,
  });

  final int total;
  final int remaining;
  final LevelTier tier;
  final bool reduceMotion;

  /// Boards smaller than this are over too quickly for a cheer.
  static const minArrows = 20;

  /// The cheer due for this progress, or null.
  static Cheer? due({
    required int total,
    required int remaining,
    required LevelTier tier,
    required Set<Cheer> shown,
  }) {
    if (total < minArrows || remaining == 0) return null;
    final cleared = total - remaining;
    if (tier != LevelTier.normal &&
        cleared >= total * 0.9 &&
        !shown.contains(Cheer.almost)) {
      return Cheer.almost;
    }
    if (cleared >= total / 2 && !shown.contains(Cheer.halfway)) {
      return Cheer.halfway;
    }
    return null;
  }

  @override
  State<ProgressCheer> createState() => _ProgressCheerState();
}

enum Cheer {
  halfway('😄', 'Halfway there!'),
  almost('🤩', 'Almost there!');

  const Cheer(this.emoji, this.text);

  final String emoji;
  final String text;
}

class _ProgressCheerState extends State<ProgressCheer> {
  final _shown = <Cheer>{};
  Cheer? _current;
  Timer? _hide;

  @override
  void didUpdateWidget(ProgressCheer old) {
    super.didUpdateWidget(old);
    // Restart: everything is back on the board.
    if (widget.remaining == widget.total) {
      _shown.clear();
      return;
    }
    if (widget.remaining >= old.remaining) return;
    final cheer = ProgressCheer.due(
      total: widget.total,
      remaining: widget.remaining,
      tier: widget.tier,
      shown: _shown,
    );
    if (cheer == null) return;
    // Passing 90% marks 50% as done too, so they never stack.
    _shown.add(cheer);
    if (cheer == Cheer.almost) _shown.add(Cheer.halfway);
    setState(() => _current = cheer);
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _current = null);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cheer = _current;
    final theme = Theme.of(context);
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: widget.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        ),
        child: cheer == null
            ? const SizedBox.shrink()
            : Semantics(
                key: ValueKey(cheer),
                liveRegion: true,
                label: cheer.text,
                child: ExcludeSemantics(
                  child: Container(
                    key: const Key('progress-cheer'),
                    padding: const EdgeInsets.fromLTRB(14, 8, 20, 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cheer.emoji, style: const TextStyle(fontSize: 34)),
                        const SizedBox(width: 10),
                        Text(
                          cheer.text,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
