import 'package:flutter_compass/flutter_compass.dart';

class BrujulaService {
  Stream<CompassEvent> getCompassStream() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      throw Exception("Este dispositivo no tiene sensor de brújula.");
    }
    return stream;
  }
}