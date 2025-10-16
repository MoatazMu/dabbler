/// Visual indicator for profile completion status with animated progress
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Profile section completion data
class ProfileSection {
  final String id;
  final String name;
  final String description;
  final bool isCompleted;
  final int totalItems;
  final int completedItems;
  final IconData icon;
  final Color color;
  final List<String> missingItems;
  final DateTime? lastUpdated;
  final bool isRequired;
  
  const ProfileSection({
    required this.id,
    required this.name,
    required this.description,
    required this.isCompleted,
    required this.totalItems,
    required this.completedItems,
    required this.icon,
    required this.color,
    this.missingItems = const [],
    this.lastUpdated,
    this.isRequired = true,
  });
  
  double get completionPercentage => 
      totalItems > 0 ? completedItems / totalItems : 0.0;
  
  ProfileSection copyWith({
    String? id,
    String? name,
    String? description,
    bool? isCompleted,
    int? totalItems,
    int? completedItems,
    IconData? icon,
    Color? color,
    List<String>? missingItems,
    DateTime? lastUpdated,
    bool? isRequired,
  }) {
    return ProfileSection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      totalItems: totalItems ?? this.totalItems,
      completedItems: completedItems ?? this.completedItems,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      missingItems: missingItems ?? this.missingItems,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

/// Milestone configuration for progress indicators
class ProgressMilestone {
  final double percentage;
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final bool showCelebration;
  
  const ProgressMilestone({
    required this.percentage,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    this.showCelebration = false,
  });
  
  static const List<ProgressMilestone> defaultMilestones = [
    ProgressMilestone(
      percentage: 0.25,
      label: 'Getting Started',
      icon: Icons.rocket_launch,
      color: Colors.orange,
      description: 'Basic profile information added',
    ),
    ProgressMilestone(
      percentage: 0.50,
      label: 'Halfway There',
      icon: Icons.timeline,
      color: Colors.blue,
      description: 'Profile is taking shape',
    ),
    ProgressMilestone(
      percentage: 0.75,
      label: 'Almost Done',
      icon: Icons.near_me,
      color: Colors.purple,
      description: 'Just a few more details',
    ),
    ProgressMilestone(
      percentage: 1.0,
      label: 'Complete',
      icon: Icons.celebration,
      color: Colors.green,
      description: 'Your profile is complete!',
      showCelebration: true,
    ),
  ];
}

/// Display mode for completion indicator
enum CompletionDisplayMode {
  linear,
  circular,
  segmented,
  compact,
  expanded,
  card,
}

/// Completion indicator widget with multiple display modes
class CompletionIndicator extends StatefulWidget {
  final List<ProfileSection> sections;
  final CompletionDisplayMode displayMode;
  final bool showMilestones;
  final bool showMissingItems;
  final bool animateChanges;
  final bool enableExpansion;
  final bool showCelebration;
  final VoidCallback? onTap;
  final Function(ProfileSection)? onSectionTap;
  final List<ProgressMilestone> milestones;
  final EdgeInsets padding;
  final double height;
  final double width;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? backgroundColor;
  final Color? progressColor;
  final Duration animationDuration;
  final String title;
  final String subtitle;
  final bool enableHapticFeedback;
  
  const CompletionIndicator({
    super.key,
    required this.sections,
    this.displayMode = CompletionDisplayMode.linear,
    this.showMilestones = true,
    this.showMissingItems = false,
    this.animateChanges = true,
    this.enableExpansion = true,
    this.showCelebration = true,
    this.onTap,
    this.onSectionTap,
    this.milestones = ProgressMilestone.defaultMilestones,
    this.padding = const EdgeInsets.all(16),
    this.height = 60,
    this.width = double.infinity,
    this.titleStyle,
    this.subtitleStyle,
    this.backgroundColor,
    this.progressColor,
    this.animationDuration = const Duration(milliseconds: 800),
    this.title = 'Profile Completion',
    this.subtitle = 'Complete your profile to get better matches',
    this.enableHapticFeedback = true,
  });
  
  @override
  State<CompletionIndicator> createState() => _CompletionIndicatorState();
}

class _CompletionIndicatorState extends State<CompletionIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late AnimationController _expansionController;
  late Animation<double> _progressAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _expansionAnimation;
  
  bool _isExpanded = false;
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;
  bool _showCelebration = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _calculateProgress();
  }
  
  void _setupAnimations() {
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    
    _expansionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.addListener(() {
      setState(() {
        _currentProgress = _targetProgress * _progressAnimation.value;
      });
    });
  }
  
