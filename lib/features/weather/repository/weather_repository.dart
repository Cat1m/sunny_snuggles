import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sunny_snuggles/services/location_service.dart';
import '../../../core/env.dart';
import '../model/weather_bundle.dart';

class WeatherRepository {
  WeatherRepository({LocationService? locationService, Dio? dio})
    : _locationService = locationService ?? const LocationService(),
      _dio = dio ?? _buildDefaultDio();

  final LocationService _locationService;
  final Dio _dio;

  // ---------- Helpers ----------
  static Dio _buildDefaultDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: Env.weatherBaseUrl, // ví dụ: https://api.weatherapi.com/v1
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    if (kDebugMode) {
      d.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          compact: true,
          maxWidth: 100,
        ),
      );
    }
    return d;
  }

  String _formatCoord(double v) => v.toStringAsFixed(5);
  String _buildQFromLatLon(double lat, double lon) =>
      '${_formatCoord(lat)},${_formatCoord(lon)}';

  // Gọi endpoint bất kỳ nhận tham số q (current.json, forecast.json, …)
  Future<Map<String, dynamic>> _getByQ(
    String path, {
    required String q,
    Map<String, dynamic>? extra,
  }) async {
    final qp = {'key': Env.weatherApiKey, 'q': q, ...?extra};
    final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: qp);
    final data = res.data;
    if (data == null) {
      throw StateError('Empty response for $path');
    }
    return data;
  }

  // ---------- Public APIs ----------
  /// Lấy forecast 2 ngày (hôm nay & ngày mai) theo vị trí hiện tại (geolocator + fallback auto:ip)
  Future<WeatherBundle> fetch2DaysForecastForCurrentLocation() async {
    try {
      final c = await _locationService.getLatLon();
      final q = _buildQFromLatLon(c.lat, c.lon);
      final map = await _getByQ(
        '/forecast.json',
        q: q,
        extra: {'days': '2', 'aqi': 'no', 'alerts': 'no'},
      );
      return WeatherBundle.fromForecastJson(map);
    } on LocationException catch (e) {
      if (e.code == 'service_disabled' ||
          e.code == 'denied' ||
          e.code == 'denied_forever') {
        // Fallback KISS: vẫn trả được dữ liệu
        final map = await _getByQ(
          '/forecast.json',
          q: 'auto:ip',
          extra: {'days': '2', 'aqi': 'no', 'alerts': 'no'},
        );
        return WeatherBundle.fromForecastJson(map);
      }
      rethrow;
    }
  }

  void dispose() {}
}
