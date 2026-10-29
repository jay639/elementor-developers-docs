import 'package:arrow_escape/app/flavor.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/core/theme/app_theme.dart';
import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArrowEscapeApp extends ConsumerWidget {
  const ArrowEscapeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final flavor = ref.watch(flavorProvider);
    return MaterialApp.router(
      title: flavor.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(
        Brightness.light,
        highContrast: settings.highContrast,
      ),
      darkTheme: AppTheme.build(
        Brightness.dark,
        highContrast: settings.highContrast,
      ),
      themeMode: settings.themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
