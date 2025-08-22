// weather_payload.dart
// Build payload tối ưu gửi LLM từ dữ liệu WeatherAPI (forecast.json)
// Không phụ thuộc package ngoài. Null-safety. Dễ unit-test.
//
// Tác vụ chính:
// 1) Parse các field cần thiết từ JSON (chỉ chọn phần cần thiết).
// 2) Tính indices (Comfort/Rain/Sun/Wind/Visibility/Heat).
// 3) Gom nhóm theo periods (early_morning, late_morning, afternoon, evening).
// 4) Rút ra highlights (uv_peak, rain_peak, wind_peak, heat_peak) + overlap.
// 5) Xuất payload Map<String, dynamic> đúng schema v1.1.

// ------------------------------ Utils ------------------------------

import 'dart:math' as math;

num clamp(num v, num lo, num hi) => v < lo ? lo : (v > hi ? hi : v);

double _toDouble(dynamic x, [double fallback = 0]) {
  if (x == null) return fallback;
  if (x is num) return x.toDouble();
  if (x is String) {
    return double.tryParse(x) ?? fallback;
  }
  return fallback;
}

int _toInt(dynamic x, [int fallback = 0]) {
  if (x == null) return fallback;
  if (x is num) return x.toInt();
  if (x is String) {
    return int.tryParse(x) ?? fallback;
  }
  return fallback;
}

DateTime? _parseLocalTime(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    // WeatherAPI trả "YYYY-MM-DD HH:mm" (no timezone). Chúng ta coi là local theo tz trong meta.
    return DateTime.parse(s.replaceFirst(' ', 'T'));
  } catch (_) {
    return null;
  }
}

double _avg(Iterable<double> xs) {
  final list = xs.where((e) => e.isFinite).toList();
  if (list.isEmpty) return 0;
  return list.reduce((a, b) => a + b) / list.length;
}

