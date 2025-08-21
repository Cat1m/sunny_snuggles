import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/weather_repository.dart';
import '../../weather/model/weather_bundle.dart';

/// Provider cho repository (có lifecycle để close client)
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final repo = WeatherRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Vị trí đơn giản (KISS). Bạn có thể thay bằng geolocator sau.
/// Ví dụ mặc định: "Ho Chi Minh"
final locationProvider = StateProvider<String>((ref) => '10.8231,106.6297');

/// Lấy WeatherBundle theo location hiện tại (today + tomorrow)
final weatherBundleProvider = FutureProvider.autoDispose<WeatherBundle>((
  ref,
) async {
  final repo = ref.watch(weatherRepositoryProvider);
  final loc = ref.watch(locationProvider);
  return repo.fetch2DaysForecast(loc);
});
