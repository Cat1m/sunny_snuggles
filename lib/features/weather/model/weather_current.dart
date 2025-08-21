class WeatherCurrent {
  final String locationName;
  final String region; // optional UI
  final String country; // optional UI
  final double tempC;
  final double windKph;
  final double? uv; // có thể null tùy plan
  final String conditionText;
  final String conditionIcon; // //cdn.weatherapi.com/weather/64x64/...

  const WeatherCurrent({
    required this.locationName,
    required this.region,
    required this.country,
    required this.tempC,
    required this.windKph,
    required this.uv,
    required this.conditionText,
    required this.conditionIcon,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final cur = json['current'] as Map<String, dynamic>? ?? {};
    final cond = cur['condition'] as Map<String, dynamic>? ?? {};

    return WeatherCurrent(
      locationName: (loc['name'] ?? '') as String,
      region: (loc['region'] ?? '') as String,
      country: (loc['country'] ?? '') as String,
      tempC: (cur['temp_c'] ?? 0).toDouble(),
      windKph: (cur['wind_kph'] ?? 0).toDouble(),
      uv: cur['uv'] == null ? null : (cur['uv'] as num).toDouble(),
      conditionText: (cond['text'] ?? '') as String,
      conditionIcon: (cond['icon'] ?? '') as String,
    );
  }
}
