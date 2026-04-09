import 'package:flutter/material.dart';
import '../theme.dart';
import 'dart:ui';
import 'dart:math' as math;

class MapPreview extends StatefulWidget {
  final String locationName;
  const MapPreview({Key? key, required this.locationName}) : super(key: key);

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 250,
      decoration: AuraTheme.solidDecoration(radius: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 🗺️ The Digital Grid
            CustomPaint(
              painter: MapPainter(_controller),
              size: Size.infinite,
            ),
            
            // 🌑 Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            
            // 📍 Location Label
            Positioned(
              bottom: 20, left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("INTELLIGENCE ROUTE ACTIVE", 
                    style: TextStyle(color: AuraTheme.accentBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)
                  ),
                  Text(widget.locationName.toUpperCase(), 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            ),
            
            // 🧭 Status HUD
            const Positioned(
              top: 20, right: 20,
              child: Row(
                children: [
                  Icon(Icons.gps_fixed_rounded, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 8),
                  Text("LIVE DATA", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final Animation<double> animation;
  MapPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Draw Grid
    double step = 30;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintGrid);
    }

    final paintRoute = Paint()
      ..color = AuraTheme.accentBlue.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw Animated Route
    Path path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.82);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.8, size.height * 0.2);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0, metric.length * animation.value);
      canvas.drawPath(extractPath, paintRoute);
    }

    // Draw Pulse at Destination
    final paintPulse = Paint()
      ..color = AuraTheme.accentBlue.withOpacity(0.3 * (1 - animation.value))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 30 * animation.value, paintPulse);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
