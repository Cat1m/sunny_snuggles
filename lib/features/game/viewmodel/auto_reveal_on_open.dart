import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_usecases.dart';

/// Kích hoạt auto reveal (nếu có) khi màn mở.
/// Idempotent nhờ revealTodayResultProvider.
final autoRevealOnOpenProvider = FutureProvider<void>((ref) async {
  try {
    await ref.watch(revealTodayResultProvider.future);
  } catch (_) {
    // KISS: ignore lỗi mạng ở đây, UI vẫn hoạt động bình thường
  }
});
