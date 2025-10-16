import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget that displays confetti celebration animation
class ConfettiCelebration extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onComplete;

  const ConfettiCelebration({
    super.key,
    this.isPlaying = false,
    this.onComplete,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _particles = _generateParticles();

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startAnimation();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  void _startAnimation() {
    _controller.forward(from: 0).then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  List<ConfettiParticle> _generateParticles() {
    final random = math.Random();
    return List.generate(50, (index) {
      return ConfettiParticle(
        color: _getRandomColor(random),
        startX: random.nextDouble(),
        startY: -0.1,
        endX: random.nextDouble(),
        endY: 1.2,
        rotation: random.nextDouble() * 2 * math.pi,
        size: 4 + random.nextDouble() * 6,
      );
    });
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;
  final double size;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animationValue;

  ConfettiPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      final progress = animationValue;
      final x = _lerp(particle.startX, particle.endX, progress) * size.width;
      final y = _lerp(particle.startY, particle.endY, progress) * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * progress * 4);

      // Draw confetti piece as a small rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}