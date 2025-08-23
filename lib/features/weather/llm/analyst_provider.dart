import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sunny_snuggles/core/env.dart';
import 'package:sunny_snuggles/features/weather/llm/llm_prompt.dart';
import 'package:sunny_snuggles/features/weather/viewmodel/weather_provider.dart';
import 'package:sunny_snuggles/features/weather/repository/weather_repository.dart';

final llmModelProvider = Provider<GenerativeModel>((ref) {
  return GenerativeModel(model: 'gemini-1.5-flash', apiKey: Env.geminiApiKey);
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository();
});

/// Analyst hôm nay – lấy payload từ repo (Dio) và gọi Gemini với WeatherPrompts
final weatherAnalystTodayProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  // Watch bundle để ăn refresh
  await ref.watch(weatherBundleCurrentProvider.future);

  // Lấy payload hôm nay từ repo
  final repo = ref.read(weatherRepositoryProvider);
  final payload = await repo.fetchTodayPayloadForCurrentLocation();

  // Prompt từ WeatherPrompts
  final system = WeatherPrompts.systemFromPayload(payload);
  final user = WeatherPrompts.userFromPayload(payload);

  // Gọi Gemini
  final model = ref.read(llmModelProvider);
  final resp = await model.generateContent(
    [Content.text(system), Content.text(user)],
    generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: 300),
  );

  return (resp.text ?? '').trim();
});
