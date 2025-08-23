// lib/services/llm_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sunny_snuggles/core/env.dart';

class LlmService {
  late final GenerativeModel _model;

  LlmService({String modelName = 'gemini-1.5-flash'}) {
    _model = GenerativeModel(
      model: modelName,
      apiKey: Env.geminiApiKey,
      // safetySettings / systemInstruction có thể bổ sung sau
    );
  }

  /// Gọi 1-shot (không streaming)
  Future<String> analyzeWeather({
    required Map<String, dynamic> weatherJson,
    String? customPrompt,
    double temperature = 0.4,
    int? maxOutputTokens,
  }) async {
    final system = '''
Bạn là trợ lý phân tích thời tiết (analyst). 
Hãy tóm tắt ngắn gọn, nêu nhiệt độ, mưa/gió/độ ẩm, cảnh báo (nếu có), và khuyến nghị ngắn (mang áo mưa, tránh giờ mưa to, v.v.). 
Trả kết quả dạng gạch đầu dòng rõ ràng.
''';

    final user =
        customPrompt ??
        'Hãy phân tích JSON thời tiết sau và đưa ra bản tóm tắt dễ hiểu cho người dùng cuối.';

    final input = Content.multi([
      TextPart(system),
      TextPart(user),
      TextPart('DỮ LIỆU:'),
      TextPart(weatherJson.toString()),
    ]);

    final resp = await _model.generateContent(
      [input],
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxOutputTokens,
      ),
    );

    return resp.text?.trim() ?? '';
  }

  /// Streaming (tuỳ chọn dùng sau)
  Stream<String> analyzeWeatherStream({
    required Map<String, dynamic> weatherJson,
    String? customPrompt,
    double temperature = 0.4,
    int? maxOutputTokens,
  }) async* {
    final system = '''
Bạn là trợ lý phân tích thời tiết (analyst). 
Hãy tóm tắt ngắn gọn, nêu nhiệt độ, mưa/gió/độ ẩm, cảnh báo (nếu có), và khuyến nghị ngắn.
''';

    final user = customPrompt ?? 'Phân tích JSON thời tiết sau:';
    final input = Content.multi([
      TextPart(system),
      TextPart(user),
      TextPart(weatherJson.toString()),
    ]);

    final stream = _model.generateContentStream(
      [input],
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxOutputTokens,
      ),
    );

    await for (final chunk in stream) {
      if (chunk.text != null) yield chunk.text!;
    }
  }
}
