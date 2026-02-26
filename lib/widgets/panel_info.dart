import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class InfoPanel extends StatelessWidget {
  final Position position;
  final bool isNight;

  const InfoPanel({
    super.key,
    required this.position,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isNight
        ? const Color(0xFF0A1628).withOpacity(0.75)
        : Colors.white.withOpacity(0.65);
    final borderColor = isNight
        ? const Color(0xFF4FC3F7).withOpacity(0.3)
        : const Color(0xFF1565C0).withOpacity(0.2);
    final accent = isNight ? const Color(0xFF4FC3F7) : const Color(0xFF1565C0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _CoordinateCard(
              label: 'LAT',
              value: position.latitude,
              icon: Icons.swap_vert,
              isNight: isNight,
              color:
                  isNight ? const Color(0xFF4FC3F7) : const Color(0xFF1565C0),
              suffix: position.latitude >= 0 ? 'N' : 'S',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CoordinateCard(
              label: 'LON',
              value: position.longitude,
              icon: Icons.swap_horiz,
              isNight: isNight,
              color:
                  isNight ? const Color(0xFF80CBC4) : const Color(0xFF00695C),
              suffix: position.longitude >= 0 ? 'E' : 'O',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CoordinateCard(
              label: 'ALT',
              value: position.altitude,
              icon: Icons.terrain,
              isNight: isNight,
              color:
                  isNight ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
              suffix: 'm',
              isAltitude: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final bool isNight;
  final Color color;
  final String suffix;
  final bool isAltitude;

  const _CoordinateCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isNight,
    required this.color,
    required this.suffix,
    this.isAltitude = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isNight ? color.withOpacity(0.08) : color.withOpacity(0.06);
    final textColor = isNight ? Colors.white : Colors.black87;
    final absVal = value.abs();
    final degrees = isAltitude ? absVal : absVal.floor().toDouble();
    final minutes =
        isAltitude ? 0.0 : ((absVal - degrees) * 60).floor().toDouble();
    final seconds =
        isAltitude ? 0.0 : (((absVal - degrees) * 60 - minutes) * 60);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isAltitude)
            Text(
              absVal.toStringAsFixed(1),
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            )
          else ...[
            Text(
              '${degrees.toInt()}°${minutes.toInt()}\'',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${seconds.toStringAsFixed(1)}"',
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              suffix,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
