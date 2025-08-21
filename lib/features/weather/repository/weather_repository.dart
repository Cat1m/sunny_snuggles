import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/env.dart';
import '../model/weather_bundle.dart';

class WeatherRepository {
  WeatherRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// Trả về "lat,lon" nếu tìm thấy, nếu không throw
  Future<String> resolveLocationOrThrow(String query) async {
    // Cleanup nhẹ cho input
    final q = query.trim().replaceAll(RegExp(r'\s+'), ' ');

    final uri = Uri.parse('${Env.weatherBaseUrl}/search.json').replace(
      queryParameters: {
        'key': Env.weatherApiKey,
        'q': q, // ví dụ "Ho Chi Minh", "Hồ Chí Minh", "10.82,106.63"
      },
    );

    final resp = await _client
        .get(uri, headers: {HttpHeaders.acceptHeader: 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw HttpException(
        'WeatherAPI search error ${resp.statusCode}: ${resp.body}',
      );
    }
    final list =
        (json.decode(resp.body) as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (list.isEmpty) {
      throw StateError('No matching location for "$q"');
    }
    final first = list.first;
    final lat = (first['lat'] as num).toDouble();
    final lon = (first['lon'] as num).toDouble();

    return '$lat,$lon'; // dùng trực tiếp cho forecast
  }

  /// Lấy forecast 2 ngày (hôm nay & ngày mai)
  Future<WeatherBundle> fetch2DaysForecast(String location) async {
    final q = await resolveLocationOrThrow(location);

    final uri = Uri.parse('${Env.weatherBaseUrl}/forecast.json').replace(
      queryParameters: {
        'key': Env.weatherApiKey,
        'q': q, // <-- luôn là "lat,lon" đã resolve
        'days': '2',
        'aqi': 'no',
        'alerts': 'no',
      },
    );

    final resp = await _client
        .get(uri, headers: {HttpHeaders.acceptHeader: 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw HttpException('WeatherAPI error ${resp.statusCode}: ${resp.body}');
    }

    final map = json.decode(resp.body) as Map<String, dynamic>;
    return WeatherBundle.fromForecastJson(map);
  }

  /// (Optional) Lấy history cho 1 ngày cụ thể (định dạng yyyy-MM-dd)
  /// Dùng để kiểm tra "kết quả thực" sau này nếu cần
  Future<Map<String, dynamic>> fetchHistoryRaw({
    required String location,
    required String dateYmd,
  }) async {
    final uri = Uri.parse('${Env.weatherBaseUrl}/history.json').replace(
      queryParameters: {
        'key': Env.weatherApiKey,
        'q': location,
        'dt': dateYmd, // yyyy-MM-dd
      },
    );

    final resp = await _client
        .get(uri, headers: {HttpHeaders.acceptHeader: 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) {
      throw HttpException(
        'WeatherAPI history error ${resp.statusCode}: ${resp.body}',
      );
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  void dispose() {
    _client.close();
  }
}
