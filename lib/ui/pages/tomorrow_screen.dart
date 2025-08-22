import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sunny_snuggles/features/game/model/quiz_enums.dart';
import 'package:sunny_snuggles/features/weather/model/weather_bundle.dart';
import 'package:sunny_snuggles/ui/pages/theme/weather_color_palette.dart';

class TomorrowScreen extends StatelessWidget {
  const TomorrowScreen({super.key, required this.bundle});
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    final tm = _resolveTomorrow(bundle);
    final condition = _conditionFromText(tm.conditionText);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Thời tiết ngày mai'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: WeatherColorPalette.getGradient(condition),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Bubble hiển thị trung bình (optional): (max+min)/2
              Hero(
                tag: 'temp-bubble', // có thể bỏ nếu không muốn dùng chung tag
                child: _TomorrowBubble(
                  avgTemp: ((tm.maxTempC + tm.minTempC) / 2).round(),
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  tm.conditionText,
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _StatChip(
                      icon: Icons.thermostat,
                      label: 'Cao',
                      value: '${tm.maxTempC.toInt()}°',
                    ),
                    _StatChip(
                      icon: Icons.ac_unit,
                      label: 'Thấp',
                      value: '${tm.minTempC.toInt()}°',
                    ),
                    if (tm.dailyChanceOfRain != null)
                      _StatChip(
                        icon: Icons.umbrella,
                        label: 'Mưa',
                        value: '${tm.dailyChanceOfRain!.toInt()}%',
                      ),
                    if (tm.uv != null)
                      _StatChip(
                        icon: Icons.wb_sunny,
                        label: 'UV',
                        value: tm.uv!.toInt().toString(),
                      ),
                  ],
                ),
              ),

              const Spacer(),
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

  /// Cố gắng lấy "ngày mai" linh hoạt theo cấu trúc WeatherBundle bạn đang có
  _TomorrowDTO _resolveTomorrow(WeatherBundle b) {
    final dyn = b as dynamic;

    // Trường hợp bundle.tomorrow tồn tại
    if ((dyn as dynamic).tomorrow != null) {
      final t = dyn.tomorrow;
      return _TomorrowDTO(
        maxTempC: t.maxTempC.toDouble(),
        minTempC: t.minTempC.toDouble(),
        conditionText: t.conditionText as String,
        dailyChanceOfRain: (t.dailyChanceOfRain is num)
            ? (t.dailyChanceOfRain as num).toDouble()
            : null,
        uv: (t.uv is num) ? (t.uv as num).toDouble() : null,
      );
    }

    // Fallback: forecast[1] nếu bạn có mảng dự báo
    if (dyn.forecast != null &&
        dyn.forecast is List &&
        dyn.forecast.length > 1) {
      final t = dyn.forecast[1];
      return _TomorrowDTO(
        maxTempC: (t.maxTempC as num).toDouble(),
        minTempC: (t.minTempC as num).toDouble(),
        conditionText: t.conditionText as String,
        dailyChanceOfRain: (t.dailyChanceOfRain is num)
            ? (t.dailyChanceOfRain as num).toDouble()
            : null,
        uv: (t.uv is num) ? (t.uv as num).toDouble() : null,
      );
    }

    // Nếu không có, dùng today như dự phòng (để UI không vỡ)
    final t = dyn.today;
    return _TomorrowDTO(
      maxTempC: (t.maxTempC as num).toDouble(),
      minTempC: (t.minTempC as num).toDouble(),
      conditionText: t.conditionText as String,
      dailyChanceOfRain: (t.dailyChanceOfRain is num)
          ? (t.dailyChanceOfRain as num).toDouble()
          : null,
      uv: (t.uv is num) ? (t.uv as num).toDouble() : null,
    );
  }
}

class _TomorrowDTO {
  _TomorrowDTO({
    required this.maxTempC,
    required this.minTempC,
    required this.conditionText,
    this.dailyChanceOfRain,
    this.uv,
  });

  final double maxTempC;
  final double minTempC;
  final String conditionText;
  final double? dailyChanceOfRain;
  final double? uv;
}

class _TomorrowBubble extends StatelessWidget {
  const _TomorrowBubble({required this.avgTemp});
  final int avgTemp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Average temperature tomorrow $avgTemp degrees',
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFEFF6FF)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(-0.45, -0.55),
              child: Container(
                width: 120,
                height: 120,
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
                '$avgTemp°',
                style: const TextStyle(
                  fontSize: 84,
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
