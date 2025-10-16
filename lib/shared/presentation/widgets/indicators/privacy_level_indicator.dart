/// Privacy level indicator with visual status and controls
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Privacy level enumeration
enum PrivacyLevel {
  public,
  friends,
  private,
  custom,
}

/// Privacy setting data
class PrivacySetting {
  final String id;
  final String name;
  final String description;
  final PrivacyLevel level;
  final bool isEnabled;
  final DateTime? lastUpdated;
  final String? lastUpdatedBy;
  final bool requiresConfirmation;
  final List<String> allowedUsers;
  final List<String> blockedUsers;
  final Map<String, dynamic> customSettings;
  final bool isInSync;
  final String? warning;
  
  const PrivacySetting({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    this.isEnabled = true,
    this.lastUpdated,
    this.lastUpdatedBy,
    this.requiresConfirmation = false,
    this.allowedUsers = const [],
    this.blockedUsers = const [],
    this.customSettings = const {},
    this.isInSync = true,
    this.warning,
  });
  
  Color get levelColor {
    switch (level) {
      case PrivacyLevel.public:
        return Colors.red;
      case PrivacyLevel.friends:
        return Colors.orange;
      case PrivacyLevel.private:
        return Colors.green;
      case PrivacyLevel.custom:
        return Colors.purple;
    }
  }
  
  IconData get levelIcon {
    switch (level) {
      case PrivacyLevel.public:
        return Icons.public;
      case PrivacyLevel.friends:
        return Icons.group;
      case PrivacyLevel.private:
        return Icons.lock;
      case PrivacyLevel.custom:
        return Icons.tune;
    }
  }
  
  String get levelLabel {
    switch (level) {
      case PrivacyLevel.public:
        return 'Public';
      case PrivacyLevel.friends:
        return 'Friends Only';
      case PrivacyLevel.private:
        return 'Private';
      case PrivacyLevel.custom:
        return 'Custom';
    }
  }
  
  String get levelDescription {
    switch (level) {
      case PrivacyLevel.public:
        return 'Visible to everyone';
      case PrivacyLevel.friends:
        return 'Visible to friends only';
      case PrivacyLevel.private:
        return 'Visible only to you';
      case PrivacyLevel.custom:
        return 'Custom privacy settings';
    }
  }
  
  bool get hasWarning => warning != null || level == PrivacyLevel.public;
  
  PrivacySetting copyWith({
    String? id,
    String? name,
    String? description,
    PrivacyLevel? level,
    bool? isEnabled,
    DateTime? lastUpdated,
    String? lastUpdatedBy,
    bool? requiresConfirmation,
    List<String>? allowedUsers,
    List<String>? blockedUsers,
    Map<String, dynamic>? customSettings,
    bool? isInSync,
    String? warning,
  }) {
    return PrivacySetting(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      isEnabled: isEnabled ?? this.isEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      allowedUsers: allowedUsers ?? this.allowedUsers,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      customSettings: customSettings ?? this.customSettings,
      isInSync: isInSync ?? this.isInSync,
      warning: warning ?? this.warning,
    );
  }
}

/// Display mode for privacy indicator
enum PrivacyDisplayMode {
  compact,
  detailed,
  toggle,
  traffic,
  expandable,
}

/// Privacy level indicator widget
class PrivacyLevelIndicator extends StatefulWidget {
  final List<PrivacySetting> settings;
  final PrivacyDisplayMode displayMode;
  final bool showSyncStatus;
  final bool showWarnings;
  final bool showLastUpdated;
  final bool enableQuickToggle;
  final bool showExpandedDetails;
  final Function(PrivacySetting, PrivacyLevel)? onPrivacyChanged;
  final Function(PrivacySetting)? onSettingTap;
  final VoidCallback? onExpandToggle;
  final EdgeInsets padding;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Duration animationDuration;
  final bool enableHapticFeedback;
  final String title;
  final bool showGlobalStatus;
  final bool enableLockAnimation;
  
  const PrivacyLevelIndicator({
    super.key,
    required this.settings,
    this.displayMode = PrivacyDisplayMode.compact,
    this.showSyncStatus = true,
    this.showWarnings = true,
    this.showLastUpdated = false,
    this.enableQuickToggle = true,
    this.showExpandedDetails = false,
    this.onPrivacyChanged,
    this.onSettingTap,
    this.onExpandToggle,
    this.padding = const EdgeInsets.all(16),
    this.titleStyle,
    this.subtitleStyle,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHapticFeedback = true,
    this.title = 'Privacy Settings',
    this.showGlobalStatus = true,
    this.enableLockAnimation = true,
  });
  
  @override
  State<PrivacyLevelIndicator> createState() => _PrivacyLevelIndicatorState();
}

