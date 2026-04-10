import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:math' as math;

enum OrbState { idle, listening, thinking, speaking }

class VoiceOrb extends StatefulWidget {
  final bool isListening;
  final OrbState state; // Added for more granular control

  const VoiceOrb({
    Key? key, 
    this.isListening = false, 
    this.state = OrbState.idle
  }) : super(key: key);

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve current visual state
    OrbState effectiveState = widget.state;
    if (widget.isListening) effectiveState = OrbState.listening;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🏮 Dynamic Glow Layer
          _buildGlow(effectiveState),
          
          // 🌀 Core Orb
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutBack,
            width: effectiveState == OrbState.listening ? 180 : 160,
            height: effectiveState == OrbState.listening ? 180 : 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: _getOrbColors(effectiveState),
                center: const Alignment(-0.2, -0.2),
                radius: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getMainColor(effectiveState).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: _buildStateIndicator(effectiveState),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(OrbState state) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        double scale = 1.0 + (_pulseController.value * 0.2);
        if (state == OrbState.listening) scale += 0.2;
        
        return Opacity(
          opacity: (1.0 - _pulseController.value) * 0.5,
          child: Container(
            width: 240 * scale,
            height: 240 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getMainColor(state).withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateIndicator(OrbState state) {
    switch (state) {
      case OrbState.listening:
        return Center(
          child: SpinKitRipple(
            color: Colors.white.withOpacity(0.5),
            size: 100,
          ),
        );
      case OrbState.thinking:
        return Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AuraTheme.accentPastelPurple.withOpacity(0.3), width: 1),
                ),
              ),
            ),
            const SpinKitThreeBounce(
              color: Colors.white38,
              size: 20,
            ),
          ],
        );
      case OrbState.speaking:
        return const Center(
          child: SpinKitPulse(
            color: Colors.white70,
            size: 80,
          ),
        );
      case OrbState.idle:
      default:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Opacity(
              opacity: 0.5 + (math.sin(value * math.pi) * 0.2),
              child: const Icon(
                Icons.mic_none_rounded,
                color: Colors.white,
                size: 56,
              ),
            );
          },
        );
    }
  }

  Color _getMainColor(OrbState state) {
    switch (state) {
      case OrbState.listening: return AuraTheme.accentBlue;
      case OrbState.thinking: return AuraTheme.accentPastelPurple;
      case OrbState.speaking: return Colors.white;
      default: return Colors.white12;
    }
  }

  List<Color> _getOrbColors(OrbState state) {
    switch (state) {
      case OrbState.listening:
        return [AuraTheme.accentBlue.withOpacity(0.8), AuraTheme.accentBlue.withOpacity(0.3)];
      case OrbState.thinking:
        return [AuraTheme.accentPastelPurple.withOpacity(0.8), AuraTheme.accentPastelPurple.withOpacity(0.3)];
      case OrbState.speaking:
        return [AuraTheme.accentBlue, AuraTheme.accentBlue.withOpacity(0.5)];
      default:
        return [AuraTheme.textSecondary.withOpacity(0.1), AuraTheme.background];
    }
  }
}
