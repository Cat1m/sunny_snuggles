import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/prefs_service.dart';

/// Streak theo location (KISS). Key: `streak_<location>`
class StreakNotifier extends Notifier<int> {
  late PrefsService _prefs;
  late String _key;

  @override
  int build() {
    // Mặc định 0; PrefsService khởi tạo lazy trong init()
    return 0;
  }

  Future<void> init(PrefsService prefs, String location) async {
    _prefs = prefs;
    _key = 'streak_$location';
    final raw = _prefs.getJson(_key);
    state = raw == null ? 0 : int.tryParse(raw) ?? 0;
  }

  Future<void> set(int v) async {
    state = v;
    await _prefs.setJson(_key, '$v');
  }

  Future<void> reset() => set(0);
  Future<void> increase() => set(state + 1);
}

final prefsServiceProvider = FutureProvider<PrefsService>((ref) async {
  return PrefsService.create();
});

final streakNotifierProvider = NotifierProvider<StreakNotifier, int>(
  StreakNotifier.new,
);
