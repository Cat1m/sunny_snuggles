import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sunny_snuggles/features/game/viewmodel/streak_provider.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _appear;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _appear = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: 44% cạnh ngắn, clamp 180–260
    final shortest = MediaQuery.of(context).size.shortestSide;
    final size =
        shortest.clamp(180.0, 260.0) * 0.44 * (shortest >= 600 ? 1.4 : 1.0);
    final baseColor = const Color(0xFF0F172A); // slate-900-ish (đậm, dễ đọc)

    return Semantics(
      label:
          'Current temperature ${widget.temperature} degrees. Tap for details.',
      button: true,
      child: Hero(
        tag: 'temp-bubble',
        child: RepaintBoundary(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            scale: _pressed ? 0.97 : 1.0,
            child: ScaleTransition(
              scale: _appear,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.busy ? null : _onTap,
                  onHighlightChanged: (v) => setState(() => _pressed = v),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Aura nhẹ phía ngoài để tạo chiều sâu
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 32,
                                spreadRadius: 2,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                        ),
                        // Nền: radial -> trung tâm sáng, rìa ấm
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment(-0.2, -0.25),
                              radius: 0.95,
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFF3F7FF), // hơi xanh nhẹ
                                Color(0xFFEFF4FF),
                              ],
                              stops: [0.2, 0.65, 1.0],
                            ),
                          ),
                        ),
                        // Viền gradient mảnh tăng “premium feel”
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 2,
                              // gradient stroke “fake” bằng shader mask
                              color: Colors.transparent,
                            ),
                          ),
                          foregroundDecoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              startAngle: 0,
                              endAngle: 3.1415 * 2,
                              colors: const [
                                Color(0xFFFFFFFF),
                                Color(0xFFE2E8F0),
                                Color(0xFFFFFFFF),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                        // Glare specular
                        Align(
                          alignment: const Alignment(-0.45, -0.55),
                          child: Container(
                            width: size * 0.55,
                            height: size * 0.55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.60),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Nhiệt độ (display typeface, kerning âm)
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(
                                scale: Tween(
                                  begin: 0.985,
                                  end: 1.0,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: Text(
                              '${widget.temperature}°',
                              key: ValueKey(widget.temperature),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                // Outfit: display đẹp, dễ đọc; có thể thử Inter Tight/Manrope
                                fontSize: (size * 0.46).clamp(56.0, 110.0),
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                                letterSpacing: -1.5,
                                color: baseColor,
                              ),
                            ),
                          ),
                        ),
                        // Busy overlay (mờ + spinner)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: widget.busy ? 1 : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.38),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
