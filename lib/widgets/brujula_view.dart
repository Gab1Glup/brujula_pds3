import 'dart:math';
import 'package:flutter/material.dart';

class CompassView extends StatefulWidget {
  const CompassView({
    Key? key,
    required this.bearing,
    required this.heading,
    this.foregroundColor = Colors.white,
    this.bearingColor = Colors.red,
    this.isNight = false,
  }) : super(key: key);

  final double? bearing;
  final double heading;
  final Color foregroundColor;
  final Color bearingColor;
  final bool isNight;

  @override
  State<CompassView> createState() => _CompassViewState();
}

class _CompassViewState extends State<CompassView>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _rotationAnim;
  double _lastHeading = 0;

  @override
  void initState() {
    super.initState();
    _lastHeading = widget.heading;

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotationAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(CompassView old) {
    super.didUpdateWidget(old);
    if ((old.heading - widget.heading).abs() > 0.5) {
      final oldVal = _rotationAnim.value;
      _rotationAnim = Tween<double>(
        begin: oldVal,
        end: -widget.heading * pi / 180,
      ).animate(
        CurvedAnimation(parent: _rotationController, curve: Curves.easeOutBack),
      );
      _rotationController
        ..reset()
        ..forward();
      _lastHeading = widget.heading;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isNight ? const Color(0xFF4FC3F7) : const Color(0xFF1565C0);
    final accentGlow = widget.isNight ? const Color(0xFF81D4FA) : const Color(0xFF42A5F5);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Outer decorative ring - animated glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, __) => CustomPaint(
              painter: _OuterRingPainter(
                glowIntensity: _glowController.value,
                color: accentGlow,
                isNight: widget.isNight,
              ),
            ),
          ),

          // Main compass rose - smooth animated rotation
          AnimatedBuilder(
            animation: _rotationAnim,
            builder: (_, __) => Transform.rotate(
              angle: _rotationAnim.value,
              child: CustomPaint(
                painter: _WindRosePainter(
                  foregroundColor: widget.foregroundColor,
                  accentColor: accent,
                  isNight: widget.isNight,
                ),
              ),
            ),
          ),

          // Bearing indicator
          if (widget.bearing != null)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final bearingAngle =
                    (widget.bearing! - widget.heading) * pi / 180;
                return Transform.rotate(
                  angle: bearingAngle,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Container(
                        width: 16,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.bearingColor,
                              widget.bearingColor.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: widget.bearingColor.withOpacity(
                                  0.4 + 0.4 * _pulseController.value),
                              blurRadius: 10 + 8 * _pulseController.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Center pivot jewel
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      accentGlow,
                      accent.withOpacity(0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentGlow.withOpacity(
                          0.3 + 0.4 * _pulseController.value),
                      blurRadius: 12 + 8 * _pulseController.value,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Heading degree display
          Align(
            alignment: const Alignment(0, 0.88),
            child: _HeadingBadge(
              heading: widget.heading,
              isNight: widget.isNight,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadingBadge extends StatelessWidget {
  final double heading;
  final bool isNight;
  const _HeadingBadge({required this.heading, required this.isNight});

  String get _cardinal {
    final h = ((heading % 360) + 360) % 360;
    if (h < 22.5 || h >= 337.5) return 'N';
    if (h < 67.5) return 'NE';
    if (h < 112.5) return 'E';
    if (h < 157.5) return 'SE';
    if (h < 202.5) return 'S';
    if (h < 247.5) return 'SO';
    if (h < 292.5) return 'O';
    return 'NO';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isNight
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.08);
    final border = isNight
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: (isNight ? Colors.blue : Colors.blue).withOpacity(0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${heading.toStringAsFixed(1)}°',
            style: TextStyle(
              color: isNight ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isNight
                  ? const Color(0xFF4FC3F7).withOpacity(0.2)
                  : const Color(0xFF1565C0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _cardinal,
              style: TextStyle(
                color: isNight ? const Color(0xFF4FC3F7) : const Color(0xFF1565C0),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OuterRingPainter extends CustomPainter {
  final double glowIntensity;
  final Color color;
  final bool isNight;
  _OuterRingPainter({
    required this.glowIntensity,
    required this.color,
    required this.isNight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;

    // Outer glow ring
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withOpacity(0.15 + 0.2 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 6 * glowIntensity);
    canvas.drawCircle(center, radius, glowPaint);

    // Degree ticks
    for (int i = 0; i < 360; i++) {
      final isMajor = i % 10 == 0;
      final isCardinal = i % 90 == 0;
      if (!isMajor && i % 5 != 0) continue;

      final angle = (i - 90) * pi / 180;
      final outer = radius - 2;
      final inner = isCardinal
          ? outer - 18
          : isMajor
              ? outer - 10
              : outer - 5;

      final tickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCardinal ? 2.5 : (isMajor ? 1.5 : 0.8)
        ..color = (isNight ? Colors.white : Colors.black87).withOpacity(
            isCardinal ? 0.9 : (isMajor ? 0.6 : 0.3));

      canvas.drawLine(
        center + Offset.fromDirection(angle, inner),
        center + Offset.fromDirection(angle, outer),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_OuterRingPainter old) =>
      old.glowIntensity != glowIntensity;
}

class _WindRosePainter extends CustomPainter {
  final Color foregroundColor;
  final Color accentColor;
  final bool isNight;

  _WindRosePainter({
    required this.foregroundColor,
    required this.accentColor,
    required this.isNight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.38;

    // Draw the 4 main cardinal points (N,S,E,W) as diamonds
    _drawCardinalDiamonds(canvas, center, radius);

    // Draw the 4 intercardinal points as smaller diamonds
    _drawIntercardinalDiamonds(canvas, center, radius * 0.65);

    // Draw center ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = foregroundColor.withOpacity(0.5);
    canvas.drawCircle(center, radius * 0.18, ringPaint);
    canvas.drawCircle(center, radius * 0.28, ringPaint..strokeWidth = 1);

    // Draw cardinal labels
    _drawLabels(canvas, center, radius, size);
  }

  void _drawCardinalDiamonds(Canvas canvas, Offset center, double radius) {
    const cardinals = ['N', 'E', 'S', 'W'];
    const angles = [0.0, 90.0, 180.0, 270.0];

    for (int i = 0; i < 4; i++) {
      final angle = angles[i] * pi / 180 - pi / 2;
      final isNorth = i == 0;

      final tipOffset = Offset.fromDirection(angle, radius);
      final baseOffset = Offset.fromDirection(angle, radius * 0.2);
      final sideAngle = angle + pi / 2;
      final sideWidth = radius * 0.18;

      final path = Path()
        ..moveTo(
            center.dx + tipOffset.dx, center.dy + tipOffset.dy) // tip
        ..lineTo(
            center.dx + baseOffset.dx + cos(sideAngle) * sideWidth,
            center.dy + baseOffset.dy + sin(sideAngle) * sideWidth) // left base
        ..lineTo(
            center.dx + baseOffset.dx - cos(sideAngle) * sideWidth * 0.5,
            center.dy +
                baseOffset.dy -
                sin(sideAngle) * sideWidth * 0.5) // bottom
        ..lineTo(
            center.dx + baseOffset.dx - cos(sideAngle) * sideWidth,
            center.dy +
                baseOffset.dy -
                sin(sideAngle) * sideWidth) // right base
        ..close();

      // Left half (lighter)
      final leftPath = Path()
        ..moveTo(center.dx + tipOffset.dx, center.dy + tipOffset.dy)
        ..lineTo(
            center.dx + baseOffset.dx + cos(sideAngle) * sideWidth,
            center.dy + baseOffset.dy + sin(sideAngle) * sideWidth)
        ..lineTo(
            center.dx + baseOffset.dx - cos(sideAngle) * sideWidth * 0.5,
            center.dy + baseOffset.dy - sin(sideAngle) * sideWidth * 0.5)
        ..close();

      final rightPath = Path()
        ..moveTo(center.dx + tipOffset.dx, center.dy + tipOffset.dy)
        ..lineTo(
            center.dx + baseOffset.dx - cos(sideAngle) * sideWidth,
            center.dy + baseOffset.dy - sin(sideAngle) * sideWidth)
        ..lineTo(
            center.dx + baseOffset.dx - cos(sideAngle) * sideWidth * 0.5,
            center.dy + baseOffset.dy - sin(sideAngle) * sideWidth * 0.5)
        ..close();

      if (isNorth) {
        // North: red + dark
        canvas.drawPath(leftPath,
            Paint()..color = const Color(0xFFE53935).withOpacity(0.95));
        canvas.drawPath(
            rightPath,
            Paint()..color = const Color(0xFFB71C1C).withOpacity(0.9));
      } else {
        canvas.drawPath(
            leftPath, Paint()..color = foregroundColor.withOpacity(0.9));
        canvas.drawPath(
            rightPath, Paint()..color = foregroundColor.withOpacity(0.55));
      }

      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = foregroundColor.withOpacity(0.3));
    }
  }

  void _drawIntercardinalDiamonds(
      Canvas canvas, Offset center, double radius) {
    const angles = [45.0, 135.0, 225.0, 315.0];

    for (final angleDeg in angles) {
      final angle = angleDeg * pi / 180 - pi / 2;
      final tipOffset = Offset.fromDirection(angle, radius);
      final baseOffset = Offset.fromDirection(angle, radius * 0.3);
      final sideAngle = angle + pi / 2;
      final sideWidth = radius * 0.14;

      final leftPath = Path()
        ..moveTo(center.dx + tipOffset.dx, center.dy + tipOffset.dy)
        ..lineTo(
            center.dx + baseOffset.dx + cos(sideAngle) * sideWidth,
            center.dy + baseOffset.dy + sin(sideAngle) * sideWidth)
        ..lineTo(
            center.dx + baseOffset.dx - cos(sideAngle) * sideWidth * 0.4,
            center.dy + baseOffset.dy - sin(sideAngle) * sideWidth * 0.4)
        ..close();

      final rightPath = Path()
        ..moveTo(center.dx + tipOffset.dx, center.dy + tipOffset.dy)
        ..lineTo(
            center.dx + baseOffset.dx - cos(sideAngle) * sideWidth,
            center.dy + baseOffset.dy - sin(sideAngle) * sideWidth)
        ..lineTo(
            center.dx + baseOffset.dx - cos(sideAngle) * sideWidth * 0.4,
            center.dy + baseOffset.dy - sin(sideAngle) * sideWidth * 0.4)
        ..close();

      canvas.drawPath(
          leftPath, Paint()..color = foregroundColor.withOpacity(0.65));
      canvas.drawPath(
          rightPath, Paint()..color = foregroundColor.withOpacity(0.35));
    }
  }

  void _drawLabels(
      Canvas canvas, Offset center, double radius, Size size) {
    const labels = ['N', 'E', 'S', 'O'];
    const angles = [-90.0, 0.0, 90.0, 180.0];
    const isNorthLabel = [true, false, false, false];

    for (int i = 0; i < labels.length; i++) {
      final angle = angles[i] * pi / 180;
      final offset = Offset.fromDirection(angle, radius + 22);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: isNorthLabel[i] ? const Color(0xFFE53935) : foregroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: (isNorthLabel[i]
                        ? const Color(0xFFE53935)
                        : accentColor)
                    .withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        center +
            offset -
            Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_WindRosePainter old) =>
      old.foregroundColor != foregroundColor || old.isNight != isNight;
}
