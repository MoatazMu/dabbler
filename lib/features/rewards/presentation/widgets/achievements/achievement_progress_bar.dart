import 'package:flutter/material.dart';

import '../../../domain/entities/achievement.dart';
import '../../../domain/entities/user_progress.dart';

enum ProgressBarStyle {
  linear,
  circular,
  segmented,
  stacked,
}

class AchievementProgressBar extends StatefulWidget {
  final Achievement achievement;
  final UserProgress userProgress;
  final ProgressBarStyle style;
  final double height;
  final double? width;
  final bool showPercentageText;
  final bool showMilestones;
  final bool showSubCriteria;
  final bool showEstimatedTime;
  final bool enableAnimations;
  final Duration animationDuration;
  final VoidCallback? onComplete;

  const AchievementProgressBar({
    super.key,
    required this.achievement,
    required this.userProgress,
    this.style = ProgressBarStyle.linear,
    this.height = 8.0,
    this.width,
    this.showPercentageText = true,
    this.showMilestones = true,
    this.showSubCriteria = false,
    this.showEstimatedTime = false,
    this.enableAnimations = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<AchievementProgressBar> createState() => _AchievementProgressBarState();
}

class _AchievementProgressBarState extends State<AchievementProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _countController;
  
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<int> _countAnimation;
  
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    _initializeAnimations();
    _updateProgress();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _countController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.enableAnimations) {
      _progressController.addListener(_onProgressUpdate);
      _progressController.addStatusListener(_onProgressStatus);
    }
  }

  void _updateProgress() {
    _targetProgress = widget.userProgress.calculateProgress() / 100;
    
    if (widget.enableAnimations) {
      _countAnimation = IntTween(
        begin: (_currentProgress * 100).round(),
        end: (_targetProgress * 100).round(),
      ).animate(CurvedAnimation(
        parent: _countController,
        curve: Curves.easeOutCubic,
      ));
      
      _progressController.forward();
      _countController.forward();
    } else {
      _currentProgress = _targetProgress;
    }
  }

  void _onProgressUpdate() {
    setState(() {
      _currentProgress = _progressAnimation.value * _targetProgress;
    });
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_targetProgress >= 1.0 && widget.onComplete != null) {
        widget.onComplete!();
        _startPulseAnimation();
      }
    }
  }

  void _startPulseAnimation() {
    if (widget.enableAnimations) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AchievementProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.userProgress != widget.userProgress) {
      _updateProgress();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressIndicator(),
        
        if (widget.showPercentageText || widget.showEstimatedTime)
          const SizedBox(height: 4),
        
        if (widget.showPercentageText || widget.showEstimatedTime)
          _buildProgressInfo(),
        
        if (widget.showSubCriteria)
          const SizedBox(height: 8),
        
        if (widget.showSubCriteria)
          _buildSubCriteriaBreakdown(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    switch (widget.style) {
      case ProgressBarStyle.linear:
        return _buildLinearProgress();
      case ProgressBarStyle.circular:
        return _buildCircularProgress();
      case ProgressBarStyle.segmented:
        return _buildSegmentedProgress();
      case ProgressBarStyle.stacked:
        return _buildStackedProgress();
    }
  }

  Widget _buildLinearProgress() {
    return AnimatedBuilder(
      animation: widget.enableAnimations ? _pulseAnimation : AnimationController(vsync: this),
      builder: (context, child) {
        return Transform.scale(
          scale: _targetProgress >= 1.0 ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              color: Colors.grey[200],
            ),
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    color: Colors.grey[200],
                  ),
                ),
                
                // Progress
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _currentProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      gradient: _getProgressGradient(),
                    ),
                  ),
                ),
                
                // Milestones
                if (widget.showMilestones)
                  _buildMilestoneMarkers(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularProgress() {
    return AnimatedBuilder(
      animation: widget.enableAnimations ? _pulseAnimation : AnimationController(vsync: this),
      builder: (context, child) {
        final size = widget.height * 4; // Circular progress is larger
        
        return Transform.scale(
          scale: _targetProgress >= 1.0 ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: widget.height,
                  color: Colors.grey[200],
                  backgroundColor: Colors.transparent,
                ),
                
                // Progress circle
                CircularProgressIndicator(
                  value: _currentProgress.clamp(0.0, 1.0),
                  strokeWidth: widget.height,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(),
                  ),
                ),
                
                // Percentage text
                if (widget.showPercentageText)
                  _buildCircularPercentageText(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedProgress() {
    final segments = _getProgressSegments();
    
    return AnimatedBuilder(
      animation: widget.enableAnimations ? _pulseAnimation : AnimationController(vsync: this),
      builder: (context, child) {
        return Transform.scale(
          scale: _targetProgress >= 1.0 ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: widget.width ?? double.infinity,
            height: widget.height,
            child: Row(
              children: segments.asMap().entries.map((entry) {
                final index = entry.key;
                final segment = entry.value;
                
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < segments.length - 1 ? 2 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      color: segment.isCompleted
                          ? _getProgressColor()
                          : Colors.grey[200],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStackedProgress() {
    return AnimatedBuilder(
      animation: widget.enableAnimations ? _pulseAnimation : AnimationController(vsync: this),
      builder: (context, child) {
        return Transform.scale(
          scale: _targetProgress >= 1.0 ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: widget.width ?? double.infinity,
            height: widget.height * 2, // Stacked is taller
            child: Column(
              children: _getSubCriteriaProgress(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMilestoneMarkers() {
    final milestones = _getMilestones();
    
    return Row(
      children: milestones.map((milestone) {
        final position = milestone.position;
        final isReached = _currentProgress >= position;
        
        return Positioned(
          left: position * (widget.width ?? 200), // Default width for calculations
          child: Container(
            width: 3,
            height: widget.height + 4,
            decoration: BoxDecoration(
              color: isReached ? _getProgressColor() : Colors.grey[400],
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.showPercentageText)
          AnimatedBuilder(
            animation: widget.enableAnimations ? _countAnimation : AnimationController(vsync: this),
            builder: (context, child) {
              final percentage = widget.enableAnimations 
                  ? _countAnimation.value 
                  : (_currentProgress * 100).round();
              
              return Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(),
                ),
              );
            },
          ),
        
        if (widget.showEstimatedTime)
          Text(
            _getEstimatedTimeText(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildCircularPercentageText() {
    return AnimatedBuilder(
      animation: widget.enableAnimations ? _countAnimation : AnimationController(vsync: this),
      builder: (context, child) {
        final percentage = widget.enableAnimations 
            ? _countAnimation.value 
            : (_currentProgress * 100).round();
        
        return Text(
          '$percentage%',
          style: TextStyle(
            fontSize: widget.height,
            fontWeight: FontWeight.bold,
            color: _getProgressColor(),
          ),
        );
      },
    );
  }

  Widget _buildSubCriteriaBreakdown() {
    final criteria = widget.userProgress.currentProgress;
    final required = widget.userProgress.requiredProgress;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: criteria.keys.map((key) {
        final current = criteria[key] as num? ?? 0;
        final req = required[key] as num? ?? 1;
        final progress = (current / req).clamp(0.0, 1.0);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCriteriaName(key),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${current.toInt()}/${req.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey[200],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: _getProgressColor().withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  LinearGradient _getProgressGradient() {
    final baseColor = _getProgressColor();
    return LinearGradient(
      colors: [
        baseColor.withOpacity(0.8),
        baseColor,
        baseColor.withOpacity(0.9),
      ],
    );
  }

  Color _getProgressColor() {
    if (_targetProgress >= 1.0) {
      return Colors.green;
    }
    
    // Color based on achievement tier
    return Color(int.parse(
      '0xFF${widget.achievement.getTierColorHex().substring(1)}',
    ));
  }

  List<ProgressSegment> _getProgressSegments() {
    // Create segments based on criteria or default to 5 segments
    final criteria = widget.userProgress.requiredProgress;
    final segmentCount = criteria.isNotEmpty ? criteria.length : 5;
    
    final segments = <ProgressSegment>[];
    for (int i = 0; i < segmentCount; i++) {
      final segmentProgress = (i + 1) / segmentCount;
      segments.add(ProgressSegment(
        index: i,
        isCompleted: _currentProgress >= segmentProgress,
        progress: (_currentProgress * segmentCount - i).clamp(0.0, 1.0),
      ));
    }
    
    return segments;
  }

  List<Widget> _getSubCriteriaProgress() {
    final criteria = widget.userProgress.currentProgress;
    final required = widget.userProgress.requiredProgress;
    
    return criteria.keys.map((key) {
      final current = criteria[key] as num? ?? 0;
      final req = required[key] as num? ?? 1;
      final progress = (current / req).clamp(0.0, 1.0);
      
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _getProgressColor(),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Milestone> _getMilestones() {
    // Create milestones at 25%, 50%, 75%
    return [
      Milestone(position: 0.25, label: '25%'),
      Milestone(position: 0.50, label: '50%'),
      Milestone(position: 0.75, label: '75%'),
    ];
  }

  String _getEstimatedTimeText() {
    final progress = _currentProgress;
    if (progress >= 1.0) return 'Complete!';
    if (progress == 0.0) return 'Not started';
    
    // Simple estimation based on current progress rate
    // This is a placeholder - in a real app, you'd have more sophisticated logic
    final daysElapsed = DateTime.now().difference(widget.userProgress.startedAt).inDays;
    if (daysElapsed == 0) return 'Just started';
    
    final progressPerDay = progress / daysElapsed;
    if (progressPerDay == 0) return 'On hold';
    
    final remainingProgress = 1.0 - progress;
    final estimatedDays = (remainingProgress / progressPerDay).ceil();
    
    if (estimatedDays <= 1) return 'Almost done!';
    if (estimatedDays <= 7) return '$estimatedDays days left';
    if (estimatedDays <= 30) return '${(estimatedDays / 7).ceil()} weeks left';
    
    return '${(estimatedDays / 30).ceil()} months left';
  }

  String _formatCriteriaName(String key) {
    return key.split('_')
        .map((word) => word.isEmpty ? '' : 
             word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class ProgressSegment {
  final int index;
  final bool isCompleted;
  final double progress;

  const ProgressSegment({
    required this.index,
    required this.isCompleted,
    required this.progress,
  });
}

class Milestone {
  final double position;
  final String label;

  const Milestone({
    required this.position,
    required this.label,
  });
}