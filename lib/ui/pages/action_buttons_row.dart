import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunny_snuggles/features/game/viewmodel/game_usecases.dart';
import 'package:sunny_snuggles/features/game/viewmodel/quiz_state.dart';

class ActionButtonsRow extends ConsumerWidget {
  const ActionButtonsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _saveGuess(context, ref),
                icon: const Icon(Icons.save_alt, color: Colors.white),
                label: const Text(
                  'Save Guess',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _revealResult(context, ref),
              icon: const Icon(Icons.visibility),
              label: const Text(
                'Reveal Today',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                side: const BorderSide(color: Color(0xFF667eea), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveGuess(BuildContext context, WidgetRef ref) async {
    final quiz = ref.watch(quizStateProvider);
    try {
      if (!quiz.isComplete) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chưa chọn đủ: Temp, Rain, Wind (UV tuỳ chọn).'),
            ),
          );
        }
        return;
      }
      await ref.read(saveGuessForTomorrowProvider.future);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã lưu dự đoán')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lưu đoán thất bại: $e')));
      }
    }
  }

  void _revealResult(BuildContext context, WidgetRef ref) async {
    try {
      final res = await ref.read(revealTodayResultProvider.future);
      if (!context.mounted) return;
      if (res == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có dự đoán cho hôm nay để chấm.')),
        );
      } else if (res == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Chính xác toàn bộ! +1 streak')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai rồi 😢 Streak đã reset.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reveal lỗi: $e')));
      }
    }
  }
}
