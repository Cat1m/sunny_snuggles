import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../utils/date_utils.dart';
import '../../weather/model/weather_day.dart';
import '../model/quiz_enums.dart';
import '../model/quiz_mapper.dart';
import '../model/user_guess.dart';
import '../viewmodel/streak_provider.dart';

/// Key: "<yyyy-MM-dd>_<location>"
String _guessKey(DateTime targetDate, String location) =>
    '${AppDateUtils.ymd(targetDate)}_$location';

class GameService {
  GameService(this._ref, this._prefs);
  final Ref _ref;
  final PrefsService _prefs;

  /// Lưu đoán cho ngày mục tiêu (thường = ngày mai)
  Future<void> saveGuess({
    required String location,
    required DateTime targetDate,
    required UserGuess guess,
  }) async {
    final key = _guessKey(targetDate, location);
    await _prefs.setJson(key, jsonEncode(guess.toJson()));
  }

  /// Đọc đoán (nếu có) cho ngày mục tiêu
  UserGuess? getGuess({
    required String location,
    required DateTime targetDate,
  }) {
    final key = _guessKey(targetDate, location);
    final raw = _prefs.getJson(key);
    if (raw == null) return null;
    return UserGuess.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Xoá đoán sau khi đã chấm (giữ kho clean)
  Future<void> clearGuess({
    required String location,
    required DateTime targetDate,
  }) async {
    final key = _guessKey(targetDate, location);
    await _prefs.remove(key);
  }

  /// So sánh guess với đáp án ngày thực tế (WeatherDay) → đúng toàn bộ?
  bool isAllCorrect({required UserGuess guess, required WeatherDay answerDay}) {
    final bands = QuizMapper.toBands(answerDay);
    final uvOk =
        (guess.uv == null && bands.uv == null) ||
        (guess.uv != null && bands.uv != null && guess.uv == bands.uv);

    return guess.temp == bands.temp &&
        guess.rain == bands.rain &&
        guess.wind == bands.wind &&
        uvOk;
  }

  /// Chấm điểm cho "hôm nay" dựa trên forecast.today hoặc history-day,
  /// rồi cập nhật streak:
  ///   - Đúng toàn bộ → +1
  ///   - Sai → reset = 0
  /// Trả về true nếu đúng, false nếu sai, null nếu không có guess để chấm.
  Future<bool?> revealAndUpdateStreak({
    required String location,
    required WeatherDay todayAnswerDay,
  }) async {
    // Target date hôm nay
    final targetDate = todayAnswerDay.date;

    // Lấy guess user đã lưu cho NGÀY HÔM NAY (đã đoán từ hôm qua)
    final guess = getGuess(location: location, targetDate: targetDate);
    if (guess == null) {
      return null; // chưa có gì để chấm
    }

    final ok = isAllCorrect(guess: guess, answerDay: todayAnswerDay);

    // Đảm bảo StreakNotifier đã init trước đó
    final streak = _ref.read(streakNotifierProvider.notifier);
    if (ok) {
      await streak.increase();
    } else {
      await streak.reset();
    }

    // Xoá đoán đã dùng
    await clearGuess(location: location, targetDate: targetDate);

    return ok;
  }
}

final gameServiceProvider = FutureProvider<GameService>((ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  return GameService(ref, prefs);
});
