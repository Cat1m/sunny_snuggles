import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunny_snuggles/features/game/model/quiz_enums.dart';
import 'package:sunny_snuggles/features/game/viewmodel/quiz_state.dart';

class CuteQuizSection extends ConsumerWidget {
  const CuteQuizSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizStateProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.quiz, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tomorrow\'s Weather Quiz! 🔮',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _QuizQuestion(
            emoji: '🌡️',
            question: 'Temperature?',
            children: [
              _CuteChoice(
                value: TempBand.lt20,
                groupValue: quiz.temp,
                onChanged: (v) =>
                    ref.read(quizStateProvider.notifier).selectTemp(v),
                label: '< 20°C',
                emoji: '🥶',
              ),
              _CuteChoice(
                value: TempBand.t20to29,
                groupValue: quiz.temp,
                onChanged: (v) =>
                    ref.read(quizStateProvider.notifier).selectTemp(v),
                label: '20-29°C',
                emoji: '😌',
              ),
              _CuteChoice(
                value: TempBand.gte30,
                groupValue: quiz.temp,
                onChanged: (v) =>
                    ref.read(quizStateProvider.notifier).selectTemp(v),
                label: '≥ 30°C',
                emoji: '🥵',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _QuizQuestion(
            emoji: '🌧️',
            question: 'Rain?',
            children: [
              _CuteChoice(
                value: RainChoice.yes,
                groupValue: quiz.rain,
                onChanged: (v) =>
                    ref.read(quizStateProvider.notifier).selectRain(v),
                label: 'Yes',
                emoji: '☔',
              ),
              _CuteChoice(
                value: RainChoice.no,
                groupValue: quiz.rain,
                onChanged: (v) =>
                    ref.read(quizStateProvider.notifier).selectRain(v),
                label: 'No',
                emoji: '☀️',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _QuizQuestion(
            emoji: '💨',
            question: 'Wind?',
            children: [
              _CuteChoice(
                value: WindBand.calm,
                groupValue: quiz.wind,
                onChanged: (v) =>
                    ref.read(quizStateProvider.notifier).selectWind(v),
                label: 'Calm',
                emoji: '😴',
              ),
              _CuteChoice(
                value: WindBand.moderate,
                groupValue: quiz.wind,
                onChanged: (v) =>
                    ref.read(quizStateProvider.notifier).selectWind(v),
                label: 'Moderate',
                emoji: '🍃',
              ),
              _CuteChoice(
                value: WindBand.windy,
                groupValue: quiz.wind,
                onChanged: (v) =>
                    ref.read(quizStateProvider.notifier).selectWind(v),
                label: 'Windy',
                emoji: '💨',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizQuestion extends StatelessWidget {
  const _QuizQuestion({
    required this.emoji,
    required this.question,
    required this.children,
  });

  final String emoji;
  final String question;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$emoji $question',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _CuteChoice<T> extends StatelessWidget {
  const _CuteChoice({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    required this.emoji,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T> onChanged;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667eea).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF667eea)
                    : const Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
