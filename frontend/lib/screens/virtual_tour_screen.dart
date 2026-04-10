import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme.dart';

class VirtualTourScreen extends StatefulWidget {
  final String imageUrl;
  final String title;

  const VirtualTourScreen({
    Key? key,
    required this.imageUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<VirtualTourScreen> createState() => _VirtualTourScreenState();
}

class _VirtualTourScreenState extends State<VirtualTourScreen> {
  double _offset = 0.0;
  ImageInfo? _imageInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final imageProvider = NetworkImage(widget.imageUrl);
    final stream = imageProvider.resolve(createLocalImageConfiguration(context));
    stream.addListener(ImageStreamListener((info, synchronousCall) {
      if (mounted) {
        setState(() {
          _imageInfo = info;
        });
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🌏 360° Panorama Engine (Custom Panner)
          if (_imageInfo == null)
            const Center(child: CircularProgressIndicator(color: AuraTheme.accentBlue))
          else
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _offset += details.delta.dx * 0.002;
                });
              },
              child: CustomPaint(
                painter: PanoramaPainter(
                  image: _imageInfo!.image,
                  offset: _offset,
                ),
                child: Container(),
              ),
            ),

          // 💎 Glassmorphic Overlay
          Positioned(
            top: 60, left: 24, right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
                            const Text("360° VIRTUAL WALKTHROUGH", style: TextStyle(fontSize: 9, color: Colors.white60)),
                          ],
                        ),
                      ),
                      const Icon(Icons.threed_rotation_rounded, color: AuraTheme.accentBlue),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🕹️ Navigation Hint
          const Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Column(
              children: [
                Icon(Icons.swipe, color: Colors.white30, size: 40),
                SizedBox(height: 8),
                Text("SWIPE TO EXPLORE", style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PanoramaPainter extends CustomPainter {
  final ui.Image image;
  final double offset;

  PanoramaPainter({required this.image, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final double imgWidth = image.width.toDouble();
    final double imgHeight = image.height.toDouble();

    // 🪐 Sphere Simulation Logic Ensure normalized positive modulo for bidirectional wrapping
    final double viewWidth = size.width;
    final double viewHeight = size.height;
    
    // Scale image to fit height
    final double scale = viewHeight / imgHeight;
    final double scaledWidth = imgWidth * scale;

    final double normalizedX = ((offset * scaledWidth) % scaledWidth + scaledWidth) % scaledWidth;

    // Draw segment 1 (Right side)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgWidth, imgHeight),
      Rect.fromLTWH(normalizedX, 0, scaledWidth, viewHeight),
      Paint(),
    );

    // Draw segment 2 (Left side wrap around)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgWidth, imgHeight),
      Rect.fromLTWH(normalizedX - scaledWidth, 0, scaledWidth, viewHeight),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant PanoramaPainter oldDelegate) => oldDelegate.offset != offset;
}
