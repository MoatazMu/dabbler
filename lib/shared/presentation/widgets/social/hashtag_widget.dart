import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hashtag popularity level
enum HashtagPopularity {
  trending,
  popular,
  moderate,
  low,
}

/// Hashtag click action type
enum HashtagAction {
  viewFeed,
  copy,
  share,
  follow,
  mute,
  report,
}

/// Related hashtag suggestion
class RelatedHashtag {
  final String tag;
  final int usageCount;
  final HashtagPopularity popularity;

  const RelatedHashtag({
    required this.tag,
    required this.usageCount,
    required this.popularity,
  });
}

/// Hashtag statistics data
class HashtagStats {
  final String tag;
  final int usageCount;
  final int todayCount;
  final int weekCount;
  final HashtagPopularity popularity;
  final DateTime? trendingStart;
  final List<RelatedHashtag> relatedTags;

  const HashtagStats({
    required this.tag,
    required this.usageCount,
    required this.todayCount,
    required this.weekCount,
    required this.popularity,
    this.trendingStart,
    this.relatedTags = const [],
  });
}

/// Clickable hashtag widget with comprehensive functionality
class HashtagWidget extends StatefulWidget {
  /// The hashtag text (with or without #)
  final String hashtag;
  
  /// Hashtag statistics
  final HashtagStats? stats;
  
  /// Show usage count
  final bool showCount;
  
  /// Show trending indicator
  final bool showTrendingIndicator;
  
  /// Enable click animation
  final bool enableAnimation;
  
  /// Custom text style
  final TextStyle? textStyle;
  
  /// Custom background color
  final Color? backgroundColor;
  
  /// Custom border radius
  final BorderRadius? borderRadius;
  
  /// Padding around the hashtag
  final EdgeInsetsGeometry? padding;
  
  /// Size variant
  final HashtagSize size;
  
  /// Enable long press menu
  final bool enableLongPress;
  
  /// Available actions for long press
  final Set<HashtagAction> availableActions;
  
  /// Callback when hashtag is tapped
  final VoidCallback? onTap;
  
  /// Callback for specific actions
  final void Function(HashtagAction action)? onAction;
  
  /// Callback when hashtag click is tracked
  final VoidCallback? onClickTracked;
  
  /// Enable haptic feedback
  final bool enableHaptics;
  
  /// Show as chip style
  final bool chipStyle;
  
  /// Enable delete functionality (for chip style)
  final bool enableDelete;
  
  /// Delete callback
  final VoidCallback? onDeleted;
  
  /// Custom tooltip message
  final String? tooltip;

  const HashtagWidget({
    super.key,
    required this.hashtag,
    this.stats,
    this.showCount = true,
    this.showTrendingIndicator = true,
    this.enableAnimation = true,
    this.textStyle,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.size = HashtagSize.medium,
    this.enableLongPress = true,
    this.availableActions = const {
      HashtagAction.viewFeed,
      HashtagAction.copy,
      HashtagAction.share,
    },
    this.onTap,
    this.onAction,
    this.onClickTracked,
    this.enableHaptics = true,
    this.chipStyle = false,
    this.enableDelete = false,
    this.onDeleted,
    this.tooltip,
  });

  @override
  State<HashtagWidget> createState() => _HashtagWidgetState();
}

/// Hashtag size variants
enum HashtagSize {
  small,
  medium,
  large,
}

