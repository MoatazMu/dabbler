/// Visual indicator for skill levels with multiple display modes
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Skill level data with detailed information
class SkillLevel {
  final String id;
  final String sportName;
  final String category;
  final int level; // 1-10
  final int maxLevel;
  final String levelName;
  final String description;
  final Color color;
  final DateTime? lastUpdated;
  final int experienceYears;
  final bool isVerified;
  final List<String> certifications;
  final SkillTrend trend;
  final double confidenceScore; // 0.0-1.0
  final Map<String, dynamic> metadata;
  
  const SkillLevel({
    required this.id,
    required this.sportName,
    required this.category,
    required this.level,
    this.maxLevel = 10,
    required this.levelName,
    required this.description,
    required this.color,
    this.lastUpdated,
    this.experienceYears = 0,
    this.isVerified = false,
    this.certifications = const [],
    this.trend = SkillTrend.stable,
    this.confidenceScore = 1.0,
    this.metadata = const {},
  });
  
  double get normalizedLevel => level / maxLevel;
  
  bool get isAdvanced => level >= (maxLevel * 0.8);
  bool get isIntermediate => level >= (maxLevel * 0.5) && level < (maxLevel * 0.8);
  bool get isBeginner => level < (maxLevel * 0.5);
  
  String get proficiencyLabel {
    if (isAdvanced) return 'Advanced';
    if (isIntermediate) return 'Intermediate';
    return 'Beginner';
  }
  
  Color get proficiencyColor {
    if (isAdvanced) return Colors.green;
    if (isIntermediate) return Colors.orange;
    return Colors.blue;
  }
  
