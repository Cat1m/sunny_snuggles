import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Game bắn confetti ~1.6s. Nền trong suốt để overlay lên UI.
class ConfettiGame extends FlameGame {
  ConfettiGame({this.count = 180});
  final int count;

  final _rnd = Random();
  bool _spawned = false; // chỉ sinh particle sau khi biết kích thước

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    Color backgroundColor = Colors.transparent;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_spawned && size.x > 0 && size.y > 0) {
      _spawned = true;
      final center = size / 2;

      // Tạo 3 cụm nổ quanh tâm cho “dày” hơn
      for (int cluster = 0; cluster < 3; cluster++) {
        final jitter = Vector2(
          (_rnd.nextDouble() - .5) * 40,
          (_rnd.nextDouble() - .5) * 40,
        );
        add(_makeBurst(center + jitter));
      }
    }
  }

  Component _makeBurst(Vector2 origin) {
    final particles = Particle.generate(
      count: count ~/ 3,
      lifespan: 1.6,
      generator: (i) {
        // Ngẫu nhiên góc 360° và tốc độ
        final angle = _rnd.nextDouble() * 2 * pi;
        final speed = 80 + _rnd.nextDouble() * 180;
        final vx = cos(angle) * speed;
        final vy = sin(angle) * speed;

        // Random màu rực rỡ bằng HSVColor (có sẵn)
        final color = HSVColor.fromAHSV(
          1.0,
          _rnd.nextDouble() * 360, // hue
          0.85, // saturation
          0.55, // value
        ).toColor();

        // Hạt tròn/ô vuông ngẫu nhiên size nhỏ
        final sz = 2.0 + _rnd.nextDouble() * 4.0;
        final isCircle = _rnd.nextBool();

        final child = isCircle
            ? CircleParticle(radius: sz, paint: Paint()..color = color)
            : ComputedParticle(
                renderer: (canvas, _) {
                  final paint = Paint()..color = color;
                  canvas.drawRect(
                    Rect.fromCenter(
                      center: Offset.zero,
                      width: sz * 2,
                      height: sz * 2,
                    ),
                    paint,
                  );
                },
              );

        // Gia tốc “trọng lực” kéo xuống nhẹ
        return AcceleratedParticle(
          acceleration: Vector2(0, 200),
          speed: Vector2(vx, vy),
          position: origin.clone(),
          child: child,
        );
      },
    );

    return ParticleSystemComponent(particle: particles);
  }
}

/// Overlay toàn màn hình hiển thị confetti.
/// Dùng với Stack + Positioned.fill.
/// Không cần overlayBuilderMap.
class ConfettiOverlay extends StatelessWidget {
  const ConfettiOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget<ConfettiGame>(game: ConfettiGame());
  }
}
