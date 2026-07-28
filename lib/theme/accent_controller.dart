import 'package:flutter/material.dart';

//-------------------- GLOBAL ACCENT COLOR CONTROLLER --------------------
// App mein kahin se bhi accent color change kar sakte hain:
// accentController.value = AppAccentPresets.presets[2]['color'];
final ValueNotifier<Color> accentController = ValueNotifier<Color>(
  const Color(0xFFD4AF37), // default: Royal Gold
);

//-------------------- PREMIUM ACCENT COLOR PRESETS --------------------
class AppAccentPresets {
  static const List<Map<String, dynamic>> presets = [
    {'name': 'Royal Gold', 'color': Color(0xFFD4AF37)},
    {'name': 'Sapphire Blue', 'color': Color(0xFF1E3A8A)},
    {'name': 'Cobalt Steel', 'color': Color(0xFF2563EB)},
    {'name': 'Emerald Noir', 'color': Color(0xFF065F46)},
    {'name': 'Teal Jade', 'color': Color(0xFF0F766E)},
    {'name': 'Ruby Velvet', 'color': Color(0xFF9B1C31)},
    {'name': 'Crimson Wine', 'color': Color(0xFF7F1D1D)},
    {'name': 'Amethyst Royale', 'color': Color(0xFF6B21A8)},
    {'name': 'Mauve Orchid', 'color': Color(0xFF9D6B9E)},
    {'name': 'Rose Gold', 'color': Color(0xFFB76E79)},
    {'name': 'Champagne', 'color': Color(0xFFC9A66B)},
    {'name': 'Bronze Copper', 'color': Color(0xFFB87333)},
    {'name': 'Platinum Silver', 'color': Color(0xFF94A3B8)},
    {'name': 'Midnight Onyx', 'color': Color(0xFF334155)},
  ];
}
