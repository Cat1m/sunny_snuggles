import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sunny_snuggles/features/game/viewmodel/streak_provider.dart';
import 'package:sunny_snuggles/features/weather/llm/analyst_provider.dart';
import 'package:sunny_snuggles/features/weather/model/weather_bundle.dart';
import 'package:sunny_snuggles/features/weather/viewmodel/weather_provider.dart';
import 'package:sunny_snuggles/ui/pages/cute_header.dart';
import 'package:sunny_snuggles/ui/pages/detail_screen.dart';
import 'package:sunny_snuggles/ui/pages/location_input.dart';
import 'package:sunny_snuggles/ui/pages/theme/weather_color_palette.dart';
import 'package:sunny_snuggles/ui/pages/tomorrow_screen.dart';

// ⚠️ ĐÃ GỠ import thừa:
// - action_buttons_row.dart
// - cute_quiz_section.dart
// - floating_location_card.dart
// - tomorrow_preview_card.dart
// - game_usecases.dart
// - quiz_state.dart

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWeather = ref.watch(weatherBundleCurrentProvider);
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
    final busy = ref.watch(isRefreshingProvider); // <-- đọc trạng thái bận

    Future<void> doRefresh() async {
      if (ref.read(isRefreshingProvider)) return;
      ref.read(isRefreshingProvider.notifier).state = true;
      try {
        await ref.refresh(weatherBundleCurrentProvider.future);
        // (tuỳ chọn) HapticFeedback.mediumImpact();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Làm mới thất bại, thử lại nhé!')),
          );
        }
      } finally {
        ref.read(isRefreshingProvider.notifier).state = false;
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: WeatherColorPalette.getGradient(condition),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: doRefresh,
          edgeOffset: 12,
          displacement: 36,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(), // cho cảm giác mượt
            ),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _FadeSlideIn(
                      delayMs: 40,
                      child: CuteHeader(streak: streak, condition: condition),
                    ),
                  ],
                ),
              ),

              // Phần còn lại fill toàn màn hình (để nội dung ngắn vẫn “kéo” được)
              SliverFillRemaining(
                hasScrollBody: false, // rất quan trọng để cột “dãn” tới đáy
                child: Column(
                  children: [
                    // Bubble giữa màn
                    Expanded(
                      child: Center(
                        child: _TempBubble(
                          temperature: bundle.current.tempC.toInt(),
                          busy: busy,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(bundle: bundle),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    _FadeSlideIn(delayMs: 90, child: _AnalystCard()),

                    const SizedBox(height: 8),
                    // Bottom actions (animate)
                    _FadeSlideIn(
                      delayMs: 120,
                      child: _BottomActions(bundle: bundle),
                    ),
                  ],
                ),
              ),
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
              const LocationInput(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(weatherBundleCurrentProvider),
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
    if (text.contains('rain') ||
        text.contains('drizzle') ||
        text.contains('shower')) {
      return WeatherCondition.rainy;
    } else if (text.contains('cloud') ||
        text.contains('overcast') ||
        text.contains('partly')) {
      return WeatherCondition.cloudy;
    } else if (text.contains('snow') ||
        text.contains('sleet') ||
        text.contains('blizzard')) {
      return WeatherCondition.snowy;
    } else if (text.contains('storm') ||
        text.contains('thunder') ||
        text.contains('lightning')) {
      return WeatherCondition.stormy;
    } else {
      return WeatherCondition.sunny;
    }
  }
}

class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _BottomActions extends ConsumerStatefulWidget {
  const _BottomActions({required this.bundle});
  final WeatherBundle bundle;

  @override
  ConsumerState<_BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends ConsumerState<_BottomActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

    // delay nhẹ cho mượt
    Future.microtask(() => _ac.forward());
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final isRefreshing = ref.read(isRefreshingProvider);
    if (isRefreshing) return;

    HapticFeedback.selectionClick();
    ref.read(isRefreshingProvider.notifier).state = true;
    try {
      // Cách 2 (tùy chọn): invalidate rồi chờ đọc lại
      ref.invalidate(weatherBundleCurrentProvider);
      await ref.read(weatherBundleCurrentProvider.future);
    } catch (_) {
      // có thể show SnackBar nếu cần
    } finally {
      if (mounted) {
        ref.read(isRefreshingProvider.notifier).state = false;
      }
    }
  }

  void _goTomorrow() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TomorrowScreen(bundle: widget.bundle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(isRefreshingProvider);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        child: SlideTransition(
          position: _slide,
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : _refresh,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(busy ? 'Đang làm mới...' : 'Làm mới'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _goTomorrow,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Hôm sau'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bubble nhiệt độ lớn (tối giản – chưa animation, sẽ nâng ở Bước 2)
// Bubble nhiệt độ phiên bản Pro
// Bubble nhiệt độ – Pro v2

class _TempBubble extends StatefulWidget {
  const _TempBubble({
    required this.temperature,
    required this.onTap,
    this.busy = false,
  });

  final int temperature;
  final VoidCallback onTap;
  final bool busy;

  @override
  State<_TempBubble> createState() => _TempBubbleState();
}

class _TempBubbleState extends State<_TempBubble>
    with TickerProviderStateMixin {
  late final AnimationController _appearController;
  late final AnimationController _flowController;
  late final AnimationController _breatheController;
  late final AnimationController _cloudController;
  late final AnimationController _rippleController;

  late final Animation<double> _appearAnimation;
  late final Animation<double> _flowAnimation;
  late final Animation<double> _breatheAnimation;
  late final Animation<double> _cloudAnimation;
  late final Animation<double> _rippleAnimation;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Appear with gentle bounce
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _appearAnimation = CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOutBack,
    );

    // Liquid flow animation - slow morphing
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    _flowAnimation = CurvedAnimation(
      parent: _flowController,
      curve: Curves.easeInOut,
    );

    // Gentle breathing effect
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _breatheAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // Cloud-like swirl animation
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    _cloudAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cloudController, curve: Curves.linear));

    // Water ripple effect
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    );
  }

  void _startAnimations() {
    _appearController.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _flowController.repeat(reverse: true);
        _breatheController.repeat(reverse: true);
        _cloudController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _appearController.dispose();
    _flowController.dispose();
    _breatheController.dispose();
    _cloudController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.busy) return;

    HapticFeedback.lightImpact();
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    final base = shortest * 0.65;
    final size = base.clamp(260.0, shortest >= 700 ? 450.0 : 400.0);

    return Semantics(
      label:
          'Current temperature ${widget.temperature} degrees. Tap for details.',
      button: true,
      child: Hero(
        tag: 'temp-bubble',
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_appearAnimation, _breatheAnimation]),
            builder: (context, child) {
              return AnimatedScale(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                scale: (_pressed ? 0.97 : 1.0) * _breatheAnimation.value,
                child: ScaleTransition(
                  scale: _appearAnimation,
                  child: _buildLiquidBubble(size),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidBubble(double size) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.busy ? null : _onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        splashColor: _getWeatherColor(widget.temperature).withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildSoftShadow(size),
              _buildLiquidBase(size),
              _buildFlowingGradient(size),
              _buildCloudSwirls(size),
              _buildGlassRefraction(size),
              _buildTemperatureText(size),
              _buildWaterRipples(size),
              _buildBusyOverlay(size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoftShadow(double size) {
    final weatherColor = _getWeatherColor(widget.temperature);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // Soft main shadow like water drop
          BoxShadow(
            color: weatherColor.withOpacity(0.15),
            blurRadius: size * 0.12,
            spreadRadius: 2,
            offset: Offset(0, size * 0.06),
          ),
          // Ambient light shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: size * 0.08,
            spreadRadius: -4,
            offset: Offset(0, size * 0.02),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidBase(double size) {
    final weatherColor = _getWeatherColor(widget.temperature);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.1, -0.2),
          radius: 1.0,
          colors: [
            // Center - clear like water
            Colors.white.withOpacity(0.9),
            // Mid - slight tint
            weatherColor.withOpacity(0.08),
            Colors.white.withOpacity(0.6),
            // Edge - more defined
            weatherColor.withOpacity(0.12),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildFlowingGradient(double size) {
    return AnimatedBuilder(
      animation: _flowAnimation,
      builder: (context, child) {
        final weatherColor = _getWeatherColor(widget.temperature);
        final flow = _flowAnimation.value;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(
                math.cos(flow * 2 * math.pi) * 0.3,
                math.sin(flow * 2 * math.pi) * 0.2,
              ),
              radius: 0.8 + (flow * 0.4),
              colors: [
                weatherColor.withOpacity(0.05),
                weatherColor.withOpacity(0.15),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCloudSwirls(double size) {
    return AnimatedBuilder(
      animation: _cloudAnimation,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // First swirl
            Transform.rotate(
              angle: _cloudAnimation.value * 2 * math.pi * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.15, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Counter swirl for cloud effect
            Transform.rotate(
              angle: -_cloudAnimation.value * 2 * math.pi * 0.2,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      _getWeatherColor(widget.temperature).withOpacity(0.08),
                      Colors.transparent,
                      Colors.white.withOpacity(0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassRefraction(double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.3)),
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.transparent,
              Colors.white.withOpacity(0.1),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureText(double size) {
    final weatherColor = _getWeatherColor(widget.temperature);

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          '${widget.temperature}°',
          key: ValueKey(widget.temperature),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (size * 0.42).clamp(65.0, 135.0),
            fontWeight: FontWeight.w800,
            height: 0.9,
            letterSpacing: -1.5,
            foreground: Paint()
              ..shader =
                  LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      weatherColor.withOpacity(0.8),
                      weatherColor,
                      weatherColor.withOpacity(0.9),
                    ],
                  ).createShader(
                    Rect.fromCenter(
                      center: Offset(size / 2, size / 2),
                      width: size * 0.6,
                      height: size * 0.6,
                    ),
                  ),
            shadows: [
              // Soft text shadow like through water
              Shadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
              // Subtle glow
              Shadow(
                color: weatherColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterRipples(double size) {
    return AnimatedBuilder(
      animation: _rippleAnimation,
      builder: (context, child) {
        if (_rippleAnimation.value == 0) return const SizedBox.shrink();

        final rippleOpacity = (1 - _rippleAnimation.value) * 0.4;
        final rippleScale = 0.9 + (_rippleAnimation.value * 0.3);

        return Transform.scale(
          scale: rippleScale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 2,
                color: _getWeatherColor(
                  widget.temperature,
                ).withOpacity(rippleOpacity),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusyOverlay(double size) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.busy ? 1 : 0,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.5),
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.1,
                height: size * 0.1,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(
                    _getWeatherColor(widget.temperature).withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getWeatherColor(int temperature) {
    // Weather-inspired colors - softer, more natural
    if (temperature <= 5) {
      return const Color(0xFF7DD3FC); // Sky blue - freezing
    } else if (temperature <= 15) {
      return const Color(0xFF38BDF8); // Light blue - cold
    } else if (temperature <= 22) {
      return const Color(0xFF06B6D4); // Cyan - cool
    } else if (temperature <= 28) {
      return const Color(0xFF10B981); // Emerald - comfortable
    } else if (temperature <= 33) {
      return const Color(0xFFFBBF24); // Yellow - warm
    } else {
      return const Color(0xFFF87171); // Rose - hot
    }
  }
}

/// Gradient chữ theo nhiệt độ (°C)
Gradient _tempGradient(int t) {
  // map đơn giản: lạnh <=15 → xanh; mát 16–27 → xanh→vàng; nóng >=28 → cam→đỏ
  if (t <= 15) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)], // cyan → sky
    );
  } else if (t <= 27) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF06B6D4), Color(0xFFF59E0B)], // teal → amber
      stops: [0.0, 1.0],
    );
  } else {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF8A00), Color(0xFFFF3D3D)], // orange → red
    );
  }
}

class _AnalystCard extends ConsumerWidget {
  const _AnalystCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weatherAnalystTodayProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: async.when(
        loading: () => const _GlassCard(
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 12),
              Expanded(child: _ShimmerLine()),
            ],
          ),
        ),
        error: (e, st) => _GlassCard(
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Không tạo được phân tích. Thử lại nhé!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Thử lại',
                onPressed: () => ref.refresh(weatherAnalystTodayProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        data: (text) => _GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text.isEmpty ? 'Không có phân tích phù hợp.' : text,
                  style: const TextStyle(height: 1.3, fontSize: 14.5),
                ),
              ),
              IconButton(
                tooltip: 'Làm mới phân tích',
                onPressed: () => ref.refresh(weatherAnalystTodayProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatefulWidget {
  const _ShimmerLine();
  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.30),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
