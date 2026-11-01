import 'package:flutter/material.dart';

/// Vivid, candy-like brand colours plus accessible alternatives.
abstract final class Palette {
  // Brand
  static const primary = Color(0xFF6C4CF5); // electric violet
  static const primaryDeep = Color(0xFF4B2FD1);
  static const secondary = Color(0xFFFF6B5B); // coral
  static const tertiary = Color(0xFF14C3A2); // teal
  static const pink = Color(0xFFFF5FA2);
  static const sky = Color(0xFF3FA9FF);
  static const sun = Color(0xFFFFB627);

  // Light surfaces: a soft lilac-to-white wash behind white cards.
  static const cream = Color(0xFFF8F6FF);
  static const washTop = Color(0xFFEFEAFF);
  static const washBottom = Color(0xFFFDFCFF);
  static const tileLight = Color(0xFFF2EEFC);
  static const tileLightEdge = Color(0xFFCFC5EE);

  /// Board background: barely tinted so the arrows and roads stand out.
  static const boardLight = Color(0xFFFAF9FE);
  static const boardDark = Color(0xFF0B0B0E);

  // Dark surfaces: true black (OLED friendly) with charcoal cards.
  static const night = Color(0xFF000000);
  static const nightTop = Color(0xFF000000);
  static const nightBottom = Color(0xFF000000);
  static const tileDark = Color(0xFF17171C);
  static const tileDarkEdge = Color(0xFF34343F);

  /// Hero gradients for big buttons and headers.
  static const heroGradient = [Color(0xFF7B5CFF), Color(0xFFB04DFF)];
  static const playGradient = [Color(0xFFEE5A1E), Color(0xFFDB1F5E)];

  static const heart = Color(0xFFFF6F7D);
  static const star = Color(0xFFFFC02E);
  static const success = Color(0xFF4CC38A);
  static const danger = Color(0xFFF0616D);

  static const lightRed = Color(0xFFF0616D);
  static const lightGreen = Color(0xFF4CC38A);

  /// Saturated arrow colours: thin lines need strong colour to read.
  static const vehiclesLight = [
    Color(0xFFF2425B),
    Color(0xFF2F7BF5),
    Color(0xFF0FAF86),
    Color(0xFF7A4DF0),
    Color(0xFFF08A00),
    Color(0xFFE23D93),
    Color(0xFF0597B8),
    Color(0xFF4BA82E),
  ];

  /// Brighter versions that read well on dark tiles.
  static const vehiclesDark = [
    Color(0xFFFF6B7E),
    Color(0xFF6AA6FF),
    Color(0xFF3FE0B0),
    Color(0xFFA98BFF),
    Color(0xFFFFB13D),
    Color(0xFFFF7CC0),
    Color(0xFF4FD3F0),
    Color(0xFF8BE06A),
  ];

  /// Okabe–Ito palette: distinguishable with the common colour-vision
  /// deficiencies.
  static const vehiclesColorblind = [
    Color(0xFFE69F00),
    Color(0xFF56B4E9),
    Color(0xFF009E73),
    Color(0xFFF0E442),
    Color(0xFF0072B2),
    Color(0xFFD55E00),
    Color(0xFFCC79A7),
  ];

  /// Saturated colours for high-contrast mode.
  static const vehiclesHighContrast = [
    Color(0xFFD7263D),
    Color(0xFF1B65D8),
    Color(0xFF0B8A55),
    Color(0xFF7B2CBF),
    Color(0xFFE07A00),
    Color(0xFFC2185B),
  ];

  static const ambulance = Color(0xFFFFFFFF);
  static const ambulanceCross = Color(0xFFE53950);
}
