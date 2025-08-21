import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunny_snuggles/features/game/model/quiz_enums.dart';
import 'package:sunny_snuggles/features/game/viewmodel/game_usecases.dart';
import 'package:sunny_snuggles/features/game/viewmodel/quiz_state.dart';
import 'package:sunny_snuggles/features/game/viewmodel/streak_provider.dart';
import 'package:sunny_snuggles/features/weather/model/weather_bundle.dart';
import 'package:sunny_snuggles/features/weather/viewmodel/weather_provider.dart';
import 'package:sunny_snuggles/ui/pages/action_buttons_row.dart';
import 'package:sunny_snuggles/ui/pages/cute_quiz_section.dart';
import 'package:sunny_snuggles/ui/pages/tomorrow_preview_card.dart';
import 'package:sunny_snuggles/ui/pages/location_input.dart';
import 'package:sunny_snuggles/ui/pages/theme/weather_color_palette.dart';

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
              TomorrowPreviewCard(bundle: bundle),
              const SizedBox(height: 24),
              CuteQuizSection(),
              const SizedBox(height: 20),
              ActionButtonsRow(),
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
              LocationInput(),
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
        content: LocationInput(),
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
