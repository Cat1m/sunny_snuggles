import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sunny_snuggles/features/game/model/quiz_enums.dart';
import 'package:sunny_snuggles/features/weather/model/weather_bundle.dart';
import 'package:sunny_snuggles/ui/pages/theme/weather_color_palette.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.bundle});
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    final current = bundle.current;
    final condition = _conditionFromText(current.conditionText);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chi tiết thời tiết'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: WeatherColorPalette.getGradient(condition),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // HERO bubble lớn
              Hero(
                tag: 'temp-bubble',
                child: _HeroBubbleLarge(temperature: current.tempC.toInt()),
              ),

              const SizedBox(height: 24),

              // Tên điều kiện
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  current.conditionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Stats gọn: High/Low hôm nay, Wind, Humidity, UV (nếu có)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _StatChip(
                      icon: Icons.thermostat,
                      label: 'Cao/Thấp',
                      value:
                          '${bundle.today.maxTempC.toInt()}° / ${bundle.today.minTempC.toInt()}°',
                    ),
                    _StatChip(
                      icon: Icons.air,
                      label: 'Gió',
                      value: '${current.windKph.toInt()} km/h',
                    ),
                    // if (current.humidity != null)
                    //   _StatChip(
                    //     icon: Icons.water_drop,
                    //     label: 'Độ ẩm',
                    //     value: '${current.humidity.toInt()}%',
                    //   ),
                    if (current.uv != null)
                      _StatChip(
                        icon: Icons.wb_sunny,
                        label: 'UV',
                        value: current.uv!.toInt().toString(),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Gợi ý: swipe back
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Opacity(
                  opacity: 0.8,
                  child: Text(
                    'Vuốt để quay lại',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  WeatherCondition _conditionFromText(String t) {
    final s = t.toLowerCase();
    bool any(List<String> keys) => keys.any(s.contains);
    if (any(['thunder', 'storm', 'lightning'])) return WeatherCondition.stormy;
    if (any(['rain', 'drizzle', 'shower'])) return WeatherCondition.rainy;
    if (any(['snow', 'sleet', 'blizzard'])) return WeatherCondition.snowy;
    if (any(['cloud', 'overcast', 'partly', 'mist', 'fog', 'haze'])) {
      return WeatherCondition.cloudy;
    }
    return WeatherCondition.sunny;
  }
}

class _HeroBubbleLarge extends StatelessWidget {
  const _HeroBubbleLarge({required this.temperature});
  final int temperature;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Current temperature $temperature degrees',
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFEFF6FF)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(-0.45, -0.55),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.55),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: Text(
                '$temperature°',
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                  height: 1.0,
                  letterSpacing: -1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
