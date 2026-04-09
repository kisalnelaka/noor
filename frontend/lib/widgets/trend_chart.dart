import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class TrendChart extends StatelessWidget {
  final List<double> data;
  final String title;

  const TrendChart({
    Key? key,
    required this.data,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: AuraTheme.solidDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AuraTheme.accentBlue)),
                   const SizedBox(height: 4),
                   const Text("MARKET TREND INDEX", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AuraTheme.textPrimary)),
                ],
              ),
              const Icon(Icons.show_chart_rounded, color: AuraTheme.accentBlue, size: 24),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: ChartPainter(data: data),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Legend(label: "2023 Q1", color: AuraTheme.borderLight),
              _Legend(label: "CURRENT", color: AuraTheme.accentBlue),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> data;

  ChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final Paint linePaint = Paint()
      ..color = AuraTheme.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AuraTheme.accentBlue.withOpacity(0.3), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final double stepX = size.width / (data.length - 1);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final Path path = Path();
    final Path fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((data[i] - minVal) / range * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Curve between points
        final double prevX = (i - 1) * stepX;
        final double prevY = size.height - ((data[i - 1] - minVal) / range * size.height);
        
        path.cubicTo(
          prevX + stepX / 2, prevY,
          x - stepX / 2, y,
          x, y
        );
        fillPath.cubicTo(
          prevX + stepX / 2, prevY,
          x - stepX / 2, y,
          x, y
        );
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw last point dot
    final double lastX = size.width;
    final double lastY = size.height - ((data.last - minVal) / range * size.height);
    canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = AuraTheme.accentBlue);
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) => true;
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;

  const _Legend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 9, color: AuraTheme.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}
