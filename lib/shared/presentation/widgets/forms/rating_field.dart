/// Interactive star rating input widget with advanced features
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Rating display mode
enum RatingDisplayMode {
  /// Interactive rating input
  interactive,
  /// Read-only display
  readOnly,
  /// Display with statistics
  withStats,
}

/// Rating statistics data
class RatingStats {
  final double averageRating;
  final int totalRatings;
  final Map<int, int>? ratingDistribution;
  final String? label;
  
  const RatingStats({
    required this.averageRating,
    required this.totalRatings,
    this.ratingDistribution,
    this.label,
  });
  
  String get formattedAverage => averageRating.toStringAsFixed(1);
  String get formattedCount => totalRatings > 999 
      ? '${(totalRatings / 1000).toStringAsFixed(1)}k'
      : totalRatings.toString();
}

/// Interactive star rating widget with half-star support
class RatingField extends StatefulWidget {
  final double? initialRating;
  final int maxRating;
  final bool allowHalfRating;
  final bool allowClear;
  final RatingDisplayMode mode;
  final ValueChanged<double?>? onRatingChanged;
  final VoidCallback? onRatingCleared;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? hoverColor;
  final double size;
  final double spacing;
  final IconData? starIcon;
  final IconData? halfStarIcon;
  final IconData? emptyStarIcon;
  final RatingStats? stats;
  final Duration animationDuration;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final EdgeInsets padding;
  final MainAxisAlignment alignment;
  final bool showTooltip;
  final List<String>? ratingLabels;
  final TextStyle? labelStyle;
  final bool enableHapticFeedback;
  
  const RatingField({
    super.key,
    this.initialRating,
    this.maxRating = 5,
    this.allowHalfRating = false,
    this.allowClear = true,
    this.mode = RatingDisplayMode.interactive,
    this.onRatingChanged,
    this.onRatingCleared,
    this.activeColor,
    this.inactiveColor,
    this.hoverColor,
    this.size = 32.0,
    this.spacing = 4.0,
    this.starIcon = Icons.star,
    this.halfStarIcon = Icons.star_half,
    this.emptyStarIcon = Icons.star_border,
    this.stats,
    this.animationDuration = const Duration(milliseconds: 200),
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.padding = const EdgeInsets.all(8.0),
    this.alignment = MainAxisAlignment.start,
    this.showTooltip = true,
    this.ratingLabels,
    this.labelStyle,
    this.enableHapticFeedback = true,
  });
  
  @override
  State<RatingField> createState() => _RatingFieldState();
}

