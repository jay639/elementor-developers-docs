import 'package:arrow_escape/core/theme/palette.dart';
import 'package:arrow_escape/features/skins/skin_paint.dart';
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
    this.effect = SkinEffect.plain,
    this.tagline = '',
  });

  /// How arrows are drawn: plain, gradient, neon glow or gold.
  final SkinEffect effect;

  /// One line for the shop card.
  final String tagline;

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
  /// Free: plain ink lines, like a pen sketch. Everything else is an
  /// upgrade you can see: colour, then gradients, neon glow and gold.
  static const classic = VehicleSkin(
    id: 'classic',
    name: 'Ink',
    price: 0,
    tagline: 'Clean pen lines',
    light: [Color(0xFF1E2340)],
    dark: [Color(0xFFE9E9F2)],
  );

  static const all = <VehicleSkin>[
    classic,
    VehicleSkin(
      id: 'candy',
      name: 'Rainbow',
      price: 300,
      adUnlock: true,
      tagline: 'Every arrow its own colour',
      light: Palette.vehiclesLight,
      dark: Palette.vehiclesDark,
    ),
    VehicleSkin(
      id: 'ocean',
      name: 'Ocean',
      price: 500,
      effect: SkinEffect.gradient,
      tagline: 'Blues that fade like waves',
      light: [
        Color(0xFF0E7FC0),
        Color(0xFF1565C0),
        Color(0xFF00897B),
        Color(0xFF3949AB),
        Color(0xFF0277BD),
      ],
      dark: [
        Color(0xFF4FC3F7),
        Color(0xFF64B5F6),
        Color(0xFF4DD0B8),
        Color(0xFF8C9EFF),
        Color(0xFF40C4FF),
      ],
    ),
    VehicleSkin(
      id: 'forest',
      name: 'Forest',
      price: 500,
      adUnlock: true,
      effect: SkinEffect.gradient,
      tagline: 'Leafy greens and bark',
      light: [
        Color(0xFF2E7D32),
        Color(0xFF558B2F),
        Color(0xFF00796B),
        Color(0xFF8D6E00),
        Color(0xFF6D4C41),
      ],
      dark: [
        Color(0xFF81C784),
        Color(0xFFAED581),
        Color(0xFF4DB6AC),
        Color(0xFFFFD54F),
        Color(0xFFBCAAA4),
      ],
    ),
    VehicleSkin(
      id: 'sunset',
      name: 'Sunset',
      price: 800,
      effect: SkinEffect.gradient,
      tagline: 'Warm evening fades',
      light: [
        Color(0xFFE64A19),
        Color(0xFFF57C00),
        Color(0xFFD81B60),
        Color(0xFF8E24AA),
        Color(0xFFF9A825),
      ],
      dark: [
        Color(0xFFFF8A65),
        Color(0xFFFFB74D),
        Color(0xFFF06292),
        Color(0xFFCE93D8),
        Color(0xFFFFD54F),
      ],
    ),
    VehicleSkin(
      id: 'neon',
      name: 'Neon',
      price: 1500,
      effect: SkinEffect.glow,
      tagline: 'Glowing light tubes',
      light: [
        Color(0xFF00BFA5),
        Color(0xFFFF1F70),
        Color(0xFF7C4DFF),
        Color(0xFFFF9100),
        Color(0xFF00A8FF),
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
      effect: SkinEffect.metallic,
      tagline: 'Polished solid gold',
      light: [Color(0xFFC8901E)],
      dark: [Color(0xFFE0B341)],
    ),
  ];

  static VehicleSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => classic);
}
