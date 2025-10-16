import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Optimistic loading overlay for game actions
class OptimisticGameActionOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String loadingMessage;
  final VoidCallback? onCancel;

  const OptimisticGameActionOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage = 'Processing...',
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Original content with opacity when loading
        AnimatedOpacity(
          opacity: isLoading ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AbsorbPointer(
            absorbing: isLoading,
            child: child,
          ),
        ),
        
        // Loading overlay
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loadingMessage,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (onCancel != null) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: onCancel,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pulsing animation for game cards during optimistic updates
class PulsingGameCard extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Duration pulseDuration;

  const PulsingGameCard({
    super.key,
    required this.child,
    this.isPulsing = false,
    this.pulseDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<PulsingGameCard> createState() => _PulsingGameCardState();
}

class _PulsingGameCardState extends State<PulsingGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingGameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(1.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Loading state for map markers while games load
class MapMarkersLoader extends StatefulWidget {
  final int markerCount;

  const MapMarkersLoader({
    super.key,
    this.markerCount = 5,
  });

  @override
  State<MapMarkersLoader> createState() => _MapMarkersLoaderState();
}

class _MapMarkersLoaderState extends State<MapMarkersLoader>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.markerCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 200)),
        vsync: this,
      ),
    );
    
    _animations = _controllers
        .map((controller) => Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            )))
        .toList();

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: 200,
      height: 150,
      child: Stack(
        children: List.generate(widget.markerCount, (index) {
          final random = math.Random(index);
          final left = random.nextDouble() * 150;
          final top = random.nextDouble() * 100;
          
          return Positioned(
            left: left,
            top: top,
            child: AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.5 + (_animations[index].value * 0.5),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

/// Search loading indicator with animated dots
class SearchLoadingIndicator extends StatefulWidget {
  final String searchTerm;

  const SearchLoadingIndicator({
    super.key,
    required this.searchTerm,
  });

  @override
  State<SearchLoadingIndicator> createState() => _SearchLoadingIndicatorState();
}

class _SearchLoadingIndicatorState extends State<SearchLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated search icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: Icon(
                    Icons.search_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Searching for "${widget.searchTerm}"',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final progress = (_controller.value - delay) % 1.0;
                    final opacity = progress < 0.5 
                        ? (progress * 2) 
                        : (2 - progress * 2);
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: math.max(0.3, opacity),
                        child: Text(
                          '•',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress indicator for multi-step game creation
class GameCreationProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const GameCreationProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;
              
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < totalSteps - 1) const SizedBox(width: 8),
                  ],
                ),
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;
              
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: theme.colorScheme.onPrimary,
                        )
                      : Text(
                          '${index + 1}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCurrent
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          // Current step label
          if (currentStep < stepLabels.length)
            Text(
              stepLabels[currentStep],
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
