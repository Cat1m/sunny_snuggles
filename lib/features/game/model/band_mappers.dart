import 'quiz_enums.dart';

class BandMappers {
  /// Nhiệt độ theo MAX temp của ngày (°C)
  static TempBand tempFromMaxC(num maxTempC) {
    if (maxTempC < 20) return TempBand.lt20;
    if (maxTempC < 30) return TempBand.t20to29;
    return TempBand.gte30;
  }

  /// Có mưa? Ưu tiên cờ will_it_rain của WeatherAPI (0/1).
  /// Nếu null, fallback theo dailyChanceOfRain (%).
  static RainChoice rainFromFlags({int? willItRain, int? dailyChanceOfRain}) {
    if (willItRain != null) {
      return willItRain == 1 ? RainChoice.yes : RainChoice.no;
    }
    if (dailyChanceOfRain != null) {
      return dailyChanceOfRain >= 50 ? RainChoice.yes : RainChoice.no;
    }
    return RainChoice.no;
  }

  /// Gió mạnh nhất trong ngày (km/h)
  static WindBand windFromMaxKph(num maxWindKph) {
    if (maxWindKph < 10) return WindBand.calm;
    if (maxWindKph <= 25) return WindBand.moderate;
    return WindBand.windy;
  }

  /// UV trung bình/ngày. WeatherAPI `day.uv` là chỉ số UV trung bình/ngày.
  static UvBand uvFromValue(num uv) {
    if (uv < 3) return UvBand.low;
    if (uv < 6) return UvBand.moderate;
    return UvBand.high;
  }
}
