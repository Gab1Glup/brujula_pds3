import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ubicacion_service.dart';
import '../widgets/brujula_view.dart';
import '../widgets/panel_info.dart';
import '../widgets/sky_background.dart';

enum _AppState {
  cargando,
  sinPermiso,
  sinPermisoPermanente,
  sinGPS,
  sinSensor,
  listo,
}

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  final _locationService = UbicacionService();

  _AppState _state = _AppState.cargando;
  Position? _position;
  bool _isNight = _calcIsNight();

  StreamSubscription<Position>? _positionSub;
  Timer? _nightTimer;
  Timer? _gpsRetryTimer;

  static bool _calcIsNight() {
    final h = DateTime.now().hour;
    return h >= 18 || h < 6;
  }

  @override
  void initState() {
    super.initState();
    _verificarTodo();
    _nightTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final n = _calcIsNight();
      if (n != _isNight && mounted) setState(() => _isNight = n);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _nightTimer?.cancel();
    _gpsRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _verificarTodo() async {
    if (!mounted) return;
    setState(() => _state = _AppState.cargando);
    _gpsRetryTimer?.cancel();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _state = _AppState.sinPermisoPermanente);
      return;
    }
    if (permission == LocationPermission.denied) {
      if (mounted) setState(() => _state = _AppState.sinPermiso);
      return;
    }

    final gpsActivo = await Geolocator.isLocationServiceEnabled();
    if (!gpsActivo) {
      if (mounted) setState(() => _state = _AppState.sinGPS);
      _gpsRetryTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        final activo = await Geolocator.isLocationServiceEnabled();
        if (activo && mounted) {
          _gpsRetryTimer?.cancel();
          _verificarTodo();
        }
      });
      return;
    }

    _iniciarStream();
  }

  void _iniciarStream() {
    _positionSub?.cancel();
    _positionSub = _locationService.getPositionStream().listen(
      (pos) {
        if (mounted) setState(() => _position = pos);
      },
      onError: (_) {
        if (mounted) {
          _positionSub?.cancel();
          setState(() {
            _state = _AppState.sinGPS;
            _position = null;
          });
          _gpsRetryTimer?.cancel();
          _gpsRetryTimer =
              Timer.periodic(const Duration(seconds: 3), (_) async {
            final activo = await Geolocator.isLocationServiceEnabled();
            if (activo && mounted) {
              _gpsRetryTimer?.cancel();
              _verificarTodo();
            }
          });
        }
      },
    );
    if (mounted) setState(() => _state = _AppState.listo);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final salir = await _mostrarDialogoSalir();
        if (salir == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            SkyBackground(isNight: _isNight),
            SafeArea(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _AppState.cargando:
        return _GateScreen(
          isNight: _isNight,
          icon: Icons.sensors,
          titulo: 'Iniciando brújula',
          mensaje: 'Verificando permisos y sensores...',
          cargando: true,
        );

      case _AppState.sinPermiso:
        return _GateScreen(
          isNight: _isNight,
          icon: Icons.location_off,
          titulo: 'Permiso de ubicación',
          mensaje: 'La brújula necesita acceso a tu ubicación para mostrarte '
              'latitud, longitud y altitud en tiempo real.',
          botonLabel: 'Dar permiso',
          onBoton: _verificarTodo,
        );

      case _AppState.sinPermisoPermanente:
        return _GateScreen(
          isNight: _isNight,
          icon: Icons.lock,
          titulo: 'Permiso bloqueado',
          mensaje: 'El permiso de ubicación fue bloqueado permanentemente.\n\n'
              'Ve a Ajustes › Aplicaciones › Brújula Unison › Permisos '
              'y activa "Ubicación".',
          botonLabel: 'Abrir Ajustes',
          onBoton: () async {
            await Geolocator.openAppSettings();
            await Future.delayed(const Duration(seconds: 1));
            _verificarTodo();
          },
          esError: true,
        );

      case _AppState.sinGPS:
        return _GateScreen(
          isNight: _isNight,
          icon: Icons.gps_off,
          titulo: 'GPS apagado',
          mensaje:
              'Activa la ubicación en tu dispositivo para poder usar la brújula.',
          botonLabel: 'Abrir ajustes de ubicación',
          onBoton: () => Geolocator.openLocationSettings(),
          cargandoSecundario: true,
          mensajeSecundario: 'Detectando automáticamente cuando lo actives...',
        );

      case _AppState.sinSensor:
        return _GateScreen(
          isNight: _isNight,
          icon: Icons.explore_off,
          titulo: 'Sin sensor de brújula',
          mensaje: 'Este dispositivo no tiene magnetómetro y no puede '
              'detectar el norte magnético.',
          esError: true,
        );

      case _AppState.listo:
        return _BrujulaLista(
          isNight: _isNight,
          position: _position,
          onSinSensor: () {
            if (mounted) setState(() => _state = _AppState.sinSensor);
          },
        );
    }
  }

  Future<bool?> _mostrarDialogoSalir() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _isNight ? const Color(0xFF0A1628) : Colors.white,
        title: Text(
          '¿Salir de la brújula?',
          style: TextStyle(color: _isNight ? Colors.white : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _GateScreen extends StatefulWidget {
  final bool isNight;
  final IconData icon;
  final String titulo;
  final String mensaje;
  final String? botonLabel;
  final VoidCallback? onBoton;
  final bool cargando;
  final bool cargandoSecundario;
  final String? mensajeSecundario;
  final bool esError;

  const _GateScreen({
    required this.isNight,
    required this.icon,
    required this.titulo,
    required this.mensaje,
    this.botonLabel,
    this.onBoton,
    this.cargando = false,
    this.cargandoSecundario = false,
    this.mensajeSecundario,
    this.esError = false,
  });

  @override
  State<_GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<_GateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isNight ? Colors.white : Colors.black87;
    final cardBg = widget.isNight
        ? const Color(0xFF0A1628).withOpacity(0.82)
        : Colors.white.withOpacity(0.78);
    final accent = widget.esError
        ? Colors.redAccent
        : widget.isNight
            ? const Color(0xFF4FC3F7)
            : const Color(0xFF1565C0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(color: accent.withOpacity(0.15), blurRadius: 28),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.10 + 0.08 * _pulse.value),
                    border: Border.all(
                      color: accent.withOpacity(0.25 + 0.2 * _pulse.value),
                      width: 2,
                    ),
                  ),
                  child: Icon(widget.icon, color: accent, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.titulo,
                style: TextStyle(
                  color: fg,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.mensaje,
                style: TextStyle(
                  color: fg.withOpacity(0.65),
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.cargando) ...[
                const SizedBox(height: 24),
                CircularProgressIndicator(color: accent, strokeWidth: 2),
              ],
              if (widget.cargandoSecundario &&
                  widget.mensajeSecundario != null) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: accent, strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.mensajeSecundario!,
                        style: TextStyle(
                            color: fg.withOpacity(0.45), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.botonLabel != null && widget.onBoton != null) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onBoton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.botonLabel!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BrujulaLista extends StatefulWidget {
  final bool isNight;
  final Position? position;
  final VoidCallback onSinSensor;

  const _BrujulaLista({
    required this.isNight,
    required this.position,
    required this.onSinSensor,
  });

  @override
  State<_BrujulaLista> createState() => _BrujulaListaState();
}

class _BrujulaListaState extends State<_BrujulaLista> {
  bool _sensorRevisado = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading;

        if (!_sensorRevisado &&
            snapshot.connectionState == ConnectionState.active &&
            heading == null) {
          _sensorRevisado = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onSinSensor();
          });
        }

        return Column(
          children: [
            _TopBar(isNight: widget.isNight),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: CompassView(
                    bearing: null,
                    heading: heading ?? 0,
                    foregroundColor:
                        widget.isNight ? Colors.white : Colors.black87,
                    bearingColor: Colors.red,
                    isNight: widget.isNight,
                  ),
                ),
              ),
            ),
            if (widget.position != null)
              InfoPanel(
                position: widget.position!,
                isNight: widget.isNight,
              )
            else
              _GpsAcquiring(isNight: widget.isNight),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatefulWidget {
  final bool isNight;
  const _TopBar({required this.isNight});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isNight ? Colors.white : Colors.black87;
    final time =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Text(
            'BRÚJULA',
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: fg.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fg.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isNight ? Icons.nights_stay : Icons.wb_sunny,
                  color: widget.isNight
                      ? const Color(0xFFFFF5D6)
                      : const Color(0xFFFFD700),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsAcquiring extends StatefulWidget {
  final bool isNight;
  const _GpsAcquiring({required this.isNight});

  @override
  State<_GpsAcquiring> createState() => _GpsAcquiringState();
}

class _GpsAcquiringState extends State<_GpsAcquiring>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.isNight ? const Color(0xFF4FC3F7) : const Color(0xFF1565C0);
    final bg = widget.isNight
        ? const Color(0xFF0A1628).withOpacity(0.70)
        : Colors.white.withOpacity(0.65);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _spin,
            builder: (_, __) => Transform.rotate(
              angle: _spin.value * 2 * 3.14159,
              child: Icon(Icons.gps_fixed, color: accent, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Adquiriendo señal GPS...',
            style: TextStyle(
              color: widget.isNight ? Colors.white70 : Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
