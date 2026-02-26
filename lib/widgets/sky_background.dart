import 'dart:math';
import 'package:flutter/material.dart';

class SkyBackground extends StatefulWidget {
  final bool isNight;
  const SkyBackground({super.key, required this.isNight});

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _twinkleController;
  late AnimationController _shootingStarController;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _shootingStarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(period: const Duration(seconds: 8));
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _twinkleController.dispose();
    _shootingStarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isNight
              ? [
                  const Color(0xFF020818),
                  const Color(0xFF0A1628),
                  const Color(0xFF112240),
                  const Color(0xFF1A2F55),
                ]
              : [
                  const Color(0xFF1B78E6),
                  const Color(0xFF3B9EF5),
                  const Color(0xFF87CEEB),
                  const Color(0xFFB8DFF5),
                ],
        ),
      ),
      child: Stack(
        children: [
          if (widget.isNight) ...[
            // Stars
            AnimatedBuilder(
              animation: _twinkleController,
              builder: (_, __) => CustomPaint(
                painter: StarsPainter(_twinkleController.value),
                size: Size.infinite,
              ),
            ),
            // Shooting star
            AnimatedBuilder(
              animation: _shootingStarController,
              builder: (_, __) => CustomPaint(
                painter: ShootingStarPainter(_shootingStarController.value),
                size: Size.infinite,
              ),
            ),
            // Moon
            Positioned(
              top: 60,
              right: 50,
              child: _Moon(),
            ),
          ] else ...[
            // Sun
            Positioned(
              top: 40,
              right: 60,
              child: _Sun(),
            ),
            // Clouds
            AnimatedBuilder(
              animation: _cloudController,
              builder: (_, __) => CustomPaint(
                painter: CloudsPainter(_cloudController.value),
                size: Size.infinite,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StarsPainter extends CustomPainter {
  final double twinkle;
  StarsPainter(this.twinkle);

  static final _rng = Random(42);
  static final List<Offset> _positions = List.generate(
    120,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final List<double> _sizes = List.generate(120, (_) => _rng.nextDouble() * 2.5 + 0.5);
  static final List<double> _phases = List.generate(120, (_) => _rng.nextDouble() * 2 * pi);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _positions.length; i++) {
      final brightness = 0.4 + 0.6 * ((sin(twinkle * pi * 2 + _phases[i]) + 1) / 2);
      final paint = Paint()
        ..color = Colors.white.withOpacity(brightness)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
      canvas.drawCircle(
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height * 0.7),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarsPainter old) => old.twinkle != twinkle;
}

class ShootingStarPainter extends CustomPainter {
  final double progress;
  ShootingStarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0.6) return;
    final t = progress / 0.6;
    final startX = size.width * 0.2;
    final startY = size.height * 0.1;
    final endX = size.width * 0.6;
    final endY = size.height * 0.35;

    final currentX = startX + (endX - startX) * t;
    final currentY = startY + (endY - startY) * t;
    final tailX = startX + (endX - startX) * max(0, t - 0.15);
    final tailY = startY + (endY - startY) * max(0, t - 0.15);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.9)],
      ).createShader(Rect.fromPoints(Offset(tailX, tailY), Offset(currentX, currentY)))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(tailX, tailY), Offset(currentX, currentY), paint);
  }

  @override
  bool shouldRepaint(ShootingStarPainter old) => old.progress != progress;
}

class CloudsPainter extends CustomPainter {
  final double progress;
  CloudsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.85);

    void drawCloud(double x, double y, double scale) {
      final path = Path();
      final cx = x * size.width;
      final cy = y * size.height;
      final s = scale * size.width * 0.12;

      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: s * 2, height: s * 1.2), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - s * 0.6, cy + s * 0.15), width: s * 1.4, height: s), paint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + s * 0.6, cy + s * 0.2), width: s * 1.3, height: s * 0.9), paint);
    }

    final offset1 = (progress * 0.3) % 1.0;
    final offset2 = (progress * 0.2 + 0.4) % 1.0;

    drawCloud(offset1, 0.15, 1.0);
    drawCloud(offset2, 0.25, 0.7);
    drawCloud((offset1 + 0.6) % 1.0, 0.1, 0.5);
  }

  @override
  bool shouldRepaint(CloudsPainter old) => old.progress != progress;
}

class _Moon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF5D6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFF5D6).withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Align(
        alignment: const Alignment(0.3, -0.2),
        child: Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF112240),
          ),
        ),
      ),
    );
  }
}

class _Sun extends StatefulWidget {
  @override
  State<_Sun> createState() => _SunState();
}

class _SunState extends State<_Sun> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _ctrl.value * 2 * pi,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFD700),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 15,
              ),
            ],
          ),
          child: CustomPaint(painter: _SunRayPainter()),
        ),
      ),
    );
  }
}

class _SunRayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE44D).withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        center + Offset.fromDirection(angle, radius + 4),
        center + Offset.fromDirection(angle, radius + 16),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
