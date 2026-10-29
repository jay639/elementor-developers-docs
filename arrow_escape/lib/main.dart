import 'package:arrow_escape/app/bootstrap.dart';
import 'package:arrow_escape/app/flavor.dart';

/// Default entry point (`flutter run`) is the dev flavor.
Future<void> main() => bootstrap(FlavorConfig.dev);
