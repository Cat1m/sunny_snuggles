// lib/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'WEATHER_API_KEY')
  static String weatherApiKey = _Env.weatherApiKey;

  @EnviedField(varName: 'WEATHER_BASE_URL')
  static String weatherBaseUrl = _Env.weatherBaseUrl;

  @EnviedField(varName: 'GEMINI_API_KEY')
  static String geminiApiKey = _Env.geminiApiKey;
}
