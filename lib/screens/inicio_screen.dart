import 'dart:async';
import 'package:flutter/material.dart';
import 'brujula_screen.dart';
import '../widgets/sky_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool get isNight {
    final h = DateTime.now().hour;
    return h >= 18 || h < 6;
  }

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  bool _tapped = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _navegar() {
    if (_tapped) return;
    _tapped = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CompassScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = isNight ? Colors.white : Colors.black87;
    final accent = isNight ? const Color(0xFF4FC3F7) : const Color(0xFF1565C0);
    final cardBg = isNight
        ? const Color(0xFF0A1628).withOpacity(0.75)
        : Colors.white.withOpacity(0.70);
    final borderColor = accent.withOpacity(0.3);

    return GestureDetector(
      onTap: _navegar,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            SkyBackground(isNight: isNight),
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (_, __) => Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) => Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardBg,
                                border: Border.all(
                                  color: accent.withOpacity(
                                      0.3 + 0.25 * _pulseController.value),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(
                                        0.15 + 0.2 * _pulseController.value),
                                    blurRadius:
                                        24 + 12 * _pulseController.value,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            'BRÚJULA',
                            style: TextStyle(
                              color: fg,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'UNISON',
                            style: TextStyle(
                              color: accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: accent.withOpacity(0.25),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: accent.withOpacity(0.25),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: borderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.08),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _IntegranteTile(
                                  nombre: 'Barajas Miranda',
                                  fg: fg,
                                  accent: accent,
                                ),
                                _Divider(color: accent),
                                _IntegranteTile(
                                  nombre: 'Jose Jose',
                                  fg: fg,
                                  accent: accent,
                                ),
                                _Divider(color: accent),
                                _IntegranteTile(
                                  nombre: 'Salcido Gutierrez',
                                  fg: fg,
                                  accent: accent,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          _TapHint(
                            isNight: isNight,
                            fg: fg,
                            accent: accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntegranteTile extends StatelessWidget {
  final String nombre;
  final Color fg;
  final Color accent;

  const _IntegranteTile({
    required this.nombre,
    required this.fg,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            nombre,
            style: TextStyle(
              color: fg.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: color.withOpacity(0.1),
    );
  }
}

class _TapHint extends StatefulWidget {
  final bool isNight;
  final Color fg;
  final Color accent;

  const _TapHint({
    required this.isNight,
    required this.fg,
    required this.accent,
  });

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
      builder: (_, __) => Opacity(
        opacity: 0.4 + 0.6 * _ctrl.value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 16,
              color: widget.accent,
            ),
            const SizedBox(width: 8),
            Text(
              'Toca para continuar',
              style: TextStyle(
                color: widget.fg.withOpacity(0.6),
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
