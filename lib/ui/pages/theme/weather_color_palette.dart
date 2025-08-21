import 'package:flutter/material.dart';

// Color Palette System
enum WeatherCondition { sunny, cloudy, rainy, snowy, stormy }

class WeatherColorPalette {
  final Color primary;
  final Color secondary;
  final Color background;
  final List<Color> gradientColors;

  const WeatherColorPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.gradientColors,
  });

  static WeatherColorPalette getColors(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return const WeatherColorPalette(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFFFFB74D),
          background: Color(0xFFFFF3E0),
          gradientColors: [
            Color(0xFFFFE082),
            Color(0xFFFFB74D),
            Color(0xFFFF8A65),
          ],
        );
      case WeatherCondition.cloudy:
        return const WeatherColorPalette(
          primary: Color(0xFF90A4AE),
          secondary: Color(0xFFB0BEC5),
          background: Color(0xFFECEFF1),
          gradientColors: [
            Color(0xFFB0BEC5),
            Color(0xFF90A4AE),
            Color(0xFF78909C),
          ],
        );
      case WeatherCondition.rainy:
        return const WeatherColorPalette(
          primary: Color(0xFF42A5F5),
          secondary: Color(0xFF64B5F6),
          background: Color(0xFFE3F2FD),
          gradientColors: [
            Color(0xFF81C784),
            Color(0xFF42A5F5),
            Color(0xFF1976D2),
          ],
        );
      case WeatherCondition.snowy:
        return const WeatherColorPalette(
          primary: Color(0xFFE1F5FE),
          secondary: Color(0xFFB3E5FC),
          background: Color(0xFFF0F8FF),
          gradientColors: [
            Color(0xFFE1F5FE),
            Color(0xFFB3E5FC),
            Color(0xFF81D4FA),
          ],
        );
      case WeatherCondition.stormy:
        return const WeatherColorPalette(
          primary: Color(0xFF5C6BC0),
          secondary: Color(0xFF7986CB),
          background: Color(0xFFE8EAF6),
          gradientColors: [
            Color(0xFF5C6BC0),
            Color(0xFF3F51B5),
            Color(0xFF303F9F),
          ],
        );
    }
  }

  static LinearGradient getGradient(WeatherCondition condition) {
    final colors = getColors(condition).gradientColors;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}
