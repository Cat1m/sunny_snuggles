import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env.dart';
import 'ui/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Cảnh báo sớm nếu chưa truyền API key
  assert(
    Env.weatherApiKey.isNotEmpty,
    'Bạn chưa cấu hình WEATHER_API_KEY trong .env',
  );

  runApp(const ProviderScope(child: SunnySnugglesApp()));
}

class SunnySnugglesApp extends StatelessWidget {
  const SunnySnugglesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunny Snuggles ☀️',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
