import 'package:sunny_snuggles/features/weather/model/weather_bundle.dart';

/// Tạo khoá location ổn định từ dữ liệu API
/// KISS: name + country là đủ phân biệt đa số trường hợp
String locationKeyFromBundle(WeatherBundle b) {
  final name = (b.current.locationName).trim();
  final country = (b.current.country).trim();
  return '$name,$country';
}
