import 'dart:ui';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🌏 360° Panorama Engine (Custom Panner)
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _offset += details.delta.dx * 0.002;
              });
            },
            child: CustomPaint(
              painter: PanoramaPainter(
                imageProvider: NetworkImage(widget.imageUrl),
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
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                            Text(widget.title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
  final ImageProvider imageProvider;
  final double offset;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  PanoramaPainter({required this.imageProvider, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    if (_imageInfo == null) {
      _imageStream ??= imageProvider.resolve(ImageConfiguration.empty);
      _imageStream!.addListener(ImageStreamListener((ImageInfo info, bool synchronousCall) {
        _imageInfo = info;
      }));
      return;
    }

    final image = _imageInfo!.image;
    final double imgWidth = image.width.toDouble();
    final double imgHeight = image.height.toDouble();

    // 🪐 Sphere Simulation Logic
    // We render the image twice to handle wrapping
    final double viewWidth = size.width;
    final double viewHeight = size.height;
    
    // Scale image to fit height
    final double scale = viewHeight / imgHeight;
    final double scaledWidth = imgWidth * scale;

    double currentX = (offset * scaledWidth) % scaledWidth;

    // Draw segment 1
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgWidth, imgHeight),
      Rect.fromLTWH(currentX, 0, scaledWidth, viewHeight),
      Paint(),
    );

    // Draw segment 2 (wrap around)
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imgWidth, imgHeight),
      Rect.fromLTWH(currentX - scaledWidth, 0, scaledWidth, viewHeight),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant PanoramaPainter oldDelegate) => oldDelegate.offset != offset;
}
