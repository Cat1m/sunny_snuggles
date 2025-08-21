class Env {
  // Lấy từ --dart-define=WEATHER_API_KEY=...
  static const weatherApiKey = String.fromEnvironment('WEATHER_API_KEY');
  static const weatherBaseUrl = 'https://api.weatherapi.com/v1';
}
