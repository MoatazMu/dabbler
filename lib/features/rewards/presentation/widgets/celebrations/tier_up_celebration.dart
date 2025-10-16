import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/badge_tier.dart';

/// Tier upgrade data
class TierUpgradeData {
  final BadgeTier oldTier;
  final BadgeTier newTier;
  final String achievementName;
  final String description;
  final List<String> benefitsUnlocked;
  final int pointsRequired;
  final int totalPoints;
  final DateTime upgradedAt;
  final Map<String, dynamic>? metadata;

  const TierUpgradeData({
    required this.oldTier,
    required this.newTier,
    required this.achievementName,
    required this.description,
    required this.benefitsUnlocked,
    required this.pointsRequired,
    required this.totalPoints,
    required this.upgradedAt,
    this.metadata,
  });

  Color get oldTierColor {
    switch (oldTier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  Color get newTierColor {
    switch (newTier) {
      case BadgeTier.bronze:
        return const Color(0xFFCD7F32);
      case BadgeTier.silver:
        return const Color(0xFFC0C0C0);
      case BadgeTier.gold:
        return const Color(0xFFFFD700);
      case BadgeTier.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  IconData get tierIcon {
    switch (newTier) {
      case BadgeTier.bronze:
        return Icons.military_tech;
      case BadgeTier.silver:
        return Icons.workspace_premium;
      case BadgeTier.gold:
        return Icons.emoji_events;
      case BadgeTier.platinum:
        return Icons.diamond;
      case BadgeTier.diamond:
        return Icons.auto_awesome;
    }
  }

  String get formattedPoints {
    return totalPoints.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}



/// Tier up celebration widget
class TierUpCelebration extends StatefulWidget {
  final TierUpgradeData upgradeData;
  final VoidCallback? onContinue;
  final Function(String)? onShare;
  final bool enableSoundEffects;
  final bool enableHaptics;
  final bool enableFireworks;
  final Duration celebrationDuration;

  const TierUpCelebration({
    super.key,
    required this.upgradeData,
    this.onContinue,
    this.onShare,
    this.enableSoundEffects = true,
    this.enableHaptics = true,
    this.enableFireworks = true,
    this.celebrationDuration = const Duration(seconds: 8),
  });

  @override
  State<TierUpCelebration> createState() => _TierUpCelebrationState();
}

class _TierUpCelebrationState extends State<TierUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _tierAnimationController;
  late AnimationController _fireworksController;
  late AnimationController _confettiController;
  late AnimationController _pulseController;

  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tierTransitionAnimation;
  late Animation<double> _benefitsSlideAnimation;
  late Animation<double> _fireworksAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _pulseAnimation;

  bool _showBenefits = false;
  bool _celebrationComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCelebrationSequence();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _tierAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fireworksController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
    ));

    _tierTransitionAnimation = CurvedAnimation(
      parent: _tierAnimationController,
      curve: Curves.easeInOut,
    );

    _benefitsSlideAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _fireworksAnimation = CurvedAnimation(
      parent: _fireworksController,
      curve: Curves.easeInOut,
    );

    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startCelebrationSequence() async {
    // Haptic feedback
    if (widget.enableHaptics) {
      HapticFeedback.heavyImpact();
    }

    // Start main animation
    _mainController.forward();

    // Start tier transition after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _tierAnimationController.forward();
      
      if (widget.enableHaptics) {
        HapticFeedback.mediumImpact();
      }
    });

    // Start fireworks
    if (widget.enableFireworks) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _fireworksController.forward();
      });
    }

    // Start confetti
    Future.delayed(const Duration(milliseconds: 1000), () {
      _confettiController.forward();
    });

    // Start pulse animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      _pulseController.repeat(reverse: true);
    });

    // Show benefits
    Future.delayed(const Duration(milliseconds: 1800), () {
      setState(() {
        _showBenefits = true;
      });
      
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
    });

    // Mark celebration complete
    Future.delayed(widget.celebrationDuration, () {
      setState(() {
        _celebrationComplete = true;
      });
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _tierAnimationController.dispose();
    _fireworksController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          // Background effects
          if (widget.enableFireworks) _buildFireworksBackground(),
          
          // Confetti overlay
          _buildConfettiOverlay(),
          
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCelebrationHeader(),
                  const SizedBox(height: 40),
                  _buildTierTransition(),
                  const SizedBox(height: 40),
                  _buildAchievementDetails(),
                  if (_showBenefits) ...[
                    const SizedBox(height: 32),
                    _buildBenefitsSection(),
                  ],
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireworksBackground() {
    return AnimatedBuilder(
      animation: _fireworksAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: FireworksPainter(
            animation: _fireworksAnimation,
            color: widget.upgradeData.newTierColor,
          ),
        );
      },
    );
  }

  Widget _buildConfettiOverlay() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(
            animation: _confettiAnimation,
            colors: [
              widget.upgradeData.newTierColor,
              Colors.amber,
              Colors.orange,
              Colors.pink,
              Colors.purple,
            ],
          ),
        );
      },
    );
  }

  Widget _buildCelebrationHeader() {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Column(
            children: [
              Text(
                'TIER UP!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: widget.upgradeData.newTierColor,
                  shadows: [
                    Shadow(
                      color: widget.upgradeData.newTierColor.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Congratulations!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTierTransition() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTierBadge(
                      tier: widget.upgradeData.oldTier,
                      color: widget.upgradeData.oldTierColor,
                      isOld: true,
                    ),
                    const SizedBox(width: 40),
                    AnimatedBuilder(
                      animation: _tierTransitionAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(100 * (1 - _tierTransitionAnimation.value), 0),
                          child: Opacity(
                            opacity: _tierTransitionAnimation.value,
                            child: Icon(
                              Icons.arrow_forward,
                              size: 48,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 40),
                    AnimatedBuilder(
                      animation: _tierTransitionAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _tierTransitionAnimation.value,
                          child: _buildTierBadge(
                            tier: widget.upgradeData.newTier,
                            color: widget.upgradeData.newTierColor,
                            isOld: false,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTierBadge({
    required BadgeTier tier,
    required Color color,
    required bool isOld,
  }) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.8),
            color,
            color.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: isOld ? 20 : 40,
            spreadRadius: isOld ? 2 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.upgradeData.tierIcon,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            tier.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementDetails() {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.upgradeData.newTierColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  widget.upgradeData.achievementName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.upgradeData.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.upgradeData.newTierColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars,
                        color: widget.upgradeData.newTierColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.upgradeData.formattedPoints} Points',
                        style: TextStyle(
                          color: widget.upgradeData.newTierColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitsSection() {
    return AnimatedBuilder(
      animation: _benefitsSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _benefitsSlideAnimation.value)),
          child: Opacity(
            opacity: _benefitsSlideAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: widget.upgradeData.newTierColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Benefits Unlocked',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...widget.upgradeData.benefitsUnlocked.asMap().entries.map((entry) {
                    final index = entry.key;
                    final benefit = entry.value;
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < widget.upgradeData.benefitsUnlocked.length - 1 ? 12 : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: widget.upgradeData.newTierColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _benefitsSlideAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _benefitsSlideAnimation.value,
          child: Column(
            children: [
              if (_celebrationComplete) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.upgradeData.newTierColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: () => widget.onShare?.call('tier_upgrade'),
                icon: const Icon(Icons.share),
                label: const Text('Share Achievement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fireworks painter for background effects
class FireworksPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  FireworksPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.screen;

    final random = math.Random(42); // Fixed seed for consistent animation
    
    for (int i = 0; i < 20; i++) {
      final progress = (animation.value + (i * 0.1)) % 1.0;
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble() * 0.7;
      
      paint.color = color.withOpacity((1 - progress) * 0.6);
      
      // Draw expanding circle
      canvas.drawCircle(
        Offset(x, y),
        progress * 100,
        paint,
      );
      
      // Draw particles
      for (int j = 0; j < 8; j++) {
        final angle = (j * math.pi * 2) / 8;
        final particleX = x + math.cos(angle) * progress * 150;
        final particleY = y + math.sin(angle) * progress * 150;
        
        paint.color = color.withOpacity((1 - progress) * 0.8);
        canvas.drawCircle(
          Offset(particleX, particleY),
          (1 - progress) * 4,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Confetti painter for celebration effects
class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Color> colors;

  ConfettiPainter({
    required this.animation,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final random = math.Random(123); // Fixed seed
    
    for (int i = 0; i < 100; i++) {
      final progress = animation.value;
      final startX = size.width * random.nextDouble();
      final startY = -20.0;
      
      final x = startX + (random.nextDouble() - 0.5) * 200 * progress;
      final y = startY + size.height * 1.2 * progress;
      
      paint.color = colors[i % colors.length].withOpacity((1 - progress) * 0.8);
      
      // Different shapes
      switch (i % 3) {
        case 0:
          // Rectangle
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(x, y),
              width: 8,
              height: 12,
            ),
            paint,
          );
          break;
        case 1:
          // Circle
          canvas.drawCircle(Offset(x, y), 4, paint);
          break;
        case 2:
          // Triangle
          final path = Path();
          path.moveTo(x, y - 6);
          path.lineTo(x - 4, y + 6);
          path.lineTo(x + 4, y + 6);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}