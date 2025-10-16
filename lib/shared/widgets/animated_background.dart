import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final int particleCount;
  final AnimationController animationController;
  final bool showGradient;

  const AnimatedBackground({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    this.particleCount = 20,
    required this.animationController,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        if (showGradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.05),
                ],
              ),
            ),
          ),

        // Animated particles
        AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: AnimatedBackgroundPainter(
                animationValue: animationController.value,
                primaryColor: primaryColor,
                particleCount: particleCount,
              ),
              size: MediaQuery.of(context).size,
            );
          },
        ),
      ],
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final int particleCount;

  AnimatedBackgroundPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final progress = (animationValue + i / particleCount) % 1.0;
      final opacity = (1.0 - progress) * 0.3;
      
      paint.color = primaryColor.withOpacity(opacity);

      // Calculate position with sine wave movement
      final x = (size.width * (i / particleCount) + 
                math.sin(progress * 2 * math.pi + i) * 30) % size.width;
      final y = size.height * (1 - progress);
      
      // Vary particle size based on position
      final radius = 1 + math.sin(progress * math.pi) * 2;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }

    // Draw some larger, slower moving particles for depth
    for (int i = 0; i < (particleCount ~/ 3); i++) {
      final progress = (animationValue * 0.5 + i / particleCount) % 1.0;
      final opacity = (1.0 - progress) * 0.1;
      
      paint.color = primaryColor.withOpacity(opacity);

      final x = (size.width * 0.2 + size.width * 0.6 * (i / (particleCount ~/ 3)) + 
                math.cos(progress * math.pi + i * 2) * 50) % size.width;
      final y = size.height * (1 - progress);
      final radius = 3 + math.sin(progress * math.pi) * 3;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Floating orb widget for special effects
class FloatingOrb extends StatelessWidget {
  final Color color;
  final double size;
  final Duration duration;
  final Offset startPosition;
  final Offset endPosition;

  const FloatingOrb({
    super.key,
    required this.color,
    this.size = 20.0,
    this.duration = const Duration(seconds: 3),
    required this.startPosition,
    required this.endPosition,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: startPosition, end: endPosition),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, position, child) {
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Shimmer background for loading states
class ShimmerBackground extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerBackground({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFEBEBF4),
    this.highlightColor = const Color(0xFFF4F4F4),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}