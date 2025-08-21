import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Lỗi vị trí gọn nhẹ để repo/fallback xử lý.
class LocationException implements Exception {
  final String code; // service_disabled | denied | denied_forever | failed
  final String message;
  const LocationException(this.code, this.message);
  @override
  String toString() => 'LocationException($code): $message';
}

class LocationService {
  const LocationService();

  /// API chính: lấy toạ độ hiện tại.
  /// - Ném LocationException cho các case dễ hiểu.
  /// - Không format số thập phân ở đây (để repo xử lý).
  Future<({double lat, double lon})> getLatLon() async {
    // 1) Dịch vụ vị trí có bật không?
    final serviceEnabled = await GeolocatorPlatform.instance
        .isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'service_disabled',
        'Dịch vụ vị trí đang tắt. Hãy bật Location Services / GPS.',
      );
    }

    // 2) Quyền truy cập (When-In-Use)
    final permission = await _ensurePermission();
    if (permission == LocationPermission.denied) {
      throw const LocationException('denied', 'Bạn đã từ chối quyền vị trí.');
    }
    if (permission == LocationPermission.deniedForever) {
      // Gợi ý mở App Settings bằng permission_handler
      await _suggestOpenAppSettings();
      throw const LocationException(
        'denied_forever',
        'Quyền vị trí bị từ chối vĩnh viễn. Hãy bật trong Cài đặt.',
      );
    }

    // 3) Lấy current position (timeout 10s). Nếu lỗi → fallback last known.
    try {
      final settings = _buildPlatformSettings();
      final pos = await GeolocatorPlatform.instance.getCurrentPosition(
        locationSettings: settings,
      );
      return (lat: pos.latitude, lon: pos.longitude);
    } on TimeoutException {
      final last = await GeolocatorPlatform.instance.getLastKnownPosition();
      if (last != null) return (lat: last.latitude, lon: last.longitude);
      throw const LocationException('failed', 'Quá thời gian chờ lấy vị trí.');
    } catch (_) {
      final last = await GeolocatorPlatform.instance.getLastKnownPosition();
      if (last != null) return (lat: last.latitude, lon: last.longitude);
      throw const LocationException(
        'failed',
        'Không lấy được vị trí hiện tại.',
      );
    }
  }

  /// Xin quyền tối thiểu cần thiết (When-In-Use).
  Future<LocationPermission> _ensurePermission() async {
    var permission = await GeolocatorPlatform.instance.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await GeolocatorPlatform.instance.requestPermission();
    }
    return permission;
  }

  /// Gợi ý mở App Settings bằng permission_handler (KISS).
  Future<void> _suggestOpenAppSettings() async {
    // Chỉ cố gắng mở, không ép buộc/không show dialog ở đây để giữ KISS.
    try {
      await ph.openAppSettings();
    } catch (_) {
      // Bỏ qua nếu không mở được; repo/UI có thể hiển thị hướng dẫn sau.
    }
  }

  /// Chọn LocationSettings theo platform (API mới).
  LocationSettings _buildPlatformSettings() {
    // Timeout chung 10s, accuracy ưu tiên best.
    const timeout = Duration(seconds: 10);

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        // Chỉ bật nếu bạn buộc phải dùng LocationManager cũ (thường không cần):
        forceLocationManager: false,
        timeLimit: timeout,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: timeout,
        // Không theo dõi nền, không hiện chỉ báo — giữ KISS.
        // activityType: ActivityType.other, // tuỳ chọn nếu cần
        // distanceFilter: 0, // mặc định
        // showBackgroundLocationIndicator: false, // mặc định
      );
    }
    // Web/khác: dùng generic settings
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      timeLimit: timeout,
    );
  }
}
