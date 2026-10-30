import 'package:arrow_escape/core/theme/palette.dart';
import 'package:flutter/material.dart';

/// A vehicle colour theme. Colorblind / high-contrast modes take precedence
/// over the skin so accessibility never depends on what you bought.
@immutable
class VehicleSkin {
  const VehicleSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.light,
    required this.dark,
    this.adUnlock = false,
  });

  final String id;
  final String name;

  /// Coin price; 0 = free.
  final int price;

  /// Can also be unlocked by watching a rewarded ad.
  final bool adUnlock;
  final List<Color> light;
  final List<Color> dark;

  List<Color> colors(Brightness b) => b == Brightness.dark ? dark : light;
}

abstract final class Skins {
  static const classic = VehicleSkin(
    id: 'classic',
    name: 'Pastel',
    price: 0,
    light: Palette.vehiclesLight,
    dark: Palette.vehiclesDark,
  );

  static const all = <VehicleSkin>[
    classic,
    VehicleSkin(
      id: 'candy',
      name: 'Candy',
      price: 300,
      adUnlock: true,
      light: [
        Color(0xFFFF9EC7),
        Color(0xFFFFC6A8),
        Color(0xFFB8E0FF),
        Color(0xFFC9B6FF),
        Color(0xFFFFE08A),
      ],
      dark: [
        Color(0xFFFF86B8),
        Color(0xFFFFB38D),
        Color(0xFF9CD2FF),
        Color(0xFFB39CFF),
        Color(0xFFFFD461),
      ],
    ),
    VehicleSkin(
      id: 'ocean',
      name: 'Ocean',
      price: 500,
      light: [
        Color(0xFF6EC6E8),
        Color(0xFF4FA3D1),
        Color(0xFF7FDCCB),
        Color(0xFF9FB8F2),
        Color(0xFF3E8FB0),
      ],
      dark: [
        Color(0xFF5BB8DE),
        Color(0xFF4E9ED0),
        Color(0xFF63D2BE),
        Color(0xFF8CA8F0),
        Color(0xFF52A6C8),
      ],
    ),
    VehicleSkin(
      id: 'forest',
      name: 'Forest',
      price: 500,
      adUnlock: true,
      light: [
        Color(0xFF8BC48A),
        Color(0xFFB5D88A),
        Color(0xFF6FA88E),
        Color(0xFFD9C27A),
        Color(0xFFA58D6F),
      ],
      dark: [
        Color(0xFF7DBA7C),
        Color(0xFFA7D073),
        Color(0xFF5FA584),
        Color(0xFFD6BC62),
        Color(0xFFB79E7E),
      ],
    ),
    VehicleSkin(
      id: 'sunset',
      name: 'Sunset',
      price: 800,
      light: [
        Color(0xFFFF8A65),
        Color(0xFFFFB74D),
        Color(0xFFF06292),
        Color(0xFFBA68C8),
        Color(0xFFFFD54F),
      ],
      dark: [
        Color(0xFFFF7B54),
        Color(0xFFFFAA33),
        Color(0xFFEE5487),
        Color(0xFFB05CC2),
        Color(0xFFFFCC33),
      ],
    ),
    VehicleSkin(
      id: 'mono',
      name: 'Ink',
      price: 400,
      light: [
        Color(0xFF5C5470),
        Color(0xFF7D7590),
        Color(0xFF9D96AE),
        Color(0xFF443C58),
      ],
      dark: [
        Color(0xFFD9D4E7),
        Color(0xFFBEB7D1),
        Color(0xFFA39BBB),
        Color(0xFFEDE9F7),
      ],
    ),
    VehicleSkin(
      id: 'neon',
      name: 'Neon',
      price: 1200,
      light: [
        Color(0xFF00C2A8),
        Color(0xFFFF3D7F),
        Color(0xFF7C4DFF),
        Color(0xFFFFB300),
        Color(0xFF00B0FF),
      ],
      dark: [
        Color(0xFF1DE9B6),
        Color(0xFFFF4081),
        Color(0xFFB388FF),
        Color(0xFFFFD740),
        Color(0xFF40C4FF),
      ],
    ),
    VehicleSkin(
      id: 'gold',
      name: 'Gold',
      price: 2500,
      light: [
        Color(0xFFE0B341),
        Color(0xFFCF9B2E),
        Color(0xFFF2CF6B),
        Color(0xFFB8862A),
      ],
      dark: [
        Color(0xFFF2C94C),
        Color(0xFFE0B341),
        Color(0xFFFFE08A),
        Color(0xFFD4A537),
      ],
    ),
  ];

  static VehicleSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => classic);
}
