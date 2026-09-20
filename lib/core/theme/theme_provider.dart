import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'dailycost_theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_themeModeKey);
      if (modeString != null) {
        if (modeString == 'light') {
          state = ThemeMode.light;
        } else if (modeString == 'dark') {
          state = ThemeMode.dark;
        } else {
          state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeString = 'system';
      if (mode == ThemeMode.light) {
        modeString = 'light';
      } else if (mode == ThemeMode.dark) {
        modeString = 'dark';
      }
      await prefs.setString(_themeModeKey, modeString);
    } catch (_) {}
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
