import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/quiz_enums.dart';
import '../model/user_guess.dart';

class QuizState {
  final TempBand? temp;
  final RainChoice? rain;
  final WindBand? wind;
  final UvBand? uv; // optional

  const QuizState({this.temp, this.rain, this.wind, this.uv});

  bool get isComplete =>
      temp != null && rain != null && wind != null; // uv optional

  UserGuess toGuess() =>
      UserGuess(temp: temp!, rain: rain!, wind: wind!, uv: uv);

  QuizState copyWith({
    TempBand? temp,
    RainChoice? rain,
    WindBand? wind,
    UvBand? uv,
  }) {
    return QuizState(
      temp: temp ?? this.temp,
      rain: rain ?? this.rain,
      wind: wind ?? this.wind,
      uv: uv ?? this.uv,
    );
  }

  static const empty = QuizState();
}

class QuizStateNotifier extends StateNotifier<QuizState> {
  QuizStateNotifier() : super(QuizState.empty);

  void selectTemp(TempBand v) => state = state.copyWith(temp: v);
  void selectRain(RainChoice v) => state = state.copyWith(rain: v);
  void selectWind(WindBand v) => state = state.copyWith(wind: v);
  void selectUv(UvBand? v) => state = state.copyWith(uv: v);

  void reset() => state = QuizState.empty;
}

final quizStateProvider = StateNotifierProvider<QuizStateNotifier, QuizState>((
  ref,
) {
  return QuizStateNotifier();
});
