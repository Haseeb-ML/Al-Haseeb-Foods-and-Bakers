import 'package:flutter/material.dart';

//-------------------- GLOBAL BACKGROUND THEME CONTROLLER --------------------
// null hone par app apne default Dark/Light colors use karti hai.
// Kisi preset ko select karne par uske apne bg/card/border colors lagte hain.
final ValueNotifier<Map<String, dynamic>?> backgroundThemeController =
    ValueNotifier<Map<String, dynamic>?>(null);

//-------------------- BACKGROUND THEME PRESETS --------------------
class AppBackgroundPresets {
  // isDarkStyle = true matlab text white/light hona chahiye (dark palette),
  // false matlab text dark hona chahiye (light palette).
  static const List<Map<String, dynamic>> presets = [
    //---------- LIGHT PALETTES ----------
    {
      'name': 'Alabaster Pearl',
      'bg': Color(0xFFF7F7F5),
      'card': Color(0xFFFFFFFF),
      'border': Color(0xFFE5E5E0),
      'isDarkStyle': false,
    },
    {
      'name': 'Nordic Frost',
      'bg': Color(0xFFF1F4F8),
      'card': Color(0xFFFFFFFF),
      'border': Color(0xFFDCE3EA),
      'isDarkStyle': false,
    },
    {
      'name': 'Sakura Blossom',
      'bg': Color(0xFFFDF2F5),
      'card': Color(0xFFFFFFFF),
      'border': Color(0xFFF5D9E0),
      'isDarkStyle': false,
    },
    {
      'name': 'Ivory Silk',
      'bg': Color(0xFFFAF6F0),
      'card': Color(0xFFFFFFFF),
      'border': Color(0xFFEDE4D8),
      'isDarkStyle': false,
    },
    {
      'name': 'Pearl Mist',
      'bg': Color(0xFFF0F2F5),
      'card': Color(0xFFFFFFFF),
      'border': Color(0xFFDDE1E6),
      'isDarkStyle': false,
    },

    //---------- DARK PALETTES ----------
    {
      'name': 'Cyber Sapphire',
      'bg': Color(0xFF0B1220),
      'card': Color(0xFF16213A),
      'border': Color(0xFF253358),
      'isDarkStyle': true,
    },
    {
      'name': 'Royal Navy',
      'bg': Color(0xFF0A1128),
      'card': Color(0xFF131B3A),
      'border': Color(0xFF1F2B54),
      'isDarkStyle': true,
    },
    {
      'name': 'Amethyst Eclipse',
      'bg': Color(0xFF150F23),
      'card': Color(0xFF241A38),
      'border': Color(0xFF3A2B57),
      'isDarkStyle': true,
    },
    {
      'name': 'Burgundy Wine',
      'bg': Color(0xFF1A0E12),
      'card': Color(0xFF2A161C),
      'border': Color(0xFF40232B),
      'isDarkStyle': true,
    },
    {
      'name': 'Arctic Charcoal',
      'bg': Color(0xFF14171C),
      'card': Color(0xFF1F242B),
      'border': Color(0xFF2E343C),
      'isDarkStyle': true,
    },
    {
      'name': 'Graphite Steel',
      'bg': Color(0xFF101317),
      'card': Color(0xFF1A1E24),
      'border': Color(0xFF282E36),
      'isDarkStyle': true,
    },
    {
      'name': 'Deep Pine',
      'bg': Color(0xFF0D1712),
      'card': Color(0xFF172621),
      'border': Color(0xFF26382F),
      'isDarkStyle': true,
    },
    {
      'name': 'Emerald Shadow',
      'bg': Color(0xFF08150F),
      'card': Color(0xFF12241B),
      'border': Color(0xFF1E3A2A),
      'isDarkStyle': true,
    },
    {
      'name': 'Obsidian Eclipse',
      'bg': Color(0xFF0A0A0C),
      'card': Color(0xFF17171A),
      'border': Color(0xFF26262B),
      'isDarkStyle': true,
    },
    {
      'name': 'Dracula Velvet',
      'bg': Color(0xFF16121F),
      'card': Color(0xFF241D33),
      'border': Color(0xFF382C4E),
      'isDarkStyle': true,
    },
    {
      'name': 'Mocha Desert',
      'bg': Color(0xFF1C140F),
      'card': Color(0xFF2B2019),
      'border': Color(0xFF40332A),
      'isDarkStyle': true,
    },
  ];
}