class _HashtagWidgetState extends State<HashtagWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getHashtagColor(),
      end: _getHashtagColor().withOpacity(0.7),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget hashtagWidget = widget.chipStyle
        ? _buildChipStyle()
        : _buildTextStyle();

    if (widget.enableAnimation) {
      hashtagWidget = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: hashtagWidget,
      );
    }

    if (widget.tooltip != null || _shouldShowTooltip()) {
      hashtagWidget = Tooltip(
        message: widget.tooltip ?? _getDefaultTooltip(),
        child: hashtagWidget,
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      onLongPress: widget.enableLongPress ? _handleLongPress : null,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: hashtagWidget,
    );
  }

  Widget _buildTextStyle() {
    return Container(
      padding: widget.padding ?? _getDefaultPadding(),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? _getBackgroundColor(),
        borderRadius: widget.borderRadius ?? _getDefaultBorderRadius(),
        border: Border.all(
          color: _getHashtagColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTrendingIndicator && _isTrending())
            _buildTrendingIndicator(),
          _buildHashtagText(),
          if (widget.showCount && widget.stats != null)
            _buildCountBadge(),
        ],
      ),
    );
  }

  Widget _buildChipStyle() {
    return Chip(
      label: _buildChipContent(),
      backgroundColor: widget.backgroundColor ?? _getBackgroundColor(),
      deleteIcon: widget.enableDelete ? const Icon(Icons.close, size: 18) : null,
      onDeleted: widget.enableDelete ? widget.onDeleted : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: widget.padding ?? EdgeInsets.zero,
      labelStyle: widget.textStyle ?? _getDefaultTextStyle(),
      side: BorderSide(
        color: _getHashtagColor().withOpacity(0.3),
        width: 1,
      ),
    );
  }

  Widget _buildChipContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTrendingIndicator && _isTrending())
          _buildTrendingIndicator(),
        _buildHashtagText(),
        if (widget.showCount && widget.stats != null)
          _buildCountBadge(),
      ],
    );
  }

  Widget _buildTrendingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        Icons.trending_up,
        size: _getTrendingIconSize(),
        color: Colors.orange[600],
      ),
    );
  }

  Widget _buildHashtagText() {
    final cleanHashtag = widget.hashtag.startsWith('#')
        ? widget.hashtag
        : '#${widget.hashtag}';

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Text(
          cleanHashtag,
          style: (widget.textStyle ?? _getDefaultTextStyle()).copyWith(
            color: _isPressed
                ? _colorAnimation.value
                : _getHashtagColor(),
          ),
        );
      },
    );
  }

  Widget _buildCountBadge() {
    final count = widget.stats!.usageCount;
    final displayCount = _formatCount(count);

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getHashtagColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        displayCount,
        style: TextStyle(
          fontSize: _getCountFontSize(),
          fontWeight: FontWeight.w600,
          color: _getHashtagColor(),
        ),
      ),
    );
  }

  // Event Handlers
  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    _trackClick();
    widget.onTap?.call();
    widget.onAction?.call(HashtagAction.viewFeed);
  }

  void _handleLongPress() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    _showActionMenu();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    if (widget.enableAnimation) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    if (widget.enableAnimation) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    if (widget.enableAnimation) {
      _animationController.reverse();
    }
  }

  void _trackClick() {
    widget.onClickTracked?.call();
  }

  void _showActionMenu() {
    final actions = widget.availableActions.toList();
    if (actions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.hashtag.startsWith('#')
                  ? widget.hashtag
                  : '#${widget.hashtag}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getHashtagColor(),
              ),
            ),
          ),
          if (widget.stats != null) _buildStatsPreview(),
          const Divider(),
          ...actions.map((action) => _buildActionTile(action)),
          if (widget.stats != null && widget.stats!.relatedTags.isNotEmpty)
            _buildRelatedTags(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatsPreview() {
    final stats = widget.stats!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _formatCount(stats.usageCount)),
          _buildStatItem('Today', _formatCount(stats.todayCount)),
          _buildStatItem('This Week', _formatCount(stats.weekCount)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(HashtagAction action) {
    return ListTile(
      leading: Icon(_getActionIcon(action)),
      title: Text(_getActionLabel(action)),
      onTap: () {
        Navigator.of(context).pop();
        _handleAction(action);
      },
    );
  }

  Widget _buildRelatedTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Related Hashtags',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.stats!.relatedTags.length,
            itemBuilder: (context, index) {
              final relatedTag = widget.stats!.relatedTags[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: HashtagWidget(
                  hashtag: relatedTag.tag,
                  size: HashtagSize.small,
                  showCount: false,
                  enableLongPress: false,
                  onTap: () {
                    Navigator.of(context).pop();
                    // Handle related tag tap
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleAction(HashtagAction action) {
    switch (action) {
      case HashtagAction.copy:
        _copyToClipboard();
        break;
      case HashtagAction.share:
        _shareHashtag();
        break;
      default:
        widget.onAction?.call(action);
        break;
    }
  }

  void _copyToClipboard() {
    final hashtag = widget.hashtag.startsWith('#')
        ? widget.hashtag
        : '#${widget.hashtag}';
    
    Clipboard.setData(ClipboardData(text: hashtag));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $hashtag to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareHashtag() {
    // Implement sharing logic
    // This would typically use the share_plus package
  }

  // Styling Methods
  Color _getHashtagColor() {
    if (widget.stats?.popularity != null) {
      switch (widget.stats!.popularity) {
        case HashtagPopularity.trending:
          return Colors.red[600]!;
        case HashtagPopularity.popular:
          return Colors.blue[600]!;
        case HashtagPopularity.moderate:
          return Colors.green[600]!;
        case HashtagPopularity.low:
          return Colors.grey[600]!;
      }
    }
    return Theme.of(context).primaryColor;
  }

  Color? _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor;
    return _getHashtagColor().withOpacity(0.1);
  }

  TextStyle _getDefaultTextStyle() {
    double fontSize;
    switch (widget.size) {
      case HashtagSize.small:
        fontSize = 12;
        break;
      case HashtagSize.medium:
        fontSize = 14;
        break;
      case HashtagSize.large:
        fontSize = 16;
        break;
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }

  EdgeInsetsGeometry _getDefaultPadding() {
    switch (widget.size) {
      case HashtagSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      case HashtagSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case HashtagSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    }
  }

  BorderRadius _getDefaultBorderRadius() {
    return BorderRadius.circular(12);
  }

  double _getTrendingIconSize() {
    switch (widget.size) {
      case HashtagSize.small:
        return 12;
      case HashtagSize.medium:
        return 14;
      case HashtagSize.large:
        return 16;
    }
  }

  double _getCountFontSize() {
    switch (widget.size) {
      case HashtagSize.small:
        return 10;
      case HashtagSize.medium:
        return 11;
      case HashtagSize.large:
        return 12;
    }
  }

  IconData _getActionIcon(HashtagAction action) {
    switch (action) {
      case HashtagAction.viewFeed:
        return Icons.tag;
      case HashtagAction.copy:
        return Icons.copy;
      case HashtagAction.share:
        return Icons.share;
      case HashtagAction.follow:
        return Icons.add;
      case HashtagAction.mute:
        return Icons.volume_off;
      case HashtagAction.report:
        return Icons.report;
    }
  }

  String _getActionLabel(HashtagAction action) {
    switch (action) {
      case HashtagAction.viewFeed:
        return 'View Feed';
      case HashtagAction.copy:
        return 'Copy Hashtag';
      case HashtagAction.share:
        return 'Share';
      case HashtagAction.follow:
        return 'Follow';
      case HashtagAction.mute:
        return 'Mute';
      case HashtagAction.report:
        return 'Report';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  bool _isTrending() {
    return widget.stats?.popularity == HashtagPopularity.trending;
  }

  bool _shouldShowTooltip() {
    return widget.stats != null;
  }

  String _getDefaultTooltip() {
    if (widget.stats == null) return '';
    
    final stats = widget.stats!;
    return 'Used ${_formatCount(stats.usageCount)} times • '
        '${stats.popularity.name.toUpperCase()}';
  }
}

/// Extension for creating hashtag groups
extension HashtagGroup on List<HashtagWidget> {
  Widget buildHashtagWrap({
    double spacing = 8.0,
    double runSpacing = 4.0,
    WrapAlignment alignment = WrapAlignment.start,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.center,
  }) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: this,
    );
  }

  Widget buildHashtagList({
    Axis scrollDirection = Axis.horizontal,
    double spacing = 8.0,
  }) {
    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      child: scrollDirection == Axis.horizontal
          ? Row(
              children: [
                for (int i = 0; i < length; i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  this[i],
                ],
              ],
            )
          : Column(
              children: [
                for (int i = 0; i < length; i++) ...[
                  if (i > 0) SizedBox(height: spacing),
                  this[i],
                ],
              ],
            ),
    );
  }
}
