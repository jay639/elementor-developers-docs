import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/widgets/arrow_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Brief animated logo while start-up work finishes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 1500);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: SplashScreen.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) context.go(Routes.home);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // One continuous motion on the same background as the system splash:
    // the big logo grows in (0-30%), rests, then zooms out (70-100%).
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final appear = Curves.easeOutBack.transform(
              (t / 0.3).clamp(0.0, 1.0),
            );
            final leave = Curves.easeIn.transform(
              ((t - 0.7) / 0.3).clamp(0.0, 1.0),
            );
            return Opacity(
              opacity: (t / 0.2).clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.8 + 0.2 * appear,
                    child: ArrowLogo(size: 176, progress: leave),
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: 1 - leave,
                    child: Column(
                      children: [
                        Text(
                          'Arrow Escape',
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(
                          'Traffic Puzzle',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
