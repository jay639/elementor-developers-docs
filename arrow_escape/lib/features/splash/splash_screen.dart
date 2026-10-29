import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/core/widgets/arrow_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Brief animated logo while start-up work finishes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 1100);

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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => ArrowLogo(
                size: 128,
                progress: Curves.easeIn.transform(
                  (_controller.value * 1.4 - 0.4).clamp(0.0, 1.0),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Arrow Escape', style: theme.textTheme.headlineMedium),
            Text(
              'Traffic Puzzle',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
