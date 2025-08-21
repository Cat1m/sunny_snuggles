import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunny_snuggles/features/game/model/quiz_enums.dart';
import 'package:sunny_snuggles/features/game/viewmodel/game_usecases.dart';
import 'package:sunny_snuggles/features/game/viewmodel/quiz_state.dart';
import 'package:sunny_snuggles/features/game/viewmodel/streak_provider.dart';
import 'package:sunny_snuggles/features/weather/model/weather_bundle.dart';
import 'package:sunny_snuggles/features/weather/viewmodel/weather_provider.dart';
// Import các providers và models như cũ...

class SunnySnugglesApp extends StatelessWidget {
  const SunnySnugglesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunny Snuggles ☀️',
      theme: _buildDynamicTheme(WeatherCondition.sunny), // Dynamic theme
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }

  // Dynamic theme based on weather
  ThemeData _buildDynamicTheme(WeatherCondition condition) {
    final colorPalette = WeatherColorPalette.getColors(condition);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPalette.primary,
        brightness: Brightness.light,
        secondary: colorPalette.secondary,
        surface: colorPalette.background,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.9),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWeather = ref.watch(weatherBundleProvider);
    final streak = ref.watch(streakNotifierProvider);

    return Scaffold(
      body: asyncWeather.when(
        data: (bundle) => _buildWeatherView(context, ref, bundle, streak),
        loading: () => _buildLoadingView(context),
        error: (e, st) => _buildErrorView(context, ref, e),
      ),
    );
  }

  Widget _buildWeatherView(
    BuildContext context,
    WidgetRef ref,
    WeatherBundle bundle,
    int streak,
  ) {
    final condition = _getWeatherCondition(bundle.current.conditionText);

    return Container(
      decoration: BoxDecoration(
        gradient: WeatherColorPalette.getGradient(condition),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _CuteHeader(streak: streak, condition: condition),
              const SizedBox(height: 20),
              _FloatingLocationCard(bundle: bundle),
              const SizedBox(height: 24),
              _MainWeatherCard(bundle: bundle),
              const SizedBox(height: 16),
              _TomorrowPreviewCard(bundle: bundle),
              const SizedBox(height: 24),
              _CuteQuizSection(),
              const SizedBox(height: 20),
              _ActionButtonsRow(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny, size: 60, color: Colors.white),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Getting weather info... ☀️',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, dynamic error) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFCDD2), Color(0xFFF8BBD9)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 80, color: Color(0xFFE91E63)),
              const SizedBox(height: 24),
              const Text(
                'Oops! Weather got shy 😊',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF880E4F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Let\'s try a different location!',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _LocationInput(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(weatherBundleProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  WeatherCondition _getWeatherCondition(String conditionText) {
    final text = conditionText.toLowerCase();
    if (text.contains('rain') || text.contains('drizzle')) {
      return WeatherCondition.rainy;
    } else if (text.contains('cloud') || text.contains('overcast')) {
      return WeatherCondition.cloudy;
    } else if (text.contains('snow')) {
      return WeatherCondition.snowy;
    } else if (text.contains('storm') || text.contains('thunder')) {
      return WeatherCondition.stormy;
    } else {
      return WeatherCondition.sunny;
    }
  }
}

class _CuteHeader extends StatelessWidget {
  const _CuteHeader({required this.streak, required this.condition});

  final int streak;
  final WeatherCondition condition;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getWeatherEmoji(condition),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sunny Snuggles',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Your weather buddy! 🤗',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _StreakBadge(streak: streak),
        ],
      ),
    );
  }

  String _getWeatherEmoji(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return '☀️';
      case WeatherCondition.cloudy:
        return '☁️';
      case WeatherCondition.rainy:
        return '🌧️';
      case WeatherCondition.snowy:
        return '❄️';
      case WeatherCondition.stormy:
        return '⛈️';
    }
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingLocationCard extends ConsumerWidget {
  const _FloatingLocationCard({required this.bundle});
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${bundle.current.locationName}, ${bundle.current.country}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showLocationDialog(context, ref),
                icon: Icon(
                  Icons.edit,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Location'),
        content: _LocationInput(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.refresh(weatherBundleProvider);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _MainWeatherCard extends StatelessWidget {
  const _MainWeatherCard({required this.bundle});
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    final current = bundle.current;
    final today = bundle.today;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${current.tempC.toInt()}°',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Image.network(
                    _fixIconUrl(current.conditionIcon),
                    width: 64,
                    height: 64,
                  ),
                  Text(
                    current.conditionText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _WeatherStats(current: current, today: today),
        ],
      ),
    );
  }

  String _fixIconUrl(String icon) =>
      icon.startsWith('//') ? 'https:$icon' : icon;
}

class _WeatherStats extends StatelessWidget {
  const _WeatherStats({required this.current, required this.today});

  final current;
  final today;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          icon: Icons.thermostat,
          label: 'High/Low',
          value: '${today.maxTempC.toInt()}°/${today.minTempC.toInt()}°',
          color: const Color(0xFFFF6B35),
        ),
        _StatItem(
          icon: Icons.air,
          label: 'Wind',
          value: '${current.windKph.toInt()} km/h',
          color: const Color(0xFF42A5F5),
        ),
        if (current.uv != null)
          _StatItem(
            icon: Icons.wb_sunny,
            label: 'UV Index',
            value: current.uv!.toInt().toString(),
            color: const Color(0xFFFFA726),
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C2C2C),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TomorrowPreviewCard extends StatelessWidget {
  const _TomorrowPreviewCard({required this.bundle});
  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    final tomorrow = bundle.tomorrow;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.8),
            const Color(0xFF764ba2).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.network(
              _fixIconUrl(tomorrow.conditionIcon),
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tomorrow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${tomorrow.conditionText} • ${tomorrow.maxTempC.toInt()}°C',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  String _fixIconUrl(String icon) =>
      icon.startsWith('//') ? 'https:$icon' : icon;
}

class _CuteQuizSection extends ConsumerWidget {
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

class _ActionButtonsRow extends ConsumerWidget {
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

// Color Palette System
enum WeatherCondition { sunny, cloudy, rainy, snowy, stormy }

class WeatherColorPalette {
  final Color primary;
  final Color secondary;
  final Color background;
  final List<Color> gradientColors;

  const WeatherColorPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.gradientColors,
  });

  static WeatherColorPalette getColors(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return const WeatherColorPalette(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFFFFB74D),
          background: Color(0xFFFFF3E0),
          gradientColors: [
            Color(0xFFFFE082),
            Color(0xFFFFB74D),
            Color(0xFFFF8A65),
          ],
        );
      case WeatherCondition.cloudy:
        return const WeatherColorPalette(
          primary: Color(0xFF90A4AE),
          secondary: Color(0xFFB0BEC5),
          background: Color(0xFFECEFF1),
          gradientColors: [
            Color(0xFFB0BEC5),
            Color(0xFF90A4AE),
            Color(0xFF78909C),
          ],
        );
      case WeatherCondition.rainy:
        return const WeatherColorPalette(
          primary: Color(0xFF42A5F5),
          secondary: Color(0xFF64B5F6),
          background: Color(0xFFE3F2FD),
          gradientColors: [
            Color(0xFF81C784),
            Color(0xFF42A5F5),
            Color(0xFF1976D2),
          ],
        );
      case WeatherCondition.snowy:
        return const WeatherColorPalette(
          primary: Color(0xFFE1F5FE),
          secondary: Color(0xFFB3E5FC),
          background: Color(0xFFF0F8FF),
          gradientColors: [
            Color(0xFFE1F5FE),
            Color(0xFFB3E5FC),
            Color(0xFF81D4FA),
          ],
        );
      case WeatherCondition.stormy:
        return const WeatherColorPalette(
          primary: Color(0xFF5C6BC0),
          secondary: Color(0xFF7986CB),
          background: Color(0xFFE8EAF6),
          gradientColors: [
            Color(0xFF5C6BC0),
            Color(0xFF3F51B5),
            Color(0xFF303F9F),
          ],
        );
    }
  }

  static LinearGradient getGradient(WeatherCondition condition) {
    final colors = getColors(condition).gradientColors;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}

// Location Input Widget
class _LocationInput extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locationProvider);
    final controller = TextEditingController(text: loc);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Enter city name or coordinates...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Get current location logic
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onSubmitted: (val) {
          final v = val.trim();
          if (v.isNotEmpty) {
            ref.read(locationProvider.notifier).state = v;
            ref.refresh(weatherBundleProvider);
          }
        },
      ),
    );
  }
}
