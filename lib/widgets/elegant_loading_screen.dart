import 'package:flutter/material.dart';

/// Beautiful, elegant loading screen with smooth animations
class ElegantLoadingScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final String? logoPath;
  final Color? accentColor;
  final bool showProgress;
  final bool showPulseAnimation;
  final Duration animationDuration;

  const ElegantLoadingScreen({
    super.key,
    this.title,
    this.subtitle,
    this.logoPath,
    this.accentColor,
    this.showProgress = true,
    this.showPulseAnimation = true,
    this.animationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<ElegantLoadingScreen> createState() => _ElegantLoadingScreenState();
}

class _ElegantLoadingScreenState extends State<ElegantLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    if (widget.showPulseAnimation) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.accentColor ?? theme.colorScheme.primary;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              primaryColor.withOpacity(0.03),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo section with pulse animation
                              if (widget.logoPath != null) ...[
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(28),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.15),
                                              blurRadius: 32,
                                              offset: const Offset(0, 12),
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(28),
                                          child: Image.asset(
                                            widget.logoPath!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 48),
                              ],
                              
                              // Title with fade animation
                              if (widget.title != null) ...[
                                Text(
                                  widget.title!,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.8,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Subtitle with fade animation
                              if (widget.subtitle != null) ...[
                                Text(
                                  widget.subtitle!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.6,
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 56),
                              ],
                              
                              // Elegant loading indicator
                              if (widget.showProgress) ...[
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    backgroundColor: primaryColor.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                  ),
                                ),
                              ],
                              
                              // Decorative animated dots
                              const SizedBox(height: 72),
                              _buildAnimatedDots(primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDots(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final delay = index * 0.2;
              final animationValue = (_pulseController.value + delay) % 1.0;
              final opacity = 0.3 + (0.7 * animationValue);
              final scale = 0.8 + (0.4 * animationValue);
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

/// Minimal loading indicator for inline use
class MinimalLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const MinimalLoadingIndicator({
    super.key,
    this.size = 20.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        backgroundColor: primaryColor.withOpacity(0.1),
      ),
    );
  }
}

/// Simple, clean loading screen for quick use
class SimpleLoadingScreen extends StatelessWidget {
  final String? message;
  final String? logoPath;
  final Color? accentColor;

  const SimpleLoadingScreen({
    super.key,
    this.message,
    this.logoPath,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = accentColor ?? theme.colorScheme.primary;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (logoPath != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  logoPath!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
            ],
            
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                backgroundColor: primaryColor.withOpacity(0.1),
              ),
            ),
            
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
