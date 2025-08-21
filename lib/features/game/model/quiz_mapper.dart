import '../../weather/model/weather_day.dart';
import 'band_mappers.dart';
import 'quiz_enums.dart';

class QuizMapper {
  /// Map từ dữ liệu thời tiết (ngày cần chấm) sang đáp án “đúng” theo band
  static ({TempBand temp, RainChoice rain, WindBand wind, UvBand? uv}) toBands(
    WeatherDay day,
  ) {
    final temp = BandMappers.tempFromMaxC(day.maxTempC);
    final rain = BandMappers.rainFromFlags(
      willItRain: day.willItRain,
      dailyChanceOfRain: day.dailyChanceOfRain,
    );
    final wind = BandMappers.windFromMaxKph(day.maxWindKph);
    final uvBand = (day.uv == null) ? null : BandMappers.uvFromValue(day.uv!);

    return (temp: temp, rain: rain, wind: wind, uv: uvBand);
  }
}