  void _calculateProgress() {
    final totalItems = widget.sections.fold<int>(0, (sum, section) => sum + section.totalItems);
    final completedItems = widget.sections.fold<int>(0, (sum, section) => sum + section.completedItems);
    
    final newProgress = totalItems > 0 ? completedItems / totalItems : 0.0;
    
    if (newProgress != _targetProgress) {
      _targetProgress = newProgress;
      
      if (widget.animateChanges) {
        _progressController.forward(from: _currentProgress / _targetProgress);
      } else {
        _currentProgress = _targetProgress;
      }
      
      // Trigger celebration if reaching 100%
      if (_targetProgress >= 1.0 && widget.showCelebration && !_showCelebration) {
        _showCelebration = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          _celebrationController.forward();
        });
      }
    }
  }
  
  @override
  void didUpdateWidget(CompletionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.sections != oldWidget.sections) {
      _calculateProgress();
    }
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    _expansionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildProgressIndicator(),
          
          if (widget.enableExpansion && (_isExpanded || widget.displayMode == CompletionDisplayMode.expanded))
            _buildExpandedContent(),
          
          if (_showCelebration)
            _buildCelebrationOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return GestureDetector(
      onTap: widget.enableExpansion ? _toggleExpansion : widget.onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.title,
                      style: widget.titleStyle ?? 
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 8),
                    _buildProgressBadge(),
                  ],
                ),
                
                if (widget.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: widget.subtitleStyle ?? 
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ],
            ),
          ),
          
          if (widget.enableExpansion)
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildProgressBadge() {
    final percentage = (_currentProgress * 100).round();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getProgressColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getProgressColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          color: _getProgressColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    switch (widget.displayMode) {
      case CompletionDisplayMode.linear:
        return _buildLinearProgress();
      case CompletionDisplayMode.circular:
        return _buildCircularProgress();
      case CompletionDisplayMode.segmented:
        return _buildSegmentedProgress();
      case CompletionDisplayMode.compact:
        return _buildCompactProgress();
      case CompletionDisplayMode.expanded:
      case CompletionDisplayMode.card:
        return _buildCardProgress();
    }
  }
  
  Widget _buildLinearProgress() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _currentProgress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            minHeight: 8,
          ),
        ),
        
        if (widget.showMilestones) ...[
          const SizedBox(height: 8),
          _buildMilestoneMarkers(),
        ],
      ],
    );
  }
  
  Widget _buildCircularProgress() {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: _currentProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
              strokeWidth: 8,
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_currentProgress * 100).round()}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(),
                  ),
                ),
                
                Text(
                  'Complete',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSegmentedProgress() {
    return Row(
      children: widget.sections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < widget.sections.length - 1 ? 4 : 0,
            ),
            child: _buildSegment(section),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildSegment(ProfileSection section) {
    return GestureDetector(
      onTap: () => widget.onSectionTap?.call(section),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: section.isCompleted 
              ? section.color 
              : section.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              section.icon,
              size: 16,
              color: section.isCompleted ? Colors.white : section.color,
            ),
            const SizedBox(height: 2),
            Text(
              section.name,
              style: TextStyle(
                fontSize: 10,
                color: section.isCompleted ? Colors.white : section.color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactProgress() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _currentProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildCompletedSectionsCount(),
      ],
    );
  }
  
  Widget _buildCompletedSectionsCount() {
    final completedSections = widget.sections.where((s) => s.isCompleted).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$completedSections/${widget.sections.length}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }
  
  Widget _buildCardProgress() {
    return Column(
      children: [
        _buildLinearProgress(),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.sections.map((section) {
            return _buildSectionCard(section);
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSectionCard(ProfileSection section) {
    return GestureDetector(
      onTap: () => widget.onSectionTap?.call(section),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: section.isCompleted 
              ? section.color.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: section.isCompleted 
                ? section.color 
                : Colors.grey[300]!,
            width: section.isCompleted ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              section.isCompleted ? Icons.check_circle : section.icon,
              color: section.isCompleted ? section.color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            
            Text(
              section.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: section.isCompleted ? section.color : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 2),
            Text(
              '${section.completedItems}/${section.totalItems}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMilestoneMarkers() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: widget.milestones.map((milestone) {
        final isReached = _currentProgress >= milestone.percentage;
        
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isReached ? milestone.color : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              
              Text(
                milestone.label,
                style: TextStyle(
                  fontSize: 10,
                  color: isReached ? milestone.color : Colors.grey[600],
                  fontWeight: isReached ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildExpandedContent() {
    return AnimatedBuilder(
      animation: _expansionAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _expansionAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            ...widget.sections.map((section) => _buildSectionDetail(section)),
            
            if (widget.showMissingItems)
              _buildMissingItemsSummary(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionDetail(ProfileSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: section.isCompleted 
            ? section.color.withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: section.isCompleted 
              ? section.color.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: section.isCompleted 
                  ? section.color 
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              section.isCompleted ? Icons.check : section.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      section.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: section.isCompleted 
                            ? section.color 
                            : Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${section.completedItems}/${section.totalItems}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: section.color,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                Text(
                  section.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                
                if (!section.isCompleted && section.missingItems.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: section.missingItems.take(3).map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMissingItemsSummary() {
    final allMissingItems = widget.sections
        .where((section) => !section.isCompleted)
        .expand((section) => section.missingItems)
        .toList();
    
    if (allMissingItems.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              
              Text(
                'Missing Items (${allMissingItems.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allMissingItems.take(8).map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[700],
                  ),
                ),
              );
            }).toList(),
          ),
          
          if (allMissingItems.length > 8) ...[
            const SizedBox(height: 6),
            Text(
              '+${allMissingItems.length - 8} more items',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        if (_celebrationAnimation.value == 0.0) {
          return const SizedBox.shrink();
        }
        
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1 * _celebrationAnimation.value),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Transform.scale(
                scale: _celebrationAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Color _getProgressColor() {
    if (widget.progressColor != null) return widget.progressColor!;
    
    if (_currentProgress >= 1.0) return Colors.green;
    if (_currentProgress >= 0.75) return Colors.blue;
    if (_currentProgress >= 0.50) return Colors.orange;
    return Colors.red;
  }
  
  void _toggleExpansion() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _expansionController.forward();
    } else {
      _expansionController.reverse();
    }
  }
}

/// Extension methods for easy CompletionIndicator creation
extension CompletionIndicatorExtensions on CompletionIndicator {
  /// Create a simple linear progress indicator
  static CompletionIndicator linear({
    required List<ProfileSection> sections,
    String title = 'Profile Completion',
    bool showMilestones = true,
    VoidCallback? onTap,
  }) {
    return CompletionIndicator(
      sections: sections,
      displayMode: CompletionDisplayMode.linear,
      title: title,
      showMilestones: showMilestones,
      onTap: onTap,
    );
  }
  
  /// Create a circular progress indicator
  static CompletionIndicator circular({
    required List<ProfileSection> sections,
    String title = 'Profile Completion',
    VoidCallback? onTap,
  }) {
    return CompletionIndicator(
      sections: sections,
      displayMode: CompletionDisplayMode.circular,
      title: title,
      onTap: onTap,
    );
  }
  
  /// Create a segmented progress indicator
  static CompletionIndicator segmented({
    required List<ProfileSection> sections,
    Function(ProfileSection)? onSectionTap,
  }) {
    return CompletionIndicator(
      sections: sections,
      displayMode: CompletionDisplayMode.segmented,
      enableExpansion: false,
      onSectionTap: onSectionTap,
    );
  }
  
  /// Create a compact progress indicator
  static CompletionIndicator compact({
    required List<ProfileSection> sections,
    VoidCallback? onTap,
  }) {
    return CompletionIndicator(
      sections: sections,
      displayMode: CompletionDisplayMode.compact,
      enableExpansion: false,
      height: 32,
      onTap: onTap,
    );
  }
}

/// Predefined profile completion presets
class CompletionIndicatorPresets {
  /// Basic profile completion sections
  static List<ProfileSection> basicProfileSections = [
    const ProfileSection(
      id: 'personal',
      name: 'Personal Info',
      description: 'Basic information about you',
      isCompleted: true,
      totalItems: 5,
      completedItems: 5,
      icon: Icons.person,
      color: Colors.blue,
    ),
    const ProfileSection(
      id: 'sports',
      name: 'Sports & Skills',
      description: 'Your sports and skill levels',
      isCompleted: false,
      totalItems: 3,
      completedItems: 1,
      icon: Icons.sports_soccer,
      color: Colors.green,
      missingItems: ['Skill levels', 'Certifications'],
    ),
    const ProfileSection(
      id: 'preferences',
      name: 'Preferences',
      description: 'Your playing preferences',
      isCompleted: false,
      totalItems: 4,
      completedItems: 2,
      icon: Icons.settings,
      color: Colors.purple,
      missingItems: ['Location', 'Availability'],
    ),
  ];
  
  /// Complete profile with all sections
  static CompletionIndicator completeProfile({
    Function(ProfileSection)? onSectionTap,
  }) {
    return CompletionIndicator(
      sections: basicProfileSections,
      displayMode: CompletionDisplayMode.expanded,
      title: 'Complete Your Profile',
      subtitle: 'Get better matches by completing all sections',
      showMissingItems: true,
      onSectionTap: onSectionTap,
    );
  }
  
  /// Quick completion overview
  static CompletionIndicator quickOverview({
    required List<ProfileSection> sections,
    VoidCallback? onTap,
  }) {
    return CompletionIndicator(
      sections: sections,
      displayMode: CompletionDisplayMode.linear,
      title: 'Profile Status',
      subtitle: '${sections.where((s) => s.isCompleted).length}/${sections.length} sections complete',
      height: 80,
      onTap: onTap,
    );
  }
}
