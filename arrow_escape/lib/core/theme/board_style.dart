import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';

/// Everything the board painters need to know about colours and strokes.
@immutable
class BoardStyle {
  const BoardStyle({
    required this.tile,
    required this.tileEdge,
    required this.vehicles,
    required this.outline,
    required this.gate,
    required this.pathClear,
    required this.pathBlocked,
    required this.danger,
    required this.lightRed,
    required this.lightGreen,
    required this.ambulance,
    required this.ambulanceCross,
    required this.strokeFactor,
    required this.symbols,
  });

  /// [skinColors] come from the selected vehicle skin; accessibility modes
  /// override them.
  factory BoardStyle.of(
    ThemeData theme,
    AppSettings settings, {
    List<Color>? skinColors,
  }) {
    final dark = theme.brightness == Brightness.dark;
    final hc = settings.highContrast;
    final List<Color> vehicles;
    if (settings.colorblind) {
      vehicles = Palette.vehiclesColorblind;
    } else if (hc) {
      vehicles = Palette.vehiclesHighContrast;
    } else {
      vehicles =
          skinColors ?? (dark ? Palette.vehiclesDark : Palette.vehiclesLight);
    }
    return BoardStyle(
      tile: hc
          ? (dark ? const Color(0xFF111111) : const Color(0xFFF2F2F2))
          : (dark ? Palette.tileDark : Palette.tileLight),
      tileEdge: hc
          ? (dark ? Colors.white54 : Colors.black45)
          : (dark ? Palette.tileDarkEdge : Palette.tileLightEdge),
      vehicles: vehicles,
      outline: hc ? (dark ? Colors.white : Colors.black) : null,
      gate: dark ? const Color(0xFFCFC8F5) : const Color(0xFF6E62C9),
      pathClear: settings.colorblind
          ? const Color(0xFF0072B2)
          : Palette.success,
      pathBlocked: dark ? Colors.white38 : Colors.black26,
      danger: settings.colorblind ? const Color(0xFFD55E00) : Palette.danger,
      lightRed: settings.colorblind
          ? const Color(0xFFD55E00)
          : Palette.lightRed,
      lightGreen: settings.colorblind
          ? const Color(0xFF0072B2)
          : Palette.lightGreen,
      ambulance: Palette.ambulance,
      ambulanceCross: Palette.ambulanceCross,
      strokeFactor: settings.thickArrows ? 0.24 : 0.14,
      // Colorblind and high-contrast modes add shape cues to colour cues.
      symbols: settings.colorblind || hc,
    );
  }

  final Color tile;
  final Color tileEdge;
  final List<Color> vehicles;

  /// Dark outline drawn around vehicles in high-contrast mode.
  final Color? outline;
  final Color gate;
  final Color pathClear;
  final Color pathBlocked;
  final Color danger;
  final Color lightRed;
  final Color lightGreen;
  final Color ambulance;
  final Color ambulanceCross;

  /// Vehicle stroke width as a fraction of the cell size.
  final double strokeFactor;

  /// Draw symbols (stop bar, go circle, blocked cross) besides colours.
  final bool symbols;

  Color vehicleColor(int piece) => vehicles[piece % vehicles.length];

  @override
  bool operator ==(Object other) =>
      other is BoardStyle &&
      other.tile == tile &&
      other.tileEdge == tileEdge &&
      identical(other.vehicles, vehicles) &&
      other.outline == outline &&
      other.gate == gate &&
      other.pathClear == pathClear &&
      other.pathBlocked == pathBlocked &&
      other.danger == danger &&
      other.lightRed == lightRed &&
      other.lightGreen == lightGreen &&
      other.strokeFactor == strokeFactor &&
      other.symbols == symbols;

  @override
  int get hashCode => Object.hash(
    tile,
    tileEdge,
    vehicles,
    outline,
    gate,
    pathClear,
    pathBlocked,
    danger,
    lightRed,
    lightGreen,
    strokeFactor,
    symbols,
  );
}
