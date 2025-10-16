import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final VoidCallback? onTap;
  final Color? shadowColor;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.borderRadius = 12.0,
    this.padding,
    this.margin,
    this.elevation,
    this.onTap,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: begin,
          end: end,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevation != null ? [
          BoxShadow(
            color: shadowColor ?? Colors.black.withOpacity(0.1),
            blurRadius: elevation! * 2,
            offset: Offset(0, elevation!),
          ),
        ] : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

// Predefined gradient cards
class RewardGradientCard extends StatelessWidget {
  final Widget child;
  final String tier;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const RewardGradientCard({
    super.key,
    required this.child,
    this.tier = 'bronze',
    this.padding,
    this.margin,
    this.onTap,
  });

  List<Color> _getTierColors(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return [
          const Color(0xFFCD7F32),
          const Color(0xFFA0522D),
        ];
      case 'silver':
        return [
          const Color(0xFFC0C0C0),
          const Color(0xFF808080),
        ];
      case 'gold':
        return [
          const Color(0xFFFFD700),
          const Color(0xFFB8860B),
        ];
      case 'platinum':
        return [
          const Color(0xFFE5E4E2),
          const Color(0xFF9C9C9C),
        ];
      case 'diamond':
        return [
          const Color(0xFFB9F2FF),
          const Color(0xFF4A90E2),
        ];
      default:
        return [
          Colors.blue.shade400,
          Colors.blue.shade600,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: _getTierColors(tier),
      padding: padding,
      margin: margin,
      onTap: onTap,
      elevation: 4,
      child: child,
    );
  }
}

class SuccessGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const SuccessGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: [
        Colors.green.shade400,
        Colors.green.shade600,
      ],
      padding: padding,
      margin: margin,
      onTap: onTap,
      elevation: 2,
      child: child,
    );
  }
}

class WarningGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const WarningGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: [
        Colors.orange.shade400,
        Colors.orange.shade600,
      ],
      padding: padding,
      margin: margin,
      onTap: onTap,
      elevation: 2,
      child: child,
    );
  }
}

class ErrorGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const ErrorGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: [
        Colors.red.shade400,
        Colors.red.shade600,
      ],
      padding: padding,
      margin: margin,
      onTap: onTap,
      elevation: 2,
      child: child,
    );
  }
}

// Animated gradient card
class AnimatedGradientCard extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AnimatedGradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.duration = const Duration(seconds: 3),
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  State<AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GradientCard(
          colors: widget.colors,
          begin: Alignment.lerp(
            Alignment.topLeft,
            Alignment.topRight,
            _animation.value,
          )!,
          end: Alignment.lerp(
            Alignment.bottomRight,
            Alignment.bottomLeft,
            _animation.value,
          )!,
          padding: widget.padding,
          margin: widget.margin,
          onTap: widget.onTap,
          elevation: 4,
          child: widget.child,
        );
      },
    );
  }
}