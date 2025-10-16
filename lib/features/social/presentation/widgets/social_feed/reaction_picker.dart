import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReactionPicker extends ConsumerStatefulWidget {
  final dynamic post;
  final Function(String) onReactionSelected;
  final Widget child;
  final bool showOnLongPress;

  const ReactionPicker({
    super.key,
    required this.post,
    required this.onReactionSelected,
    required this.child,
    this.showOnLongPress = true,
  });

  @override
  ConsumerState<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends ConsumerState<ReactionPicker>
    with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isShowingReactions = false;

  final List<ReactionData> _reactions = [
    ReactionData('like', '❤️', Colors.red, 'Like'),
    ReactionData('love', '😍', Colors.pink, 'Love'),
    ReactionData('laugh', '😂', Colors.orange, 'Laugh'),
    ReactionData('wow', '😮', Colors.blue, 'Wow'),
    ReactionData('sad', '😢', Colors.blue, 'Sad'),
    ReactionData('angry', '😡', Colors.red, 'Angry'),
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleQuickReaction(),
      onLongPress: widget.showOnLongPress ? _showReactionPicker : null,
      child: widget.child,
    );
  }

  void _handleQuickReaction() {
    HapticFeedback.lightImpact();
    
    // Quick like if no reaction, otherwise show picker
    if (widget.post.currentUserReaction == null) {
      widget.onReactionSelected('like');
      _animateQuickReaction();
    } else {
      // Toggle off current reaction
      widget.onReactionSelected(widget.post.currentUserReaction);
    }
  }

  void _animateQuickReaction() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  void _showReactionPicker() {
    if (_isShowingReactions) return;
    
    HapticFeedback.mediumImpact();
    _isShowingReactions = true;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate position for reaction picker
    double left = offset.dx + (size.width / 2) - 150; // Center picker on widget
    double top = offset.dy - 80; // Show above the widget
    
    // Adjust if picker would go off screen
    if (left < 10) left = 10;
    if (left + 300 > screenSize.width) left = screenSize.width - 310;
    if (top < 50) top = offset.dy + size.height + 10; // Show below if no space above
    
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background overlay
          GestureDetector(
            onTap: _removeOverlay,
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.transparent,
            ),
          ),
          
          // Reaction picker
          Positioned(
            left: left,
            top: top,
            child: _buildReactionPicker(),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionPicker() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _reactions.map((reaction) {
                      return _buildReactionButton(reaction);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionButton(ReactionData reaction) {
    final isSelected = widget.post.currentUserReaction == reaction.type;
    
    return GestureDetector(
      onTap: () => _selectReaction(reaction),
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected 
            ? reaction.color.withOpacity(0.2)
            : Colors.transparent,
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reaction.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: reaction.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectReaction(ReactionData reaction) {
    HapticFeedback.lightImpact();
    widget.onReactionSelected(reaction.type);
    _removeOverlay();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isShowingReactions = false;
      });
    }
  }
}

/// Quick reaction widget that shows floating reactions
class QuickReactionWidget extends StatefulWidget {
  final Offset position;
  final String emoji;
  final Color color;
  final VoidCallback? onComplete;

  const QuickReactionWidget({
    super.key,
    required this.position,
    required this.emoji,
    required this.color,
    this.onComplete,
  });

  @override
  State<QuickReactionWidget> createState() => _QuickReactionWidgetState();
}

class _QuickReactionWidgetState extends State<QuickReactionWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));
    
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -100),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 25,
      top: widget.position.dy - 25,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: _positionAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Reaction count widget
class ReactionCountWidget extends StatefulWidget {
  final Map<String, int> reactions;
  final String? currentUserReaction;
  final VoidCallback? onTap;

  const ReactionCountWidget({
    super.key,
    required this.reactions,
    this.currentUserReaction,
    this.onTap,
  });

  @override
  State<ReactionCountWidget> createState() => _ReactionCountWidgetState();
}

class _ReactionCountWidgetState extends State<ReactionCountWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalReactions = widget.reactions.values.fold(0, (sum, count) => sum + count);
    
    if (totalReactions == 0) {
      return const SizedBox.shrink();
    }
    
    final topReactions = widget.reactions.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return GestureDetector(
      onTap: () {
        _controller.forward().then((_) => _controller.reverse());
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show top 3 reaction emojis
                  ...topReactions.take(3).map((entry) {
                    final emoji = _getEmojiForReaction(entry.key);
                    return Container(
                      margin: const EdgeInsets.only(right: 2),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }),
                  
                  const SizedBox(width: 4),
                  
                  // Total count
                  Text(
                    totalReactions.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
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

  String _getEmojiForReaction(String reaction) {
    switch (reaction) {
      case 'like':
        return '❤️';
      case 'love':
        return '😍';
      case 'laugh':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return '❤️';
    }
  }
}

/// Reaction data class
class ReactionData {
  final String type;
  final String emoji;
  final Color color;
  final String label;

  const ReactionData(this.type, this.emoji, this.color, this.label);
}

/// Animated reaction button
class AnimatedReactionButton extends StatefulWidget {
  final String reaction;
  final int count;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AnimatedReactionButton({
    super.key,
    required this.reaction,
    required this.count,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedReactionButton> createState() => _AnimatedReactionButtonState();
}

class _AnimatedReactionButtonState extends State<AnimatedReactionButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _bounceController;
  late Animation<double> _pressAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate when becoming active
    if (!oldWidget.isActive && widget.isActive) {
      _bounceController.forward().then((_) => _bounceController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressAnimation, _bounceAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value * _bounceAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isActive
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isActive
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getEmojiForReaction(widget.reaction),
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      widget.count.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getEmojiForReaction(String reaction) {
    switch (reaction) {
      case 'like':
        return '❤️';
      case 'love':
        return '😍';
      case 'laugh':
        return '😂';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      default:
        return '❤️';
    }
  }
}
