import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/core/widgets/ui.dart';
import 'package:flutter/material.dart';

/// One stop of a [ProductTour]: the widget to spotlight and what it does.
class TourStep {
  const TourStep({
    required this.target,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final GlobalKey target;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

/// Coach marks: dims the screen, cuts a spotlight around each step's
/// target and explains it in a card. [onDone] gets whether the player
/// finished (true) or skipped (false).
class ProductTour extends StatefulWidget {
  const ProductTour({super.key, required this.steps, required this.onDone});

  final List<TourStep> steps;
  final ValueChanged<bool> onDone;

  @override
  State<ProductTour> createState() => _ProductTourState();
}

class _ProductTourState extends State<ProductTour> {
  int _step = 0;
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final target = widget.steps[_step].target.currentContext
        ?.findRenderObject();
    final self = context.findRenderObject();
    if (target is! RenderBox || self is! RenderBox || !target.hasSize) {
      // Target not laid out yet: try again next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
      return;
    }
    final topLeft = target.localToGlobal(Offset.zero, ancestor: self);
    setState(() => _hole = (topLeft & target.size).inflate(6));
  }

  void _next() {
    if (_step == widget.steps.length - 1) {
      widget.onDone(true);
      return;
    }
    setState(() {
      _step++;
      _hole = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_step];
    final hole = _hole;
    final size = MediaQuery.sizeOf(context);
    final last = _step == widget.steps.length - 1;
    // Card below the spotlight, or above it when the target is low.
    final below = hole == null || hole.center.dy < size.height * 0.55;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Stack(
        key: const Key('product-tour'),
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(painter: _ScrimPainter(hole)),
            ),
          ),
          if (hole != null)
            Positioned(
              left: 16,
              right: 16,
              top: below ? hole.bottom + 14 : null,
              bottom: below ? null : size.height - hole.top + 14,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_step),
                tween: Tween(begin: 0.9, end: 1),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: SoftCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBubble(
                            icon: step.icon,
                            colors: [
                              Color.lerp(step.color, Colors.white, 0.3)!,
                              step.color,
                            ],
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.body,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 0; i < widget.steps.length; i++)
                            Container(
                              width: i == _step ? 14 : 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i == _step
                                    ? Palette.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                              ),
                            ),
                          const Spacer(),
                          if (!last)
                            TextButton(
                              key: const Key('tour-skip'),
                              onPressed: () => widget.onDone(false),
                              child: const Text('Skip'),
                            ),
                          const SizedBox(width: 4),
                          FilledButton(
                            key: const Key('tour-next'),
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(96, 48),
                            ),
                            child: Text(last ? 'Got it' : 'Next'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()..addRect(Offset.zero & size);
    final h = hole;
    if (h != null) {
      scrim
        ..addRRect(RRect.fromRectAndRadius(h, const Radius.circular(28)))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(scrim, Paint()..color = const Color(0xB3000000));
    if (h != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(h, const Radius.circular(28)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}