class _RatingFieldState extends State<RatingField>
    with TickerProviderStateMixin {
  double? _currentRating;
  double? _hoverRating;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  final List<AnimationController> _starControllers = [];
  final List<Animation<double>> _starAnimations = [];
  
  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _setupAnimations();
    _setupStarAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }
  
  void _setupStarAnimations() {
    _starControllers.clear();
    _starAnimations.clear();
    
    for (int i = 0; i < widget.maxRating; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 200 + (i * 50)),
        vsync: this,
      );
      
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
      
      _starControllers.add(controller);
      _starAnimations.add(animation);
    }
    
    // Animate stars on mount
    _animateStars();
  }
  
  void _animateStars() async {
    for (int i = 0; i < _starControllers.length; i++) {
      _starControllers[i].forward();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
  
  @override
  void didUpdateWidget(RatingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.initialRating != oldWidget.initialRating) {
      setState(() {
        _currentRating = widget.initialRating;
      });
    }
    
    if (widget.maxRating != oldWidget.maxRating) {
      _setupStarAnimations();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    for (final controller in _starControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: widget.labelStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          _buildRatingWidget(),
          
          if (widget.stats != null && widget.mode == RatingDisplayMode.withStats) ...[
            const SizedBox(height: 8),
            _buildStatsWidget(),
          ],
          
          if (widget.helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.helperText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          
          if (widget.errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildRatingWidget() {
    return Row(
      mainAxisAlignment: widget.alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(widget.maxRating, (index) => _buildStar(index + 1)),
        
        if (widget.allowClear && _currentRating != null && widget.mode == RatingDisplayMode.interactive) ...[
          const SizedBox(width: 8),
          _buildClearButton(),
        ],
        
        if (_currentRating != null && widget.ratingLabels != null) ...[
          const SizedBox(width: 12),
          _buildRatingLabel(),
        ],
      ],
    );
  }
  
  Widget _buildStar(int position) {
    final isActive = _getStarState(position);
    final animationIndex = position - 1;
    
    Color starColor;
    IconData starIcon;
    
    if (isActive == StarState.full) {
      starColor = widget.activeColor ?? Colors.amber;
      starIcon = widget.starIcon!;
    } else if (isActive == StarState.half) {
      starColor = widget.activeColor ?? Colors.amber;
      starIcon = widget.halfStarIcon!;
    } else {
      starColor = widget.inactiveColor ?? Colors.grey[300]!;
      starIcon = widget.emptyStarIcon!;
    }
    
    // Apply hover color if hovering
    if (_hoverRating != null && position <= _hoverRating!) {
      starColor = widget.hoverColor ?? (widget.activeColor ?? Colors.amber).withOpacity(0.8);
    }
    
    Widget star = AnimatedBuilder(
      animation: animationIndex < _starAnimations.length 
          ? _starAnimations[animationIndex] 
          : _animationController,
      builder: (context, child) {
        final scale = animationIndex < _starAnimations.length 
            ? _starAnimations[animationIndex].value 
            : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: Icon(
            starIcon,
            size: widget.size,
            color: starColor,
          ),
        );
      },
    );
    
    if (widget.mode == RatingDisplayMode.interactive && widget.enabled) {
      star = MouseRegion(
        onEnter: (_) => _handleHover(position.toDouble()),
        onExit: (_) => _handleHoverExit(),
        child: GestureDetector(
          onTap: () => _handleTap(position.toDouble()),
          onPanUpdate: (details) => _handlePanUpdate(details, position),
          child: star,
        ),
      );
    }
    
    if (widget.showTooltip && widget.mode == RatingDisplayMode.interactive) {
      star = Tooltip(
        message: _getTooltipMessage(position),
        child: star,
      );
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
      child: star,
    );
  }
  
  Widget _buildClearButton() {
    return GestureDetector(
      onTap: _clearRating,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.close,
          size: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }
  
  Widget _buildRatingLabel() {
    final rating = (_hoverRating ?? _currentRating ?? 0).round();
    final label = rating > 0 && rating <= widget.ratingLabels!.length
        ? widget.ratingLabels![rating - 1]
        : '';
    
    return AnimatedOpacity(
      opacity: label.isNotEmpty ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: widget.activeColor ?? Colors.amber[700],
        ),
      ),
    );
  }
  
  Widget _buildStatsWidget() {
    final stats = widget.stats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              stats.formattedAverage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            
            // Small stars showing average
            ...List.generate(5, (index) {
              final starValue = index + 1;
              return Icon(
                starValue <= stats.averageRating
                    ? widget.starIcon
                    : (starValue - 0.5 <= stats.averageRating
                        ? widget.halfStarIcon
                        : widget.emptyStarIcon),
                size: 14,
                color: starValue <= stats.averageRating + 0.5
                    ? widget.activeColor ?? Colors.amber
                    : Colors.grey[300],
              );
            }),
            
            const SizedBox(width: 8),
            Text(
              '(${stats.formattedCount})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        if (stats.label != null) ...[
          const SizedBox(height: 4),
          Text(
            stats.label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        
        if (stats.ratingDistribution != null) ...[
          const SizedBox(height: 8),
          _buildRatingDistribution(stats),
        ],
      ],
    );
  }
  
  Widget _buildRatingDistribution(RatingStats stats) {
    final distribution = stats.ratingDistribution!;
    final maxCount = distribution.values.isEmpty ? 1 : distribution.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: List.generate(5, (index) {
        final star = 5 - index;
        final count = distribution[star] ?? 0;
        final percentage = maxCount > 0 ? count / maxCount : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Text('$star', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 4),
              Icon(widget.starIcon, size: 12, color: widget.activeColor ?? Colors.amber),
              const SizedBox(width: 8),
              
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.activeColor ?? Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
  
  StarState _getStarState(int position) {
    final rating = _hoverRating ?? _currentRating ?? 0;
    
    if (position <= rating) {
      return StarState.full;
    } else if (widget.allowHalfRating && position - 0.5 <= rating) {
      return StarState.half;
    } else {
      return StarState.empty;
    }
  }
  
  void _handleHover(double rating) {
    if (!widget.enabled) return;
    
    setState(() {
      _hoverRating = rating;
    });
  }
  
  void _handleHoverExit() {
    if (!widget.enabled) return;
    
    setState(() {
      _hoverRating = null;
    });
  }
  
  void _handleTap(double rating) {
    if (!widget.enabled) return;
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    setState(() {
      if (_currentRating == rating && widget.allowClear) {
        _currentRating = null;
      } else {
        _currentRating = rating;
      }
      _hoverRating = null;
    });
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    widget.onRatingChanged?.call(_currentRating);
  }
  
  void _handlePanUpdate(DragUpdateDetails details, int position) {
    if (!widget.enabled || !widget.allowHalfRating) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // Calculate which star and which half
    final starIndex = (localPosition.dx / (widget.size + widget.spacing)).floor();
    final starPosition = localPosition.dx - (starIndex * (widget.size + widget.spacing));
    final isLeftHalf = starPosition < widget.size / 2;
    
    double newRating = (starIndex + 1).toDouble();
    if (isLeftHalf && widget.allowHalfRating) {
      newRating -= 0.5;
    }
    
    newRating = newRating.clamp(0.5, widget.maxRating.toDouble());
    
    if (newRating != _hoverRating) {
      setState(() {
        _hoverRating = newRating;
      });
    }
  }
  
  void _clearRating() {
    if (!widget.enabled) return;
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    setState(() {
      _currentRating = null;
      _hoverRating = null;
    });
    
    widget.onRatingChanged?.call(null);
    widget.onRatingCleared?.call();
  }
  
  String _getTooltipMessage(int position) {
    if (widget.ratingLabels != null && position <= widget.ratingLabels!.length) {
      return '${widget.ratingLabels![position - 1]} ($position star${position > 1 ? 's' : ''})';
    }
    return '$position star${position > 1 ? 's' : ''}';
  }
}

enum StarState {
  full,
  half,
  empty,
}

/// Extension methods for easy RatingField creation
extension RatingFieldExtensions on RatingField {
  /// Create a simple star rating
  static RatingField simple({
    double? initialRating,
    int maxRating = 5,
    ValueChanged<double?>? onChanged,
    String? label,
  }) {
    return RatingField(
      initialRating: initialRating,
      maxRating: maxRating,
      onRatingChanged: onChanged,
      label: label,
      size: 24,
      spacing: 2,
    );
  }
  
  /// Create a detailed rating with half-stars
  static RatingField detailed({
    double? initialRating,
    int maxRating = 5,
    ValueChanged<double?>? onChanged,
    String? label,
    List<String>? ratingLabels,
  }) {
    return RatingField(
      initialRating: initialRating,
      maxRating: maxRating,
      allowHalfRating: true,
      onRatingChanged: onChanged,
      label: label,
      ratingLabels: ratingLabels,
      size: 32,
      spacing: 4,
      showTooltip: true,
    );
  }
  
  /// Create a display-only rating with stats
  static RatingField display({
    required RatingStats stats,
    String? label,
    double size = 20,
  }) {
    return RatingField(
      initialRating: stats.averageRating,
      mode: RatingDisplayMode.withStats,
      stats: stats,
      label: label,
      size: size,
      enabled: false,
    );
  }
  
  /// Create a compact rating for lists
  static RatingField compact({
    double? rating,
    int maxRating = 5,
    bool readOnly = true,
  }) {
    return RatingField(
      initialRating: rating,
      maxRating: maxRating,
      mode: readOnly ? RatingDisplayMode.readOnly : RatingDisplayMode.interactive,
      size: 16,
      spacing: 1,
      padding: EdgeInsets.zero,
    );
  }
}

/// Predefined rating configurations
class RatingPresets {
  /// Skill level rating (1-10 scale)
  static RatingField skillLevel({
    double? initialRating,
    ValueChanged<double?>? onChanged,
    String skillName = 'Skill Level',
  }) {
    return RatingField(
      initialRating: initialRating,
      maxRating: 10,
      allowHalfRating: true,
      onRatingChanged: onChanged,
      label: skillName,
      ratingLabels: const [
        'Terrible', 'Poor', 'Below Average', 'Average', 'Good',
        'Very Good', 'Great', 'Excellent', 'Outstanding', 'Perfect'
      ],
      size: 24,
      activeColor: Colors.blue,
      enableHapticFeedback: true,
    );
  }
  
  /// Experience rating (1-5 scale)
  static RatingField experience({
    double? initialRating,
    ValueChanged<double?>? onChanged,
    String label = 'Experience Level',
  }) {
    return RatingField(
      initialRating: initialRating,
      maxRating: 5,
      onRatingChanged: onChanged,
      label: label,
      ratingLabels: const [
        'Beginner',
        'Novice', 
        'Intermediate',
        'Advanced',
        'Expert'
      ],
      activeColor: Colors.green,
      size: 28,
    );
  }
  
  /// Game/match rating
  static RatingField gameRating({
    double? initialRating,
    ValueChanged<double?>? onChanged,
    String label = 'Rate this Game',
  }) {
    return RatingField(
      initialRating: initialRating,
      maxRating: 5,
      allowHalfRating: true,
      onRatingChanged: onChanged,
      label: label,
      ratingLabels: const [
        'Terrible',
        'Poor', 
        'Average',
        'Good',
        'Excellent'
      ],
      activeColor: Colors.orange,
      size: 32,
      allowClear: true,
    );
  }
  
  /// Facility rating with stats
  static RatingField facilityRating({
    required RatingStats stats,
    String label = 'Facility Rating',
  }) {
    return RatingField(
      initialRating: stats.averageRating,
      mode: RatingDisplayMode.withStats,
      stats: stats,
      label: label,
      maxRating: 5,
      size: 20,
      activeColor: Colors.indigo,
    );
  }
}
