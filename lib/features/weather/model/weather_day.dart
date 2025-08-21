class WeatherDay {
  final DateTime date; // yyyy-MM-dd
  final double maxTempC;
  final double minTempC;
  final double maxWindKph;
  final double? uv; // average uv of the day
  final int? willItRain; // 0/1 (tổng quan ngày)
  final int? dailyChanceOfRain; // %
  final String conditionText;
  final String conditionIcon;

  const WeatherDay({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.maxWindKph,
    required this.uv,
    required this.willItRain,
    required this.dailyChanceOfRain,
    required this.conditionText,
    required this.conditionIcon,
  });

  /// Map từ forecast.forecastday[i]
  factory WeatherDay.fromForecastDayJson(Map<String, dynamic> fd) {
    final dateStr = (fd['date'] ?? '') as String;
    final day = fd['day'] as Map<String, dynamic>? ?? {};
    final cond = day['condition'] as Map<String, dynamic>? ?? {};
    // Rain flags có thể nằm trong 'day' hoặc trong từng 'hour'
    // Ở cấp 'day', WeatherAPI có: daily_will_it_rain, daily_chance_of_rain
    final will = day['daily_will_it_rain'];
    final chance = day['daily_chance_of_rain'];

    return WeatherDay(
      date: DateTime.tryParse(dateStr) ?? DateTime.now(),
      maxTempC: (day['maxtemp_c'] ?? 0).toDouble(),
      minTempC: (day['mintemp_c'] ?? 0).toDouble(),
      maxWindKph: (day['maxwind_kph'] ?? 0).toDouble(),
      uv: day['uv'] == null ? null : (day['uv'] as num).toDouble(),
      willItRain: will is int ? will : (will is num ? will.toInt() : null),
      dailyChanceOfRain: chance is int
          ? chance
          : (chance is num ? chance.toInt() : null),
      conditionText: (cond['text'] ?? '') as String,
      conditionIcon: (cond['icon'] ?? '') as String,
    );
  }
}
