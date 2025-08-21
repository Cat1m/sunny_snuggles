import 'weather_current.dart';
import 'weather_day.dart';

class WeatherBundle {
  final WeatherCurrent current;
  final WeatherDay today; // forecast.day cho hôm nay (khớp current.date)
  final WeatherDay tomorrow; // forecast.day cho ngày mai

  const WeatherBundle({
    required this.current,
    required this.today,
    required this.tomorrow,
  });

  /// Tạo từ response `/v1/forecast.json?days=2&...`
  factory WeatherBundle.fromForecastJson(Map<String, dynamic> json) {
    final current = WeatherCurrent.fromJson(json);
    final forecast = json['forecast'] as Map<String, dynamic>? ?? {};
    final list =
        (forecast['forecastday'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (list.length < 2) {
      throw StateError('Forecast must provide 2 days (today & tomorrow).');
    }

    final today = WeatherDay.fromForecastDayJson(list[0]);
    final tomorrow = WeatherDay.fromForecastDayJson(list[1]);

    return WeatherBundle(current: current, today: today, tomorrow: tomorrow);
    // Lưu ý: WeatherAPI có timezone location.localtime → nếu cần align ngày theo TZ
  }
}