  SkillLevel copyWith({
    String? id,
    String? sportName,
    String? category,
    int? level,
    int? maxLevel,
    String? levelName,
    String? description,
    Color? color,
    DateTime? lastUpdated,
    int? experienceYears,
    bool? isVerified,
    List<String>? certifications,
    SkillTrend? trend,
    double? confidenceScore,
    Map<String, dynamic>? metadata,
  }) {
    return SkillLevel(
      id: id ?? this.id,
      sportName: sportName ?? this.sportName,
      category: category ?? this.category,
      level: level ?? this.level,
      maxLevel: maxLevel ?? this.maxLevel,
      levelName: levelName ?? this.levelName,
      description: description ?? this.description,
      color: color ?? this.color,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      experienceYears: experienceYears ?? this.experienceYears,
      isVerified: isVerified ?? this.isVerified,
      certifications: certifications ?? this.certifications,
      trend: trend ?? this.trend,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Skill trend indicator
enum SkillTrend {
  improving,
  stable,
  declining,
}

/// Display mode for skill level indicator
enum SkillDisplayMode {
  stars,
  bars,
  badges,
  circular,
  comparison,
  compact,
  detailed,
}

/// Skill level indicator widget
class SkillLevelIndicator extends StatefulWidget {
  final List<SkillLevel> skills;
  final SkillDisplayMode displayMode;
  final bool showTrend;
  final bool showCertifications;
  final bool showTooltips;
  final bool showComparison;
  final bool animateChanges;
  final bool enableInteraction;
  final Function(SkillLevel)? onSkillTap;
  final Function(SkillLevel)? onSkillLongPress;
  final EdgeInsets padding;
  final double height;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Duration animationDuration;
  final bool enableHapticFeedback;
  final String title;
  final bool showExperienceYears;
  final bool showConfidence;
  final int maxSkillsToShow;
  
  const SkillLevelIndicator({
    super.key,
    required this.skills,
    this.displayMode = SkillDisplayMode.stars,
    this.showTrend = true,
    this.showCertifications = true,
    this.showTooltips = true,
    this.showComparison = false,
    this.animateChanges = true,
    this.enableInteraction = true,
    this.onSkillTap,
    this.onSkillLongPress,
    this.padding = const EdgeInsets.all(16),
    this.height = 80,
    this.titleStyle,
    this.subtitleStyle,
    this.animationDuration = const Duration(milliseconds: 600),
    this.enableHapticFeedback = true,
    this.title = 'Skill Levels',
    this.showExperienceYears = true,
    this.showConfidence = false,
    this.maxSkillsToShow = 10,
  });
  
  @override
  State<SkillLevelIndicator> createState() => _SkillLevelIndicatorState();
}

class _SkillLevelIndicatorState extends State<SkillLevelIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _skillAnimationControllers;
  late List<Animation<double>> _skillAnimations;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _skillAnimationControllers = widget.skills.map((skill) {
      return AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
    }).toList();
    
    _skillAnimations = _skillAnimationControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();
    
    if (widget.animateChanges) {
      _startStaggeredAnimations();
    } else {
      for (var controller in _skillAnimationControllers) {
        controller.value = 1.0;
      }
    }
  }
  
  void _startStaggeredAnimations() {
    for (int i = 0; i < _skillAnimationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _skillAnimationControllers[i].forward();
        }
      });
    }
  }
  
  @override
  void didUpdateWidget(SkillLevelIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.skills.length != oldWidget.skills.length) {
      _disposeAnimationControllers();
      _setupAnimations();
    }
  }
  
  @override
  void dispose() {
    _disposeAnimationControllers();
    super.dispose();
  }
  
  void _disposeAnimationControllers() {
    _animationController.dispose();
    for (var controller in _skillAnimationControllers) {
      controller.dispose();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final skillsToShow = widget.skills.take(widget.maxSkillsToShow).toList();
    
    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty) ...[
            _buildHeader(),
            const SizedBox(height: 16),
          ],
          
          _buildSkillIndicator(skillsToShow),
          
          if (widget.skills.length > widget.maxSkillsToShow) ...[
            const SizedBox(height: 8),
            _buildShowMoreButton(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    final averageLevel = widget.skills.isEmpty 
        ? 0.0 
        : widget.skills.map((s) => s.normalizedLevel).reduce((a, b) => a + b) / widget.skills.length;
    
    return Row(
      children: [
        Text(
          widget.title,
          style: widget.titleStyle ?? 
              Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        
        if (widget.skills.isNotEmpty) ...[
          _buildAverageIndicator(averageLevel),
          const SizedBox(width: 8),
          Text(
            '${widget.skills.length} skills',
            style: widget.subtitleStyle ?? 
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildAverageIndicator(double averageLevel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getColorForLevel(averageLevel).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorForLevel(averageLevel).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            size: 12,
            color: _getColorForLevel(averageLevel),
          ),
          const SizedBox(width: 4),
          Text(
            'Avg ${(averageLevel * 10).toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getColorForLevel(averageLevel),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSkillIndicator(List<SkillLevel> skills) {
    switch (widget.displayMode) {
      case SkillDisplayMode.stars:
        return _buildStarsDisplay(skills);
      case SkillDisplayMode.bars:
        return _buildBarsDisplay(skills);
      case SkillDisplayMode.badges:
        return _buildBadgesDisplay(skills);
      case SkillDisplayMode.circular:
        return _buildCircularDisplay(skills);
      case SkillDisplayMode.comparison:
        return _buildComparisonDisplay(skills);
      case SkillDisplayMode.compact:
        return _buildCompactDisplay(skills);
      case SkillDisplayMode.detailed:
        return _buildDetailedDisplay(skills);
    }
  }
  
  Widget _buildStarsDisplay(List<SkillLevel> skills) {
    return Column(
      children: skills.asMap().entries.map((entry) {
        final index = entry.key;
        final skill = entry.value;
        
        return AnimatedBuilder(
          animation: _skillAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _skillAnimations[index].value,
              child: _buildSkillStars(skill),
            );
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildSkillStars(SkillLevel skill) {
    return GestureDetector(
      onTap: widget.enableInteraction ? () => _handleSkillTap(skill) : null,
      onLongPress: widget.enableInteraction ? () => _handleSkillLongPress(skill) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: skill.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: skill.color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            skill.sportName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: skill.color,
                            ),
                          ),
                          
                          if (skill.isVerified) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                          ],
                          
                          if (widget.showTrend)
                            _buildTrendIndicator(skill.trend),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      Text(
                        skill.levelName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                _buildStarRating(skill),
              ],
            ),
            
            if (widget.showExperienceYears && skill.experienceYears > 0) ...[
              const SizedBox(height: 8),
              _buildExperienceIndicator(skill),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStarRating(SkillLevel skill) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = (index + 1) * 2; // Scale 1-10 to 5 stars
        final filled = skill.level >= starValue;
        final halfFilled = skill.level >= starValue - 1 && !filled;
        
        return Icon(
          halfFilled 
              ? Icons.star_half 
              : (filled ? Icons.star : Icons.star_border),
          size: 20,
          color: skill.color,
        );
      }),
    );
  }
  
  Widget _buildBarsDisplay(List<SkillLevel> skills) {
    return Column(
      children: skills.asMap().entries.map((entry) {
        final index = entry.key;
        final skill = entry.value;
        
        return AnimatedBuilder(
          animation: _skillAnimations[index],
          builder: (context, child) {
            return _buildSkillBar(skill, _skillAnimations[index].value);
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildSkillBar(SkillLevel skill, double animationValue) {
    return GestureDetector(
      onTap: widget.enableInteraction ? () => _handleSkillTap(skill) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    skill.sportName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: skill.normalizedLevel * animationValue,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(skill.color),
                      minHeight: 6,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                Text(
                  '${skill.level}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: skill.color,
                    fontSize: 12,
                  ),
                ),
                
                if (widget.showTrend)
                  _buildTrendIndicator(skill.trend),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBadgesDisplay(List<SkillLevel> skills) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.asMap().entries.map((entry) {
        final index = entry.key;
        final skill = entry.value;
        
        return AnimatedBuilder(
          animation: _skillAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _skillAnimations[index].value,
              child: _buildSkillBadge(skill),
            );
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildSkillBadge(SkillLevel skill) {
    return GestureDetector(
      onTap: widget.enableInteraction ? () => _handleSkillTap(skill) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: skill.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: skill.color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (skill.isVerified) ...[
              const Icon(
                Icons.verified,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
            ],
            
            Text(
              skill.sportName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${skill.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            
            if (widget.showTrend && skill.trend != SkillTrend.stable) ...[
              const SizedBox(width: 4),
              Icon(
                skill.trend == SkillTrend.improving 
                    ? Icons.trending_up 
                    : Icons.trending_down,
                size: 12,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCircularDisplay(List<SkillLevel> skills) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        
        return AnimatedBuilder(
          animation: _skillAnimations[index],
          builder: (context, child) {
            return _buildCircularSkill(skill, _skillAnimations[index].value);
          },
        );
      },
    );
  }
  
  Widget _buildCircularSkill(SkillLevel skill, double animationValue) {
    return GestureDetector(
      onTap: widget.enableInteraction ? () => _handleSkillTap(skill) : null,
      child: Container(
        decoration: BoxDecoration(
          color: skill.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: skill.color.withOpacity(0.2),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: skill.normalizedLevel * animationValue,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(skill.color),
                strokeWidth: 4,
              ),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${skill.level}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: skill.color,
                  ),
                ),
                
                Text(
                  skill.sportName,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            
            if (skill.isVerified)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.verified,
                  size: 12,
                  color: Colors.blue[600],
                ),
              ),
            
            if (widget.showTrend && skill.trend != SkillTrend.stable)
              Positioned(
                bottom: 4,
                right: 4,
                child: _buildTrendIndicator(skill.trend, size: 12),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparisonDisplay(List<SkillLevel> skills) {
    final maxLevel = skills.isEmpty 
        ? 10 
        : skills.map((s) => s.level).reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        // Chart header
        SizedBox(
          height: 30,
          child: Row(
            children: [
              const SizedBox(width: 80),
              ...List.generate(maxLevel, (index) {
                return Expanded(
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        
        // Skill bars
        ...skills.asMap().entries.map((entry) {
          final index = entry.key;
          final skill = entry.value;
          
          return AnimatedBuilder(
            animation: _skillAnimations[index],
            builder: (context, child) {
              return _buildComparisonBar(skill, maxLevel, _skillAnimations[index].value);
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildComparisonBar(SkillLevel skill, int maxLevel, double animationValue) {
    return GestureDetector(
      onTap: widget.enableInteraction ? () => _handleSkillTap(skill) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        height: 24,
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                skill.sportName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  
                  FractionallySizedBox(
                    widthFactor: (skill.level / maxLevel) * animationValue,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: skill.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    right: 4,
                    top: 2,
                    child: Text(
                      '${skill.level}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: skill.level > maxLevel * 0.5 
                            ? Colors.white 
                            : skill.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactDisplay(List<SkillLevel> skills) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: skills.asMap().entries.map((entry) {
          final index = entry.key;
          final skill = entry.value;
          
          return AnimatedBuilder(
            animation: _skillAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _skillAnimations[index].value,
                child: _buildCompactSkill(skill),
              );
            },
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildCompactSkill(SkillLevel skill) {
    return GestureDetector(
      onTap: widget.enableInteraction ? () => _handleSkillTap(skill) : null,
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: skill.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: skill.color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              skill.sportName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: skill.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: skill.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${skill.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailedDisplay(List<SkillLevel> skills) {
    return Column(
      children: skills.asMap().entries.map((entry) {
        final index = entry.key;
        final skill = entry.value;
        
        return AnimatedBuilder(
          animation: _skillAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _skillAnimations[index].value,
              child: _buildDetailedSkill(skill),
            );
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildDetailedSkill(SkillLevel skill) {
    return GestureDetector(
      onTap: widget.enableInteraction ? () => _handleSkillTap(skill) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: skill.color.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: skill.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${skill.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                            skill.sportName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          
                          if (skill.isVerified) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                          ],
                          
                          const Spacer(),
                          if (widget.showTrend)
                            _buildTrendIndicator(skill.trend),
                        ],
                      ),
                      
                      Text(
                        skill.levelName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Text(
              skill.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            
            if (widget.showExperienceYears && skill.experienceYears > 0) ...[
              const SizedBox(height: 8),
              _buildExperienceIndicator(skill),
            ],
            
            if (widget.showCertifications && skill.certifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildCertificationBadges(skill.certifications),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrendIndicator(SkillTrend trend, {double size = 16}) {
    IconData icon;
    Color color;
    
    switch (trend) {
      case SkillTrend.improving:
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case SkillTrend.declining:
        icon = Icons.trending_down;
        color = Colors.red;
        break;
      case SkillTrend.stable:
        icon = Icons.trending_flat;
        color = Colors.grey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
  
  Widget _buildExperienceIndicator(SkillLevel skill) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        
        Text(
          '${skill.experienceYears} years experience',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        
        if (widget.showConfidence) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.psychology,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          
          Text(
            '${(skill.confidenceScore * 100).round()}% confidence',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildCertificationBadges(List<String> certifications) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: certifications.take(3).map((cert) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.blue[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.military_tech,
                size: 10,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 2),
              
              Text(
                cert,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildShowMoreButton() {
    return GestureDetector(
      onTap: () {
        // Handle show more
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '+${widget.skills.length - widget.maxSkillsToShow} more skills',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getColorForLevel(double normalizedLevel) {
    if (normalizedLevel >= 0.8) return Colors.green;
    if (normalizedLevel >= 0.5) return Colors.orange;
    return Colors.blue;
  }
  
  void _handleSkillTap(SkillLevel skill) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    widget.onSkillTap?.call(skill);
  }
  
  void _handleSkillLongPress(SkillLevel skill) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onSkillLongPress?.call(skill);
  }
}

/// Extension methods for easy SkillLevelIndicator creation
extension SkillLevelIndicatorExtensions on SkillLevelIndicator {
  /// Create a simple stars display
  static SkillLevelIndicator stars({
    required List<SkillLevel> skills,
    Function(SkillLevel)? onSkillTap,
  }) {
    return SkillLevelIndicator(
      skills: skills,
      displayMode: SkillDisplayMode.stars,
      onSkillTap: onSkillTap,
    );
  }
  
  /// Create a horizontal bars display
  static SkillLevelIndicator bars({
    required List<SkillLevel> skills,
    Function(SkillLevel)? onSkillTap,
  }) {
    return SkillLevelIndicator(
      skills: skills,
      displayMode: SkillDisplayMode.bars,
      showTrend: true,
      onSkillTap: onSkillTap,
    );
  }
  
  /// Create a compact badge display
  static SkillLevelIndicator badges({
    required List<SkillLevel> skills,
    Function(SkillLevel)? onSkillTap,
  }) {
    return SkillLevelIndicator(
      skills: skills,
      displayMode: SkillDisplayMode.badges,
      showTrend: false,
      onSkillTap: onSkillTap,
    );
  }
  
  /// Create a comparison chart
  static SkillLevelIndicator comparison({
    required List<SkillLevel> skills,
    Function(SkillLevel)? onSkillTap,
  }) {
    return SkillLevelIndicator(
      skills: skills,
      displayMode: SkillDisplayMode.comparison,
      showComparison: true,
      onSkillTap: onSkillTap,
    );
  }
}

/// Predefined skill level presets
class SkillLevelPresets {
  /// Sample sports skills
  static List<SkillLevel> sampleSkills = [
    const SkillLevel(
      id: 'tennis',
      sportName: 'Tennis',
      category: 'Racket Sports',
      level: 8,
      levelName: 'Advanced',
      description: 'Competitive tournament player',
      color: Colors.green,
      experienceYears: 5,
      isVerified: true,
      certifications: ['USTA Level 4', 'Tournament Certified'],
      trend: SkillTrend.improving,
    ),
    const SkillLevel(
      id: 'basketball',
      sportName: 'Basketball',
      category: 'Ball Sports',
      level: 6,
      levelName: 'Intermediate',
      description: 'Regular league player',
      color: Colors.orange,
      experienceYears: 3,
      trend: SkillTrend.stable,
    ),
    const SkillLevel(
      id: 'swimming',
      sportName: 'Swimming',
      category: 'Water Sports',
      level: 4,
      levelName: 'Beginner+',
      description: 'Comfortable in all strokes',
      color: Colors.blue,
      experienceYears: 1,
      trend: SkillTrend.improving,
    ),
  ];
}
