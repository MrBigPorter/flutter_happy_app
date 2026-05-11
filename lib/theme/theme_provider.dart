import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  // Here you can read from persistent storage to get the saved theme mode
  // Default to dark mode
  return ThemeMode.dark;
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
    static const _themeModeKey = 'app_theme_mode';

    @override
    ThemeMode build() {
      // Initialize with the saved theme mode or default to system
      return ref.read(initialThemeModeProvider);
    }

    Future<void> toggleThemeMode() async {
       final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
       state = next;

       final prefs = await SharedPreferences.getInstance();
       await prefs.setString(_themeModeKey, next.name);
    }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier,ThemeMode>(ThemeModeNotifier.new);
