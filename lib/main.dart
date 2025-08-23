import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sunny_snuggles/core/app_theme.dart';
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
      theme: AppTheme.light, // dùng theme light đã định nghĩa
      darkTheme: AppTheme.dark, // dark mode
      themeMode: ThemeMode.light, // hoặc ThemeMode.system nếu muốn tự động
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
