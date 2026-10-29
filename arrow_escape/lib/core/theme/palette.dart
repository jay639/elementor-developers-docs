import 'package:flutter/material.dart';

/// Soft pastel brand colours plus accessible alternatives.
abstract final class Palette {
  // Brand
  static const primary = Color(0xFF7C6CF2); // soft violet
  static const secondary = Color(0xFFFF9F8E); // peach
  static const tertiary = Color(0xFF5CC9B0); // mint

  // Light surfaces
  static const cream = Color(0xFFFFF8F1);
  static const tileLight = Color(0xFFF1EAF9);
  static const tileLightEdge = Color(0xFFE2D8F0);

  // Dark surfaces
  static const night = Color(0xFF17161D);
  static const tileDark = Color(0xFF2A2833);
  static const tileDarkEdge = Color(0xFF3A3746);

  static const heart = Color(0xFFFF6F7D);
  static const star = Color(0xFFFFC94D);
  static const success = Color(0xFF4CC38A);
  static const danger = Color(0xFFF0616D);

  static const lightRed = Color(0xFFF0616D);
  static const lightGreen = Color(0xFF4CC38A);

  /// Pastel vehicle colours (light mode).
  static const vehiclesLight = [
    Color(0xFFF4978E),
    Color(0xFF8EC5FC),
    Color(0xFF84DCC6),
    Color(0xFFB9A6F2),
    Color(0xFFF9C96E),
    Color(0xFFF5A3C7),
    Color(0xFF9AD0EC),
    Color(0xFFA8D88E),
  ];

  /// Slightly deeper versions that read well on dark tiles.
  static const vehiclesDark = [
    Color(0xFFFF8F84),
    Color(0xFF7DB8F7),
    Color(0xFF6FD3BA),
    Color(0xFFA997F0),
    Color(0xFFF7C25A),
    Color(0xFFF291BD),
    Color(0xFF86C6E8),
    Color(0xFF95CF78),
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
