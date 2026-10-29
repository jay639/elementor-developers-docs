import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Flavor { dev, prod }

/// Build-time configuration. Values that differ per environment (ad unit
/// IDs, API keys) are injected with `--dart-define` and never hardcoded.
class FlavorConfig {
  const FlavorConfig({required this.flavor, required this.appName});

  final Flavor flavor;
  final String appName;

  bool get isDev => flavor == Flavor.dev;

  static const dev = FlavorConfig(
    flavor: Flavor.dev,
    appName: 'Arrow Escape Dev',
  );
  static const prod = FlavorConfig(
    flavor: Flavor.prod,
    appName: 'Arrow Escape',
  );
}

/// Overridden in `bootstrap` with the flavor being run.
final flavorProvider = Provider<FlavorConfig>((ref) => FlavorConfig.dev);
