import 'package:flutter/material.dart';
import 'package:flutter_app/theme/token_theme.dart';

extension TokenThemeToMaterial on TokenTheme {
  ThemeData toThemeData({required bool dark}) {
    Color c(String k, [Color fallback = Colors.transparent]) =>
        color(k) ?? fallback;

    // 关键映射
    final primary     = c('componentcolors_utility_brand_utility_brand_500', Colors.orange);
    final onPrimary   = c('colors_text_text_primary_on_accent', Colors.white);

    final secondary   = c('componentcolors_utility_orange_utility_orange_500', Colors.deepOrange);
    final onSecondary = c('colors_text_text_primary900', Colors.black);

    final surfaceContainer  = c('colors_background_bg_primary', dark ? Colors.black : Colors.white);
    final surfaceContainerHighest= c('colors_text_text_primary900', dark ? Colors.white : Colors.black);

    final surface     = c('colors_background_bg_card', dark ? Colors.grey[900]! : Colors.grey[50]!);
    final onSurface   = c('colors_text_text_primary900', dark ? Colors.white : Colors.black);

    final error       = c('componentcolors_utility_red_utility_red_500', Colors.red);
    final onError     = c('colors_text_text_on_accent', Colors.white);

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: onSecondary,
        surfaceContainer: surfaceContainer,
        surfaceContainerHighest: surfaceContainerHighest,
        surface: surface,
        onSurface: onSurface,
        error: error,
        onError: onError,
      ),
    );
  }
}