T? _mode<T>(Iterable<T> xs) {
  final map = <T, int>{};
  for (final x in xs) {
    map[x] = (map[x] ?? 0) + 1;
  }
  if (map.isEmpty) return null;
  return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

// ------------------------------ Models (lightweight) ------------------------------

class LocationInfo {
  final String name;
  final String country;
  final String tzId;
  final String date; // YYYY-MM-DD (we derive from forecastday[0].date)
  LocationInfo({
    required this.name,
    required this.country,
    required this.tzId,
    required this.date,
  });
}

class CurrentInfo {
  final double tempC;
  final double feelslikeC;
  final String conditionText;
  final int humidity; // %
  final double windKph;
  final double uv;

  CurrentInfo({
    required this.tempC,
    required this.feelslikeC,
    required this.conditionText,
    required this.humidity,
    required this.windKph,
    required this.uv,
  });
}

class DaySummary {
  final double maxTempC;
  final double minTempC;
  final int dailyChanceOfRain; // 0..100
  final double totalPrecipMm;
  final double maxWindKph;
  DaySummary({
    required this.maxTempC,
    required this.minTempC,
    required this.dailyChanceOfRain,
    required this.totalPrecipMm,
    required this.maxWindKph,
  });
}

class HourPoint {
  final DateTime time; // local date time
  final double tempC;
  final double feelslikeC; // hoặc dùng heatindex nếu có
  final double heatIndexC;
  final int humidity; // %
  final double windKph;
  final double gustKph;
  final double uv;
  final int chanceOfRain; // 0..100
  final double visKm;
  final String conditionText;
  final int cloud; // 0..100

  HourPoint({
    required this.time,
    required this.tempC,
    required this.feelslikeC,
    required this.heatIndexC,
    required this.humidity,
    required this.windKph,
    required this.gustKph,
    required this.uv,
    required this.chanceOfRain,
    required this.visKm,
    required this.conditionText,
    required this.cloud,
  });
}

class PeriodStats {
  final double tempAvg;
  final double feelsAvg;
  final double uvMax;
  final int rainChanceMax;
  final double windMax;
  final String condition; // dominant
  final String note;

  PeriodStats({
    required this.tempAvg,
    required this.feelsAvg,
    required this.uvMax,
    required this.rainChanceMax,
    required this.windMax,
    required this.condition,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
    "temp_avg": _round1(tempAvg),
    "feelslike_avg": _round1(feelsAvg),
    "uv_max": _round1(uvMax),
    "rain_chance_max": rainChanceMax,
    "wind_max": _round1(windMax),
    "condition": condition,
    "note": note,
  };
}

class Indices {
  final int comfort;
  final int rainRisk;
  final int sunExposure;
  final int windImpact;
  final int visibility;
  final int heatStress;
  Indices({
    required this.comfort,
    required this.rainRisk,
    required this.sunExposure,
    required this.windImpact,
    required this.visibility,
    required this.heatStress,
  });

  Map<String, dynamic> toJson() => {
    "comfort": comfort,
    "rain_risk": rainRisk,
    "sun_exposure": sunExposure,
    "wind_impact": windImpact,
    "visibility": visibility,
    "heat_stress": heatStress,
  };
}

class Highlight {
  final String type; // uv_peak, rain_peak, wind_peak, heat_peak
  final String start; // "HH:MM"
  final String end; // "HH:MM"
  final double value;
  final String shortReason;

  Highlight({
    required this.type,
    required this.start,
    required this.end,
    required this.value,
    required this.shortReason,
  });

  Map<String, dynamic> toJson() => {
    "type": type,
    "start": start,
    "end": end,
    "value": _round1(value),
    "short_reason": shortReason,
  };
}

// ------------------------------ Extractors from WeatherAPI JSON ------------------------------

LocationInfo parseLocation(Map<String, dynamic> root) {
  final loc = (root["location"] as Map?) ?? {};
  final name = (loc["name"] ?? "").toString();
  final country = (loc["country"] ?? "").toString();
  final tz = (loc["tz_id"] ?? "Asia/Ho_Chi_Minh").toString();

  // Lấy date từ forecastday[0]
  final forecast = (root["forecast"] as Map?)?["forecastday"] as List? ?? [];
  final firstDay = (forecast.isNotEmpty ? forecast.first : null) as Map?;
  final date = (firstDay?["date"] ?? "").toString(); // "YYYY-MM-DD"

  return LocationInfo(name: name, country: country, tzId: tz, date: date);
}

CurrentInfo parseCurrent(Map<String, dynamic> root) {
  final cur = (root["current"] as Map?) ?? {};
  final cond = (cur["condition"] as Map?) ?? {};
  return CurrentInfo(
    tempC: _toDouble(cur["temp_c"]),
    feelslikeC: _toDouble(cur["feelslike_c"]),
    conditionText: (cond["text"] ?? "").toString(),
    humidity: _toInt(cur["humidity"]),
    windKph: _toDouble(cur["wind_kph"]),
    uv: _toDouble(cur["uv"]),
  );
}

DaySummary parseDaySummary(Map<String, dynamic> forecastDay) {
  final day = (forecastDay["day"] as Map?) ?? {};
  return DaySummary(
    maxTempC: _toDouble(day["maxtemp_c"]),
    minTempC: _toDouble(day["mintemp_c"]),
    dailyChanceOfRain: _toInt(day["daily_chance_of_rain"]),
    totalPrecipMm: _toDouble(day["totalprecip_mm"]),
    maxWindKph: _toDouble(day["maxwind_kph"]),
  );
}

List<HourPoint> parseHours(Map<String, dynamic> forecastDay) {
  final hours = (forecastDay["hour"] as List?) ?? [];
  return hours.map((h) {
    final cond = (h as Map)["condition"] as Map? ?? {};
    final timeStr = (h["time"] ?? "").toString(); // "YYYY-MM-DD HH:mm"
    final dt = _parseLocalTime(timeStr) ?? DateTime.now();

    return HourPoint(
      time: dt,
      tempC: _toDouble(h["temp_c"]),
      feelslikeC: _toDouble(h["feelslike_c"]),
      heatIndexC: _toDouble(h["heatindex_c"], _toDouble(h["feelslike_c"])),
      humidity: _toInt(h["humidity"]),
      windKph: _toDouble(h["wind_kph"]),
      gustKph: _toDouble(h["gust_kph"], _toDouble(h["wind_kph"])),
      uv: _toDouble(h["uv"]),
      chanceOfRain: _toInt(h["chance_of_rain"]),
      visKm: _toDouble(h["vis_km"], 10),
      conditionText: (cond["text"] ?? "").toString(),
      cloud: _toInt(h["cloud"]),
    );
  }).toList();
}

// ------------------------------ Period splitter ------------------------------

enum PeriodSlot { earlyMorning, lateMorning, afternoon, evening }

bool _inRange(DateTime t, int startHour, int endHour) {
  final h = t.hour;
  return h >= startHour && h < endHour;
}

Map<PeriodSlot, List<HourPoint>> splitPeriods(List<HourPoint> hours) {
  final map = {
    PeriodSlot.earlyMorning: <HourPoint>[],
    PeriodSlot.lateMorning: <HourPoint>[],
    PeriodSlot.afternoon: <HourPoint>[],
    PeriodSlot.evening: <HourPoint>[],
  };
  for (final h in hours) {
    if (_inRange(h.time, 6, 9)) {
      map[PeriodSlot.earlyMorning]!.add(h);
    } else if (_inRange(h.time, 9, 12)) {
      map[PeriodSlot.lateMorning]!.add(h);
    } else if (_inRange(h.time, 12, 18)) {
      map[PeriodSlot.afternoon]!.add(h);
    } else if (_inRange(h.time, 18, 24)) {
      map[PeriodSlot.evening]!.add(h);
    }
  }
  return map;
}

PeriodStats buildPeriodStats(List<HourPoint> H) {
  if (H.isEmpty) {
    return PeriodStats(
      tempAvg: 0,
      feelsAvg: 0,
      uvMax: 0,
      rainChanceMax: 0,
      windMax: 0,
      condition: "",
      note: "",
    );
  }
  final tempAvg = _avg(H.map((e) => e.tempC));
  final feelsAvg = _avg(
    H.map((e) => (e.heatIndexC.isFinite ? e.heatIndexC : e.feelslikeC)),
  );
  final uvMax = H.map((e) => e.uv).fold<double>(0, (m, v) => v > m ? v : m);
  final rainMax = H
      .map((e) => e.chanceOfRain)
      .fold<int>(0, (m, v) => v > m ? v : m);
  final windMax = H
      .map((e) => e.windKph)
      .fold<double>(0, (m, v) => v > m ? v : m);
  final cond = _mode(H.map((e) => e.conditionText)) ?? "";

  // Note ngắn
  final notes = <String>[];
  if (rainMax >= 70) {
    // giờ đỉnh mưa
    final peak = H.reduce((a, b) => a.chanceOfRain >= b.chanceOfRain ? a : b);
    notes.add("Mưa cao ~${_fmtHm(peak.time)}");
  }
  if (uvMax >= 8) {
    notes.add("UV rất cao");
  }
  final minVis = H
      .map((e) => e.visKm)
      .fold<double>(10, (m, v) => v < m ? v : m);
  final fogHours = H
      .where(
        (e) =>
            e.conditionText.toLowerCase().contains("mist") ||
            e.conditionText.toLowerCase().contains("fog"),
      )
      .length;
  if (minVis <= 2 || fogHours >= 2) {
    notes.add("Sương mù giảm tầm nhìn");
  }

  return PeriodStats(
    tempAvg: tempAvg,
    feelsAvg: feelsAvg,
    uvMax: uvMax,
    rainChanceMax: rainMax,
    windMax: windMax,
    condition: cond,
    note: notes.join("; "),
  );
}

// ------------------------------ Indices calculators ------------------------------

int _roundIndex(num x) => clamp(x.round(), 0, 100).toInt();
double _round1(num x) => ((x * 10).roundToDouble() / 10.0);

int calcComfortIndex({
  required double feelslikeC,
  required int humidity,
  required double windKph,
  required int cloud, // 0..100
}) {
  final double feelScore = clamp(
    100 - 8 * (feelslikeC - 27).abs(),
    0,
    100,
  ).toDouble();
  final double humScore = clamp(
    100 - 2 * (humidity - 55).abs(),
    0,
    100,
  ).toDouble();
  final double windShape = -2 * (windKph - 10) * (windKph - 10) + 100;
  final double windScore = clamp(
    windShape.isFinite ? windShape : 0,
    0,
    100,
  ).toDouble();
  final double cloudScore = (100 - clamp(cloud, 0, 100)).toDouble();

  final double ci =
      0.45 * feelScore + 0.25 * humScore + 0.20 * windScore + 0.10 * cloudScore;
  return _roundIndex(ci);
}

int calcRainRiskIndex({
  required int dailyChanceOfRain,
  required int maxHourlyChanceOfRain,
  required double totalPrecipMm,
}) {
  final pDay = clamp(dailyChanceOfRain, 0, 100);
  final pPeak = clamp(maxHourlyChanceOfRain, 0, 100);
  final double vol = clamp(20 * log10(1 + totalPrecipMm), 0, 100).toDouble();
  final rri = 0.5 * pDay + 0.4 * pPeak + 0.1 * vol;
  return _roundIndex(rri);
}

double log10(num x) => x <= 0 ? 0 : (math.log(x.toDouble()) / math.ln10);

// As Dart's core doesn't expose x.log() directly, we'll shim using dart:math.
// Add this import line at top in your project: import 'dart:math' as math;
// And replace above helpers with math.log(x) / math.ln10 etc.
// (Giữ lại giải pháp này nếu bạn dán file vào môi trường không cho import.)
// => Khuyến nghị: dùng import 'dart:math' as math; và sửa:
// double log10(num x) => x <= 0 ? 0 : (math.log(x) / math.ln10);

int calcSunExposureIndex({required double uvMax}) {
  final v = (uvMax / 11.0);
  final sei = clamp(v, 0, 1) * 100;
  return _roundIndex(sei);
}

int calcWindImpactIndex({
  required double maxWindKph,
  required double maxGustKph,
}) {
  final v = maxWindKph > maxGustKph ? maxWindKph : maxGustKph;
  final wii = (v / 60.0) * 100.0;
  return _roundIndex(wii);
}

int calcVisibilityIndex({required double minVisKm, required int fogHours}) {
  double base = (minVisKm / 10.0) * 100.0;
  base = clamp(base, 0, 100).toDouble(); // <— thêm .toDouble()
  if (fogHours >= 2) base -= 20;
  return _roundIndex(base);
}

int calcHeatStressIndex({required double maxHeatIndexC}) {
  final h = (maxHeatIndexC - 27) * 6;
  return _roundIndex(h);
}

// ------------------------------ Highlights ------------------------------

Highlight? _findHighlight(List<Highlight> list, String type) {
  for (final h in list) {
    if (h.type == type) return h;
  }
  return null;
}

String _fmtHm(DateTime t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return "$hh:$mm";
}

Highlight? _peakUv(List<HourPoint> hours) {
  if (hours.isEmpty) return null;
  final peak = hours.reduce((a, b) => a.uv >= b.uv ? a : b);
  if (peak.uv < 8.0) return null; // ngưỡng tạo highlight
  final start = peak.time.subtract(const Duration(minutes: 60));
  final end = peak.time.add(const Duration(minutes: 60));
  return Highlight(
    type: "uv_peak",
    start: _fmtHm(start),
    end: _fmtHm(end),
    value: peak.uv,
    shortReason: "UV rất cao",
  );
}

Highlight? _peakRain(List<HourPoint> hours) {
  if (hours.isEmpty) return null;
  final peak = hours.reduce((a, b) => a.chanceOfRain >= b.chanceOfRain ? a : b);
  if (peak.chanceOfRain < 70) return null;
  final start = peak.time.subtract(const Duration(minutes: 60));
  final end = peak.time.add(const Duration(minutes: 60));
  return Highlight(
    type: "rain_peak",
    start: _fmtHm(start),
    end: _fmtHm(end),
    value: peak.chanceOfRain.toDouble(),
    shortReason: "Mưa dễ xảy ra",
  );
}

Highlight? _peakWind(List<HourPoint> hours) {
  if (hours.isEmpty) return null;
  final peak = hours.reduce((a, b) => a.gustKph >= b.gustKph ? a : b);
  if (peak.gustKph < 40) return null;
  final start = peak.time.subtract(const Duration(minutes: 60));
  final end = peak.time.add(const Duration(minutes: 60));
  return Highlight(
    type: "wind_peak",
    start: _fmtHm(start),
    end: _fmtHm(end),
    value: peak.gustKph,
    shortReason: "Gió giật",
  );
}

Highlight? _peakHeat(List<HourPoint> hours) {
  if (hours.isEmpty) return null;
  final peak = hours.reduce((a, b) => a.heatIndexC >= b.heatIndexC ? a : b);
  if (peak.heatIndexC < 37) return null;
  final start = peak.time.subtract(const Duration(minutes: 60));
  final end = peak.time.add(const Duration(minutes: 60));
  return Highlight(
    type: "heat_peak",
    start: _fmtHm(start),
    end: _fmtHm(end),
    value: peak.heatIndexC,
    shortReason: "Oi nóng",
  );
}

bool _overlapHHmm(String s1, String e1, String s2, String e2) {
  final t1s = _parseHm(s1);
  final t1e = _parseHm(e1);
  final t2s = _parseHm(s2);
  final t2e = _parseHm(e2);
  if (t1s == null || t1e == null || t2s == null || t2e == null) return false;
  // Overlap nếu max(start) < min(end)
  final latestStart = t1s.isAfter(t2s) ? t1s : t2s;
  final earliestEnd = t1e.isBefore(t2e) ? t1e : t2e;
  return latestStart.isBefore(earliestEnd);
}

DateTime? _parseHm(String hm) {
  // Parse "HH:MM" thành DateTime ngày 1970-01-01
  final parts = hm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return DateTime(1970, 1, 1, h, m);
}

// ------------------------------ Builder (main API) ------------------------------

class WeatherPayloadBuilder {
  final Map<String, dynamic> json;

  WeatherPayloadBuilder(this.json);

  Map<String, dynamic> buildPayload() {
    final loc = parseLocation(json);
    final current = parseCurrent(json);

    // lấy forecast day đầu tiên (hoặc theo date mong muốn)
    final forecastDays =
        (json["forecast"] as Map?)?["forecastday"] as List? ?? [];
    if (forecastDays.isEmpty) {
      throw ArgumentError("forecast.forecastday trống");
    }
    final today = forecastDays.first as Map<String, dynamic>;

    final daySummary = parseDaySummary(today);
    final hours = parseHours(today);

    // ---- Periods ----
    final periodsMap = splitPeriods(hours);
    final pEarly = buildPeriodStats(periodsMap[PeriodSlot.earlyMorning] ?? []);
    final pLate = buildPeriodStats(periodsMap[PeriodSlot.lateMorning] ?? []);
    final pAfter = buildPeriodStats(periodsMap[PeriodSlot.afternoon] ?? []);
    final pEven = buildPeriodStats(periodsMap[PeriodSlot.evening] ?? []);

    // ---- Indices (tính theo ngày) ----
    final maxHourlyRain = hours
        .map((e) => e.chanceOfRain)
        .fold<int>(0, (m, v) => v > m ? v : m);
    final uvMax = hours.fold<double>(0.0, (m, e) => e.uv > m ? e.uv : m);
    final maxGust = hours.fold<double>(
      0.0,
      (m, e) => e.gustKph > m ? e.gustKph : m,
    );
    final minVis = hours.fold<double>(
      10.0,
      (m, e) => e.visKm < m ? e.visKm : m,
    );
    final fogHours = hours
        .where(
          (e) =>
              e.conditionText.toLowerCase().contains("mist") ||
              e.conditionText.toLowerCase().contains("fog"),
        )
        .length;
    final maxHeat = hours.fold<double>(0.0, (m, e) {
      final v = e.heatIndexC.isFinite ? e.heatIndexC : e.feelslikeC;
      return v > m ? v : m;
    });

    // cloud % cho comfort: lấy cloud tại "now" gần nhất (hoặc mode trong ngày)
    final cloudForNow = _mode(hours.map((e) => e.cloud)) ?? 50;

    final indices = Indices(
      comfort: calcComfortIndex(
        feelslikeC: current.feelslikeC,
        humidity: current.humidity,
        windKph: current.windKph,
        cloud: cloudForNow,
      ),
      rainRisk: calcRainRiskIndex(
        dailyChanceOfRain: daySummary.dailyChanceOfRain,
        maxHourlyChanceOfRain: maxHourlyRain,
        totalPrecipMm: daySummary.totalPrecipMm,
      ),
      sunExposure: calcSunExposureIndex(uvMax: uvMax),
      windImpact: calcWindImpactIndex(
        maxWindKph: daySummary.maxWindKph,
        maxGustKph: maxGust,
      ),
      visibility: calcVisibilityIndex(minVisKm: minVis, fogHours: fogHours),
      heatStress: calcHeatStressIndex(maxHeatIndexC: maxHeat),
    );

    // ---- Highlights ----
    final hs = <Highlight>[];
    final hUv = _peakUv(hours);
    if (hUv != null) hs.add(hUv);
    final hRain = _peakRain(hours);
    if (hRain != null) hs.add(hRain);
    final hWind = _peakWind(hours);
    if (hWind != null) hs.add(hWind);
    final hHeat = _peakHeat(hours);
    if (hHeat != null) hs.add(hHeat);

    // chọn tối đa 3 highlight theo "độ quan trọng" (ưu tiên rain, uv, heat, wind)
    hs.sort((a, b) {
      int score(Highlight h) {
        switch (h.type) {
          case "rain_peak":
            return 4;
          case "uv_peak":
            return 3;
          case "heat_peak":
            return 2;
          case "wind_peak":
            return 1;
          default:
            return 0;
        }
      }

      return score(b) - score(a);
    });
    final topHighlights = hs.take(3).toList();

    // overlap uv-rain
    bool uvRainOverlap = false;
    final firstUv = _findHighlight(topHighlights, "uv_peak");
    final firstRain = _findHighlight(topHighlights, "rain_peak");
    if (firstUv != null && firstRain != null) {
      uvRainOverlap = _overlapHHmm(
        firstUv.start,
        firstUv.end,
        firstRain.start,
        firstRain.end,
      );
    }

    // ---- Build payload ----
    final payload = <String, dynamic>{
      "meta": {
        "locale": "vi-VN",
        "location": "${loc.name}, ${loc.country}",
        "date": loc.date,
        "tz": loc.tzId,
        "units": {"temp": "C", "wind": "km/h", "vis": "km"},
        "source": "weatherapi.com",
      },
      "now": {
        "temp_c": _round1(current.tempC),
        "feelslike_c": _round1(current.feelslikeC),
        "condition": current.conditionText,
        "humidity": current.humidity,
        "wind_kph": _round1(current.windKph),
        "uv": _round1(current.uv),
      },
      "indices": indices.toJson(),
      "periods": {
        "early_morning": pEarly.toJson(),
        "late_morning": pLate.toJson(),
        "afternoon": pAfter.toJson(),
        "evening": pEven.toJson(),
      },
      "highlights": topHighlights.map((e) => e.toJson()).toList(),
      "relations": {"uv_rain_overlap": uvRainOverlap},
      "style": {
        "tone": "thân thiện, ngắn gọn",
        "max_sentences": 3,
        "include_tip": true,
        "timeword": true,
      },
    };

    return payload;
  }
}

// ------------------------------ Test nhanh (sample) ------------------------------
// Dùng mẫu dữ liệu rút gọn từ log của bạn (06:00–10:00 + current + day).
// Bạn có thể bỏ phần main này trong Flutter (hoặc chuyển thành unit test).

/*
void main() {
  // Tạo JSON mô phỏng theo cấu trúc WeatherAPI (rút gọn từ dữ liệu bạn đã gửi).
  final sample = {
    "location": {
      "name": "Tay Ninh",
      "country": "Vietnam",
      "tz_id": "Asia/Ho_Chi_Minh",
    },
    "current": {
      "temp_c": 26.2,
      "feelslike_c": 28.7,
      "humidity": 79,
      "wind_kph": 13.3,
      "uv": 0.0,
      "condition": {"text": "Clear"}
    },
    "forecast": {
      "forecastday": [
        {
          "date": "2025-08-22",
          "day": {
            "maxtemp_c": 32.2,
            "mintemp_c": 23.1,
            "daily_chance_of_rain": 85,
            "totalprecip_mm": 3.26,
            "maxwind_kph": 18.0
          },
          "hour": [
            {
              "time": "2025-08-22 06:00",
              "temp_c": 23.2,
              "feelslike_c": 25.5,
              "heatindex_c": 25.5,
              "humidity": 94,
              "wind_kph": 7.9,
              "gust_kph": 13.2,
              "uv": 0.0,
              "chance_of_rain": 0,
              "vis_km": 2.0,
              "cloud": 42,
              "condition": {"text": "Mist"}
            },
            {
              "time": "2025-08-22 07:00",
              "temp_c": 24.5,
              "feelslike_c": 26.9,
              "heatindex_c": 26.9,
              "humidity": 88,
              "wind_kph": 7.6,
              "gust_kph": 10.3,
              "uv": 0.8,
              "chance_of_rain": 0,
              "vis_km": 10.0,
              "cloud": 41,
              "condition": {"text": "Partly Cloudy"}
            },
            {
              "time": "2025-08-22 08:00",
              "temp_c": 26.1,
              "feelslike_c": 28.8,
              "heatindex_c": 28.8,
              "humidity": 82,
              "wind_kph": 9.4,
              "gust_kph": 11.4,
              "uv": 2.7,
              "chance_of_rain": 62,
              "vis_km": 10.0,
              "cloud": 79,
              "condition": {"text": "Patchy rain nearby"}
            },
            {
              "time": "2025-08-22 09:00",
              "temp_c": 27.7,
              "feelslike_c": 30.8,
              "heatindex_c": 30.8,
              "humidity": 73,
              "wind_kph": 10.8,
              "gust_kph": 12.4,
              "uv": 5.8,
              "chance_of_rain": 60,
              "vis_km": 10.0,
              "cloud": 87,
              "condition": {"text": "Patchy rain nearby"}
            },
            {
              "time": "2025-08-22 10:00",
              "temp_c": 29.3,
              "feelslike_c": 32.7,
              "heatindex_c": 32.7,
              "humidity": 65,
              "wind_kph": 10.4,
              "gust_kph": 12.0,
              "uv": 9.3,
              "chance_of_rain": 75,
              "vis_km": 10.0,
              "cloud": 94,
              "condition": {"text": "Patchy rain nearby"}
            }
          ]
        }
      ]
    }
  };

  final builder = WeatherPayloadBuilder(sample);
  final payload = builder.buildPayload();
  print(const JsonEncoder.withIndent('  ').convert(payload));
}
*/

// LƯU Ý:
// - Để dùng log10 đúng chuẩn, bạn nên import 'dart:math' as math;
//   rồi thay hàm log10 ở trên bằng: double log10(num x) => x <= 0 ? 0 : (math.log(x) / math.ln10);
//
// - Khi tích hợp thực tế, bạn có thể:
//   + Tính indices theo từng period nếu muốn chi tiết hơn,
//   + Điều chỉnh ngưỡng highlight (UV>=8, Rain>=70, Gust>=40, HeatIndex>=37),
//   + Áp rule "minVis sau 07:00" nếu muốn VFI phản ánh ban ngày tốt hơn,
//   + Thêm cache layer & unit tests.
