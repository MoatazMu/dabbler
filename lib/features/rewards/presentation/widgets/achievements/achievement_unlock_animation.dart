import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/achievement.dart';
import '../../../domain/entities/user_progress.dart';

enum CelebrationTheme {
  classic,
  confetti,
  burst,
  sparkle,
  fireworks,
}

class AchievementUnlockAnimation extends StatefulWidget {
  final Achievement achievement;
  final UserProgress userProgress;
  final CelebrationTheme theme;
  final bool showPointsAnimation;
  final bool enableSoundEffects;
  final bool enableHapticFeedback;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;
  final VoidCallback? onDismiss;

  const AchievementUnlockAnimation({
    super.key,
    required this.achievement,
    required this.userProgress,
    this.theme = CelebrationTheme.confetti,
    this.showPointsAnimation = true,
    this.enableSoundEffects = true,
    this.enableHapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: 3000),
    this.onAnimationComplete,
    this.onDismiss,
  });

  @override
  State<AchievementUnlockAnimation> createState() => _AchievementUnlockAnimationState();
}

class _AchievementUnlockAnimationState extends State<AchievementUnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pointsController;
  late AnimationController _glowController;

  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<int> _pointsAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _confettiAnimation;

  final List<ConfettiParticle> _confettiParticles = [];
  final List<BurstParticle> _burstParticles = [];
  final List<SparkleParticle> _sparkleParticles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticles();
    _startAnimation();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.bounceOut,
    ));

    _pointsAnimation = IntTween(
      begin: 0,
      end: widget.achievement.points,
    ).animate(CurvedAnimation(
      parent: _pointsController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOutQuart,
    ));
  }

  void _initializeParticles() {
    final random = math.Random();
    
    // Initialize confetti particles
    for (int i = 0; i < 50; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        color: _getRandomColor(),
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * 2 * math.pi,
        velocity: Offset(
          (random.nextDouble() - 0.5) * 200,
          random.nextDouble() * -300 - 100,
        ),
      ));
    }

    // Initialize burst particles
    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * math.pi;
      _burstParticles.add(BurstParticle(
        angle: angle,
        distance: 0,
        maxDistance: random.nextDouble() * 150 + 100,
        color: _getRandomColor(),
        size: random.nextDouble() * 6 + 3,
      ));
    }

    // Initialize sparkle particles
    for (int i = 0; i < 20; i++) {
      _sparkleParticles.add(SparkleParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        color: Colors.white,
        size: random.nextDouble() * 4 + 2,
        opacity: random.nextDouble(),
        twinkleSpeed: random.nextDouble() * 2 + 1,
      ));
    }
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  void _startAnimation() async {
    if (widget.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }

    // Start animations in sequence
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    _glowController.repeat(reverse: true);
    
    await Future.delayed(const Duration(milliseconds: 400));
    _confettiController.forward();
    
    if (widget.showPointsAnimation) {
      await Future.delayed(const Duration(milliseconds: 600));
      _pointsController.forward();
    }

    _mainController.forward();

    // Auto-dismiss after animation completes
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (widget.onAnimationComplete != null) {
            widget.onAnimationComplete!();
          }
          _dismiss();
        });
      }
    });
  }

  void _dismiss() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pointsController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: GestureDetector(
        onTap: _dismiss,
        child: Stack(
          children: [
            // Particle effects background
            _buildParticleEffects(),
            
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _slideAnimation,
                  _scaleAnimation,
                  _glowAnimation,
                ]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 200),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildAchievementCard(),
                    ),
                  );
                },
              ),
            ),

            // Points animation
            if (widget.showPointsAnimation)
              _buildPointsAnimation(),

            // Dismiss hint
            _buildDismissHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticleEffects() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: ParticleEffectsPainter(
            confettiParticles: _confettiParticles,
            burstParticles: _burstParticles,
            sparkleParticles: _sparkleParticles,
            animation: _confettiAnimation.value,
            theme: widget.theme,
          ),
        );
      },
    );
  }

  Widget _buildAchievementCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(int.parse('0xFF${widget.achievement.getTierColorHex().substring(1)}')).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: _glowAnimation.value * 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Achievement unlocked title
          Text(
            'Achievement Unlocked!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Color(int.parse('0xFF${widget.achievement.getTierColorHex().substring(1)}')),
            ),
          ),

          const SizedBox(height: 16),

          // Achievement icon/badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(int.parse('0xFF${widget.achievement.getTierColorHex().substring(1)}')),
                  Color(int.parse('0xFF${widget.achievement.getTierColorHex().substring(1)}')).withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(int.parse('0xFF${widget.achievement.getTierColorHex().substring(1)}')).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: _glowAnimation.value * 5,
                ),
              ],
            ),
            child: Icon(
              _getAchievementIcon(),
              size: 40,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Achievement title
          Text(
            widget.achievement.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Achievement description
          Text(
            widget.achievement.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${widget.achievement.getTierColorHex().substring(1)}')).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color(int.parse('0xFF${widget.achievement.getTierColorHex().substring(1)}')),
                width: 1,
              ),
            ),
            child: Text(
              widget.achievement.tier.toString().split('.').last.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(int.parse('0xFF${widget.achievement.getTierColorHex().substring(1)}')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsAnimation() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.35,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pointsAnimation,
        builder: (context, child) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${_pointsAnimation.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDismissHint() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Tap anywhere to continue',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  IconData _getAchievementIcon() {
    switch (widget.achievement.category) {
      case AchievementCategory.gaming:
        return Icons.sports_esports;
      case AchievementCategory.gameParticipation:
        return Icons.sports_esports;
      case AchievementCategory.social:
        return Icons.people;
      case AchievementCategory.profile:
        return Icons.person;
      case AchievementCategory.venue:
        return Icons.location_on;
      case AchievementCategory.engagement:
        return Icons.favorite;
      case AchievementCategory.skillPerformance:
        return Icons.trending_up;
      case AchievementCategory.milestone:
        return Icons.flag;
      case AchievementCategory.special:
        return Icons.star;
    }
  }
}

class ParticleEffectsPainter extends CustomPainter {
  final List<ConfettiParticle> confettiParticles;
  final List<BurstParticle> burstParticles;
  final List<SparkleParticle> sparkleParticles;
  final double animation;
  final CelebrationTheme theme;

  ParticleEffectsPainter({
    required this.confettiParticles,
    required this.burstParticles,
    required this.sparkleParticles,
    required this.animation,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme) {
      case CelebrationTheme.confetti:
        _paintConfetti(canvas, size);
        break;
      case CelebrationTheme.burst:
        _paintBurst(canvas, size);
        break;
      case CelebrationTheme.sparkle:
        _paintSparkle(canvas, size);
        break;
      case CelebrationTheme.fireworks:
        _paintFireworks(canvas, size);
        break;
      case CelebrationTheme.classic:
        _paintConfetti(canvas, size);
        _paintSparkle(canvas, size);
        break;
    }
  }

  void _paintConfetti(Canvas canvas, Size size) {
    for (final particle in confettiParticles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - animation)
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width + particle.velocity.dx * animation;
      final y = particle.y * size.height + particle.velocity.dy * animation;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + animation * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintBurst(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in burstParticles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - animation)
        ..style = PaintingStyle.fill;

      final distance = particle.maxDistance * animation;
      final x = center.dx + math.cos(particle.angle) * distance;
      final y = center.dy + math.sin(particle.angle) * distance;

      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1.0 - animation * 0.5),
        paint,
      );
    }
  }

  void _paintSparkle(Canvas canvas, Size size) {
    for (final particle in sparkleParticles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(
          particle.opacity * math.sin(animation * math.pi * particle.twinkleSpeed),
        )
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width;
      final y = particle.y * size.height;

      // Draw sparkle as a star shape
      _drawStar(canvas, Offset(x, y), particle.size, paint);
    }
  }

  void _paintFireworks(Canvas canvas, Size size) {
    // Combine burst and sparkle effects for fireworks
    _paintBurst(canvas, size);
    _paintSparkle(canvas, size);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi) / 5;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ParticleEffectsPainter oldDelegate) => animation != oldDelegate.animation;
}

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double rotation;
  final Offset velocity;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.velocity,
  });
}

class BurstParticle {
  final double angle;
  final double distance;
  final double maxDistance;
  final Color color;
  final double size;

  BurstParticle({
    required this.angle,
    required this.distance,
    required this.maxDistance,
    required this.color,
    required this.size,
  });
}

class SparkleParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double opacity;
  final double twinkleSpeed;

  SparkleParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.opacity,
    required this.twinkleSpeed,
  });
}