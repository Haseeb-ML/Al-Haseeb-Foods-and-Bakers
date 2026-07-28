import 'package:flutter/material.dart';

//-------------------- GLOBAL THEME CONTROLLER --------------------
// App mein kahin se bhi theme change kar sakte hain: themeController.value = ThemeMode.light
final ValueNotifier<ThemeMode> themeController = ValueNotifier(ThemeMode.dark);
