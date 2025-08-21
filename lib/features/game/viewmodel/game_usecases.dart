import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../weather/viewmodel/weather_provider.dart';
import '../../weather/model/weather_bundle.dart';
import '../../../utils/location_key_utils.dart';
import '../service/game_service.dart';
import '../viewmodel/quiz_state.dart';
import '../viewmodel/streak_provider.dart';
import '../../../core/storage/prefs_service.dart';

/// Lưu đoán cho NGÀY MAI theo bundle & quizState hiện tại, dùng locationKey chuẩn hoá
final saveGuessForTomorrowProvider = FutureProvider<void>((ref) async {
  final game = await ref.watch(gameServiceProvider.future);
  final bundle = await ref.watch(weatherBundleCurrentProvider.future);
  final qs = ref.read(quizStateProvider);

  if (!qs.isComplete) {
    throw StateError('Bạn chưa chọn đủ mục (UV là optional).');
  }

  final locationKey = locationKeyFromBundle(bundle);
  await game.saveGuess(
    location: locationKey,
    targetDate: bundle.tomorrow.date,
    guess: qs.toGuess(),
  );
});

/// Chấm điểm cho HÔM NAY một cách idempotent:
/// - Nếu đã chấm hôm nay rồi → trả null (không làm gì).
/// - Nếu có guess cho hôm nay → chấm & cập nhật streak.
/// - Nếu không có guess → trả null.
/// Trả về: true = đúng toàn bộ, false = sai, null = không hành động.
final revealTodayResultProvider = FutureProvider<bool?>((ref) async {
  final game = await ref.watch(gameServiceProvider.future);
  final bundle = await ref.watch(weatherBundleCurrentProvider.future);
  final prefs = await ref.watch(prefsServiceProvider.future);

  final locationKey = locationKeyFromBundle(bundle);
  final todayDate = bundle.today.date;

  // Đảm bảo streak đã init theo locationKey
  await ref.read(streakNotifierProvider.notifier).init(prefs, locationKey);

  // Chống chấm lặp
  final revealKey =
      'revealed_${todayDate.toIso8601String().split("T").first}_$locationKey';
  final revealed = prefs.getJson(revealKey);
  if (revealed == '1') {
    return null; // đã reveal hôm nay
  }

  final res = await game.revealAndUpdateStreak(
    location: locationKey,
    todayAnswerDay: bundle.today,
  );

  // Đánh dấu đã reveal nếu có hành động (kể cả đúng/sai)
  if (res != null) {
    await prefs.setJson(revealKey, '1');
  }
  return res;
});
