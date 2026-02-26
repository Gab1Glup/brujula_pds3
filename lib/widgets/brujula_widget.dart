import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

class BrujulaWidget extends StatelessWidget {
  final Stream<CompassEvent>? compassStream;
  final bool isNight;

  const BrujulaWidget({
    super.key,
    required this.compassStream,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassEvent>(
      stream: compassStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(
            color: isNight ? Colors.white : Colors.black,
          );
        }

        double direction = snapshot.data!.heading ?? 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${direction.toStringAsFixed(0)}°",
              style: TextStyle(
                fontSize: 40,
                color: isNight ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            AnimatedRotation(
              turns: -direction / 360,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isNight ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/compass.png',
                  width: 250,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
