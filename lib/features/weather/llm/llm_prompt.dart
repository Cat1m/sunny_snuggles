import 'dart:convert';

class WeatherPrompts {
  static String systemFromPayload(Map<String, dynamic> payload) =>
      '''
Bạn là trợ lý thời tiết nói tiếng Việt, viết tối đa ${payload["style"]["max_sentences"]} câu, thân thiện, dễ hiểu.
- Không mô tả hai hiện tượng như xảy ra đồng thời nếu relations.uv_rain_overlap = false.
- Luôn nêu rõ khung giờ: "sáng/chiều/tối" hoặc "HH:MM–HH:MM".
- Nếu style.include_tip = true, thêm 1 mẹo ngắn.
''';

  static String userFromPayload(Map<String, dynamic> payload) =>
      '''
Dưới đây là dữ liệu đã rút gọn (JSON). Hãy viết tóm tắt theo yêu cầu:
```json
${const JsonEncoder.withIndent('  ').convert(payload)}
```
''';
}
