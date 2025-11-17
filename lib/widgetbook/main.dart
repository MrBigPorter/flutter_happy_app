import 'package:flutter/material.dart';
import 'package:flutter_app/widgetbook/stories/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:easy_localization/easy_localization.dart';

import '../theme/design_tokens.g.dart';
import '../theme/theme_provider.dart';

/// widgetbook main entry
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // theme provider
  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = prefs.getString('app_theme_mode');

  final initialThemeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedThemeMode,
    orElse: () => ThemeMode.system,
  );

  runApp(
   riverpod.ProviderScope(
     overrides: [
       // 4) 覆盖初始主题模式 provider
       initialThemeModeProvider.overrideWithValue(initialThemeMode)
     ],
      child:  EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('tl')],
        path: 'assets/locales',
        fallbackLocale: const Locale('en'),
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          useInheritedMediaQuery: true,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) => const WidgetBookApp(),
        ),
      ),
  ));
}

class WidgetBookApp extends riverpod.ConsumerWidget {
  const WidgetBookApp({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
   final themeMode = ref.watch(themeModeProvider);


    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child){
        return Widgetbook.material(
          // add all component stories here
          directories: buildAllComponentStories(context),
          lightTheme: _buildTheme(false),
          darkTheme: _buildTheme(true),
          themeMode: themeMode,
          addons: [
            DeviceFrameAddon(
              devices: [
                Devices.ios.iPhone14Pro,
                Devices.ios.iPad,
                Devices.android.samsungGalaxyS20,
              ],
            ),
            // add localization support, elements will be translated if the text is wrapped with tr()
            LocalizationAddon(
                locales: const [Locale('en'), Locale('tl')],
              localizationsDelegates: [
                ...context.localizationDelegates,
              ],
              initialLocale: context.locale,
            )

          ],
          header: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Lucky App Components', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

ThemeData _buildTheme(bool dark) {
  final brightness = dark ? Brightness.dark : Brightness.light;

  final cs =
  ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    brightness: brightness,
  ).copyWith(
    surface: brightness == Brightness.dark
        ? TokensDark.bgMobilePrimary
        : TokensLight.bgMobilePrimary,
  );
  return ThemeData(
    fontFamily: 'Inter',
    useMaterial3: true,
    brightness: brightness,
    colorScheme: cs,
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? TokensDark.bgMobilePrimary
        : TokensLight.bgMobilePrimary,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}