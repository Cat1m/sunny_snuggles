import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/weather_repository.dart';
import '../../weather/model/weather_bundle.dart';

final isRefreshingProvider = StateProvider.autoDispose<bool>((ref) => false);

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final repo = WeatherRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final weatherBundleCurrentProvider = FutureProvider.autoDispose<WeatherBundle>((
  ref,
) async {
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.fetch2DaysForecastForCurrentLocation();
});
final locationProvider = StateProvider<String>((ref) => '');