class _PrivacyLevelIndicatorState extends State<PrivacyLevelIndicator>
    with TickerProviderStateMixin {
  late AnimationController _lockAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _lockRotateAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkForWarnings();
  }
  
  void _setupAnimations() {
    _lockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _lockRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _lockAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    if (_hasWarnings()) {
      _pulseController.repeat(reverse: true);
    }
  }
  
  void _checkForWarnings() {
    if (_hasWarnings() && widget.showWarnings) {
      _pulseController.repeat(reverse: true);
    }
  }
  
  bool _hasWarnings() {
    return widget.settings.any((setting) => setting.hasWarning);
  }
  
  @override
  void didUpdateWidget(PrivacyLevelIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.settings != oldWidget.settings) {
      _checkForWarnings();
    }
  }
  
  @override
  void dispose() {
    _lockAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty) ...[
            _buildHeader(),
            const SizedBox(height: 16),
          ],
          
          _buildPrivacyIndicator(),
          
          if (_isExpanded || widget.displayMode == PrivacyDisplayMode.expandable)
            _buildExpandedContent(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          widget.title,
          style: widget.titleStyle ?? 
              Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        
        const SizedBox(width: 8),
        
        if (widget.showGlobalStatus)
          _buildGlobalStatusBadge(),
        
        const Spacer(),
        
        if (widget.showSyncStatus)
          _buildSyncStatusIndicator(),
        
        if (widget.settings.isNotEmpty && 
            widget.displayMode != PrivacyDisplayMode.expandable)
          GestureDetector(
            onTap: _toggleExpansion,
            child: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: widget.animationDuration,
              child: Icon(
                Icons.expand_more,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildGlobalStatusBadge() {
    final publicCount = widget.settings.where((s) => s.level == PrivacyLevel.public).length;
    final hasPublic = publicCount > 0;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: hasPublic ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasPublic 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasPublic 
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPublic ? Icons.warning : Icons.security,
                  size: 12,
                  color: hasPublic ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 4),
                
                Text(
                  hasPublic ? '$publicCount Public' : 'Secure',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: hasPublic ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSyncStatusIndicator() {
    final allInSync = widget.settings.every((setting) => setting.isInSync);
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: allInSync 
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        allInSync ? Icons.sync : Icons.sync_problem,
        size: 16,
        color: allInSync ? Colors.green : Colors.orange,
      ),
    );
  }
  
  Widget _buildPrivacyIndicator() {
    switch (widget.displayMode) {
      case PrivacyDisplayMode.compact:
        return _buildCompactDisplay();
      case PrivacyDisplayMode.detailed:
        return _buildDetailedDisplay();
      case PrivacyDisplayMode.toggle:
        return _buildToggleDisplay();
      case PrivacyDisplayMode.traffic:
        return _buildTrafficDisplay();
      case PrivacyDisplayMode.expandable:
        return _buildExpandableDisplay();
    }
  }
  
  Widget _buildCompactDisplay() {
    if (widget.settings.isEmpty) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.settings.map((setting) {
          return _buildCompactPrivacyItem(setting);
        }).toList(),
      ),
    );
  }
  
  Widget _buildCompactPrivacyItem(PrivacySetting setting) {
    return GestureDetector(
      onTap: () => _handleSettingTap(setting),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: setting.levelColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: setting.levelColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _lockRotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: setting.level == PrivacyLevel.private 
                      ? _lockRotateAnimation.value 
                      : 0.0,
                  child: Icon(
                    setting.levelIcon,
                    size: 16,
                    color: setting.levelColor,
                  ),
                );
              },
            ),
            
            const SizedBox(width: 6),
            Text(
              setting.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: setting.levelColor,
              ),
            ),
            
            if (setting.hasWarning) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.warning_rounded,
                size: 12,
                color: Colors.red,
              ),
            ],
            
            if (!setting.isInSync) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.sync_problem,
                size: 12,
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailedDisplay() {
    return Column(
      children: widget.settings.map((setting) {
        return _buildDetailedPrivacyItem(setting);
      }).toList(),
    );
  }
  
  Widget _buildDetailedPrivacyItem(PrivacySetting setting) {
    return GestureDetector(
      onTap: () => _handleSettingTap(setting),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: setting.levelColor.withOpacity(0.2),
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
                    color: setting.levelColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedBuilder(
                    animation: _lockRotateAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: setting.level == PrivacyLevel.private 
                            ? _lockRotateAnimation.value 
                            : 0.0,
                        child: Icon(
                          setting.levelIcon,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
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
                            setting.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          
                          if (setting.hasWarning) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.warning_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      Text(
                        setting.levelLabel,
                        style: TextStyle(
                          color: setting.levelColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (widget.enableQuickToggle)
                  _buildQuickToggle(setting),
              ],
            ),
            
            const SizedBox(height: 12),
            Text(
              setting.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            
            if (setting.hasWarning && widget.showWarnings) ...[
              const SizedBox(height: 8),
              _buildWarningMessage(setting),
            ],
            
            if (widget.showLastUpdated && setting.lastUpdated != null) ...[
              const SizedBox(height: 8),
              _buildLastUpdatedInfo(setting),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildToggleDisplay() {
    return Column(
      children: widget.settings.map((setting) {
        return _buildToggleItem(setting);
      }).toList(),
    );
  }
  
  Widget _buildToggleItem(PrivacySetting setting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: setting.levelColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: setting.levelColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _lockRotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: setting.level == PrivacyLevel.private 
                    ? _lockRotateAnimation.value 
                    : 0.0,
                child: Icon(
                  setting.levelIcon,
                  color: setting.levelColor,
                  size: 20,
                ),
              );
            },
          ),
          
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setting.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                Text(
                  setting.levelDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          _buildPrivacyLevelSelector(setting),
        ],
      ),
    );
  }
  
  Widget _buildTrafficDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Privacy Status',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrafficLight(
                Colors.green, 
                'Private', 
                widget.settings.where((s) => s.level == PrivacyLevel.private).length,
              ),
              _buildTrafficLight(
                Colors.orange, 
                'Friends', 
                widget.settings.where((s) => s.level == PrivacyLevel.friends).length,
              ),
              _buildTrafficLight(
                Colors.red, 
                'Public', 
                widget.settings.where((s) => s.level == PrivacyLevel.public).length,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          _buildOverallSecurityScore(),
        ],
      ),
    );
  }
  
  Widget _buildTrafficLight(Color color, String label, int count) {
    final isActive = count > 0;
    
    return Column(
      children: [
        AnimatedContainer(
          duration: widget.animationDuration,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
        ),
        
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? color : Colors.grey[600],
          ),
        ),
        
        Text(
          '$count',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOverallSecurityScore() {
    final totalSettings = widget.settings.length;
    if (totalSettings == 0) return const SizedBox.shrink();
    
    final privateCount = widget.settings.where((s) => s.level == PrivacyLevel.private).length;
    final friendsCount = widget.settings.where((s) => s.level == PrivacyLevel.friends).length;
    final publicCount = widget.settings.where((s) => s.level == PrivacyLevel.public).length;
    
    // Calculate security score (private=100%, friends=60%, public=20%)
    final score = ((privateCount * 100 + friendsCount * 60 + publicCount * 20) / totalSettings).round();
    
    Color scoreColor;
    String scoreLabel;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Poor';
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Security Score',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            
            Text(
              '$scoreLabel ($score%)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
  
  Widget _buildExpandableDisplay() {
    return Column(
      children: [
        _buildCompactDisplay(),
        
        AnimatedContainer(
          duration: widget.animationDuration,
          height: _isExpanded ? null : 0,
          child: _isExpanded ? _buildExpandedContent() : null,
        ),
      ],
    );
  }
  
  Widget _buildExpandedContent() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: widget.settings.map((setting) {
          return _buildExpandedSettingItem(setting);
        }).toList(),
      ),
    );
  }
  
  Widget _buildExpandedSettingItem(PrivacySetting setting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: setting.levelColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: setting.levelColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                setting.levelIcon,
                color: setting.levelColor,
                size: 20,
              ),
              
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  setting.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: setting.levelColor,
                  ),
                ),
              ),
              
              _buildPrivacyLevelSelector(setting),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            setting.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          
          if (setting.level == PrivacyLevel.custom) ...[
            const SizedBox(height: 8),
            _buildCustomSettingsPreview(setting),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPrivacyLevelSelector(PrivacySetting setting) {
    return PopupMenuButton<PrivacyLevel>(
      onSelected: (level) => _handlePrivacyChanged(setting, level),
      itemBuilder: (context) => PrivacyLevel.values.map((level) {
        return PopupMenuItem<PrivacyLevel>(
          value: level,
          child: Row(
            children: [
              Icon(
                _getIconForLevel(level),
                size: 16,
                color: _getColorForLevel(level),
              ),
              const SizedBox(width: 8),
              
              Text(_getLabelForLevel(level)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: setting.levelColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: setting.levelColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              setting.levelLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: setting.levelColor,
              ),
            ),
            const SizedBox(width: 4),
            
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: setting.levelColor,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickToggle(PrivacySetting setting) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: PrivacyLevel.values.take(3).map((level) {
        final isSelected = setting.level == level;
        
        return GestureDetector(
          onTap: () => _handlePrivacyChanged(setting, level),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected 
                  ? _getColorForLevel(level) 
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getIconForLevel(level),
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildWarningMessage(PrivacySetting setting) {
    final warningText = setting.warning ?? 
        (setting.level == PrivacyLevel.public ? 'This information is visible to everyone' : '');
    
    if (warningText.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            size: 16,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 8),
          
          Expanded(
            child: Text(
              warningText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLastUpdatedInfo(PrivacySetting setting) {
    final lastUpdated = setting.lastUpdated!;
    final timeAgo = _formatTimeAgo(lastUpdated);
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        
        Text(
          'Updated $timeAgo',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        
        if (setting.lastUpdatedBy != null) ...[
          Text(
            ' by ${setting.lastUpdatedBy}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildCustomSettingsPreview(PrivacySetting setting) {
    if (setting.customSettings.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Settings:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.purple[700],
            ),
          ),
          
          const SizedBox(height: 4),
          ...setting.customSettings.entries.take(3).map((entry) {
            return Text(
              '• ${entry.key}: ${entry.value}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.purple[600],
              ),
            );
          }),
          
          if (setting.customSettings.length > 3)
            Text(
              '• +${setting.customSettings.length - 3} more settings',
              style: TextStyle(
                fontSize: 10,
                color: Colors.purple[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getColorForLevel(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return Colors.red;
      case PrivacyLevel.friends:
        return Colors.orange;
      case PrivacyLevel.private:
        return Colors.green;
      case PrivacyLevel.custom:
        return Colors.purple;
    }
  }
  
  IconData _getIconForLevel(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return Icons.public;
      case PrivacyLevel.friends:
        return Icons.group;
      case PrivacyLevel.private:
        return Icons.lock;
      case PrivacyLevel.custom:
        return Icons.tune;
    }
  }
  
  String _getLabelForLevel(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return 'Public';
      case PrivacyLevel.friends:
        return 'Friends Only';
      case PrivacyLevel.private:
        return 'Private';
      case PrivacyLevel.custom:
        return 'Custom';
    }
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
  
  void _toggleExpansion() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    widget.onExpandToggle?.call();
  }
  
  void _handleSettingTap(PrivacySetting setting) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    widget.onSettingTap?.call(setting);
  }
  
  void _handlePrivacyChanged(PrivacySetting setting, PrivacyLevel newLevel) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    
    // Animate lock for private settings
    if (newLevel == PrivacyLevel.private && widget.enableLockAnimation) {
      _lockAnimationController.forward().then((_) {
        _lockAnimationController.reverse();
      });
    }
    
    widget.onPrivacyChanged?.call(setting, newLevel);
  }
}

/// Extension methods for easy PrivacyLevelIndicator creation
extension PrivacyLevelIndicatorExtensions on PrivacyLevelIndicator {
  /// Create a simple compact privacy indicator
  static PrivacyLevelIndicator compact({
    required List<PrivacySetting> settings,
    Function(PrivacySetting)? onSettingTap,
  }) {
    return PrivacyLevelIndicator(
      settings: settings,
      displayMode: PrivacyDisplayMode.compact,
      onSettingTap: onSettingTap,
    );
  }
  
  /// Create a traffic light style indicator
  static PrivacyLevelIndicator traffic({
    required List<PrivacySetting> settings,
  }) {
    return PrivacyLevelIndicator(
      settings: settings,
      displayMode: PrivacyDisplayMode.traffic,
      showGlobalStatus: true,
      enableQuickToggle: false,
    );
  }
  
  /// Create a detailed expandable indicator
  static PrivacyLevelIndicator detailed({
    required List<PrivacySetting> settings,
    Function(PrivacySetting, PrivacyLevel)? onPrivacyChanged,
  }) {
    return PrivacyLevelIndicator(
      settings: settings,
      displayMode: PrivacyDisplayMode.detailed,
      enableQuickToggle: true,
      showWarnings: true,
      showLastUpdated: true,
      onPrivacyChanged: onPrivacyChanged,
    );
  }
}

/// Predefined privacy setting presets
class PrivacyLevelPresets {
  /// Sample privacy settings
  static List<PrivacySetting> sampleSettings = [
    PrivacySetting(
      id: 'profile',
      name: 'Profile Info',
      description: 'Your basic profile information',
      level: PrivacyLevel.friends,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PrivacySetting(
      id: 'location',
      name: 'Location',
      description: 'Your current location and activity areas',
      level: PrivacyLevel.public,
      warning: 'Your location is visible to all users',
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PrivacySetting(
      id: 'contacts',
      name: 'Contact Info',
      description: 'Phone number and email address',
      level: PrivacyLevel.private,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    PrivacySetting(
      id: 'activity',
      name: 'Activity History',
      description: 'Your sports activities and achievements',
      level: PrivacyLevel.friends,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];
}
