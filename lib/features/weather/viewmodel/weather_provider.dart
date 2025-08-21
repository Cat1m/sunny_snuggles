import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/weather_repository.dart';
import '../../weather/model/weather_bundle.dart';

/// Repository (giữ nguyên)
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final repo = WeatherRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// NEW: Forecast 2 ngày theo VỊ TRÍ HIỆN TẠI (geolocator + fallback auto:ip)
final weatherBundleCurrentProvider = FutureProvider.autoDispose<WeatherBundle>((
  ref,
) async {
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.fetch2DaysForecastForCurrentLocation();
});

final locationProvider = StateProvider<String>((ref) => '');
