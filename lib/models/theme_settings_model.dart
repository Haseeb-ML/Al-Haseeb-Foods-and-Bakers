import 'package:flutter/material.dart';

class ThemeSettingsModel {
  final bool isDarkMode;
  final int selectedColorIndex;
  final int selectedBackgroundIndex;

  ThemeSettingsModel({
    required this.isDarkMode,
    required this.selectedColorIndex,
    required this.selectedBackgroundIndex,
  });

  //-------------------- TO JSON --------------------
  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'selectedColorIndex': selectedColorIndex,
      'selectedBackgroundIndex': selectedBackgroundIndex,
    };
  }

  //-------------------- FROM JSON --------------------
  factory ThemeSettingsModel.fromJson(Map<String, dynamic> json) {
    return ThemeSettingsModel(
      isDarkMode: json['isDarkMode'] ?? false,
      selectedColorIndex: json['selectedColorIndex'] ?? 0,
      selectedBackgroundIndex: json['selectedBackgroundIndex'] ?? 0,
    );
  }

  //-------------------- DEFAULTS --------------------
  static ThemeSettingsModel get defaults {
    return ThemeSettingsModel(
      isDarkMode: false,
      selectedColorIndex: 3, // Amber Gold
      selectedBackgroundIndex: 0, // Alabaster Pearl
    );
  }
}
