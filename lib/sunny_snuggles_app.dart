import 'package:flutter/material.dart';
import 'package:sunny_snuggles/ui/pages/home_page.dart';
import 'package:sunny_snuggles/ui/pages/theme/weather_color_palette.dart';

class SunnySnugglesApp extends StatelessWidget {
  const SunnySnugglesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunny Snuggles ☀️',
      theme: _buildDynamicTheme(WeatherCondition.sunny), // Dynamic theme
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }

  // Dynamic theme based on weather
  ThemeData _buildDynamicTheme(WeatherCondition condition) {
    final colorPalette = WeatherColorPalette.getColors(condition);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPalette.primary,
        brightness: Brightness.light,
        secondary: colorPalette.secondary,
        surface: colorPalette.background,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.9),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
