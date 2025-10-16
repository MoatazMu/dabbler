import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Social button size variants
enum SocialButtonSize {
  small,
  medium,
  large,
}

/// Social button types with predefined styling
enum SocialButtonType {
  like,
  comment,
  share,
  follow,
  message,
  bookmark,
  report,
  block,
  delete,
  edit,
}

/// Additional options for long press menu
class SocialButtonOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isDangerous;

  const SocialButtonOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isDangerous = false,
  });
}

/// Standardized social action button with comprehensive functionality
class SocialButton extends StatefulWidget {
  /// Button type for predefined styling
  final SocialButtonType? type;
  
  /// Custom icon (overrides type icon)
  final IconData? icon;
  
  /// Button text (optional)
  final String? text;
  
  /// Badge count to display
  final int? badgeCount;
  
  /// Loading state
  final bool isLoading;
  
  /// Disabled state
  final bool isDisabled;
  
  /// Selected/active state
  final bool isSelected;
  
  /// Tap callback
  final VoidCallback? onTap;
  
  /// Long press options
  final List<SocialButtonOption>? longPressOptions;
  
  /// Custom colors
  final Color? color;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? selectedBackgroundColor;
  final Color? disabledColor;
  
  /// Button size
  final SocialButtonSize size;
  
  /// Custom padding
  final EdgeInsetsGeometry? padding;
  
  /// Show tooltip
  final String? tooltip;
  
  /// Enable haptic feedback
  final bool enableHaptics;
  
  /// Custom border radius
  final BorderRadius? borderRadius;
  
  /// Show border
  final bool showBorder;
  
  /// Animate state changes
  final bool animate;
  
  /// Custom animation duration
  final Duration animationDuration;
  
  /// Semantic label for accessibility
  final String? semanticLabel;

  const SocialButton({
    super.key,
    this.type,
    this.icon,
    this.text,
    this.badgeCount,
    this.isLoading = false,
    this.isDisabled = false,
    this.isSelected = false,
    this.onTap,
    this.longPressOptions,
    this.color,
    this.backgroundColor,
    this.selectedColor,
    this.selectedBackgroundColor,
    this.disabledColor,
    this.size = SocialButtonSize.medium,
    this.padding,
    this.tooltip,
    this.enableHaptics = true,
    this.borderRadius,
    this.showBorder = false,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.semanticLabel,
  });

  /// Factory constructors for common button types
  factory SocialButton.like({
    required VoidCallback onTap,
    bool isSelected = false,
    int? count,
    SocialButtonSize size = SocialButtonSize.medium,
    bool enableHaptics = true,
    String? tooltip,
  }) {
    return SocialButton(
      type: SocialButtonType.like,
      onTap: onTap,
      isSelected: isSelected,
      badgeCount: count,
      size: size,
      enableHaptics: enableHaptics,
      tooltip: tooltip ?? (isSelected ? 'Unlike' : 'Like'),
    );
  }

  factory SocialButton.comment({
    required VoidCallback onTap,
    int? count,
    SocialButtonSize size = SocialButtonSize.medium,
    String? tooltip,
  }) {
    return SocialButton(
      type: SocialButtonType.comment,
      onTap: onTap,
      badgeCount: count,
      size: size,
      tooltip: tooltip ?? 'Comment',
    );
  }

  factory SocialButton.share({
    required VoidCallback onTap,
    int? count,
    List<SocialButtonOption>? shareOptions,
    SocialButtonSize size = SocialButtonSize.medium,
    String? tooltip,
  }) {
    return SocialButton(
      type: SocialButtonType.share,
      onTap: onTap,
      badgeCount: count,
      longPressOptions: shareOptions,
      size: size,
      tooltip: tooltip ?? 'Share',
    );
  }

  factory SocialButton.follow({
    required VoidCallback onTap,
    bool isSelected = false,
    SocialButtonSize size = SocialButtonSize.medium,
    String? tooltip,
  }) {
    return SocialButton(
      type: SocialButtonType.follow,
      onTap: onTap,
      isSelected: isSelected,
      size: size,
      tooltip: tooltip ?? (isSelected ? 'Unfollow' : 'Follow'),
      text: isSelected ? 'Following' : 'Follow',
    );
  }

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isPressed = false;

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

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getIconColor(),
      end: _getSelectedIconColor(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(SocialButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButton();

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return Semantics(
      label: widget.semanticLabel ?? _getSemanticLabel(),
      button: true,
      child: button,
    );
  }

  Widget _buildButton() {
    return GestureDetector(
      onTap: widget.isDisabled || widget.isLoading ? null : _handleTap,
      onLongPress: widget.longPressOptions != null && !widget.isDisabled
          ? _handleLongPress
          : null,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: widget.animate
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isPressed ? _scaleAnimation.value : 1.0,
                  child: Transform.rotate(
                    angle: widget.isSelected && widget.type == SocialButtonType.like
                        ? _rotationAnimation.value
                        : 0.0,
                    child: child,
                  ),
                );
              },
              child: _buildButtonContent(),
            )
          : _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    return Container(
      padding: widget.padding ?? _getDefaultPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: widget.borderRadius ?? _getDefaultBorderRadius(),
        border: widget.showBorder
            ? Border.all(
                color: _getBorderColor(),
                width: 1.0,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconWithBadge(),
          if (widget.text != null) ...[
            const SizedBox(width: 8),
            _buildText(),
          ],
        ],
      ),
    );
  }

  Widget _buildIconWithBadge() {
    Widget iconWidget = _buildIcon();

    if (widget.badgeCount != null && widget.badgeCount! > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -6,
            top: -6,
            child: _buildBadge(),
          ),
        ],
      );
    }

    return iconWidget;
  }

  Widget _buildIcon() {
    if (widget.isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(_getIconColor()),
        ),
      );
    }

    IconData iconData = widget.icon ?? _getTypeIcon();

    return widget.animate
        ? AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return Icon(
                iconData,
                size: _getIconSize(),
                color: widget.isSelected
                    ? _colorAnimation.value
                    : _getIconColor(),
              );
            },
          )
        : Icon(
            iconData,
            size: _getIconSize(),
            color: _getIconColor(),
          );
  }

  Widget _buildBadge() {
    final count = widget.badgeCount!;
    final displayText = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildText() {
    return Text(
      widget.text!,
      style: TextStyle(
        color: _getIconColor(),
        fontSize: _getTextSize(),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Event Handlers
  void _handleTap() {
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    _showLongPressMenu();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  void _showLongPressMenu() {
    if (widget.longPressOptions == null || widget.longPressOptions!.isEmpty) {
      return;
    }

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
          ...widget.longPressOptions!.map((option) => ListTile(
            leading: Icon(
              option.icon,
              color: option.isDangerous
                  ? Colors.red
                  : (option.color ?? Theme.of(context).iconTheme.color),
            ),
            title: Text(
              option.label,
              style: TextStyle(
                color: option.isDangerous ? Colors.red : null,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              option.onTap();
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Styling Methods
  IconData _getTypeIcon() {
    switch (widget.type) {
      case SocialButtonType.like:
        return widget.isSelected ? Icons.favorite : Icons.favorite_border;
      case SocialButtonType.comment:
        return Icons.chat_bubble_outline;
      case SocialButtonType.share:
        return Icons.share;
      case SocialButtonType.follow:
        return widget.isSelected ? Icons.person_remove : Icons.person_add;
      case SocialButtonType.message:
        return Icons.message;
      case SocialButtonType.bookmark:
        return widget.isSelected ? Icons.bookmark : Icons.bookmark_border;
      case SocialButtonType.report:
        return Icons.report_outlined;
      case SocialButtonType.block:
        return Icons.block;
      case SocialButtonType.delete:
        return Icons.delete_outline;
      case SocialButtonType.edit:
        return Icons.edit_outlined;
      case null:
        return Icons.touch_app;
    }
  }

  Color _getIconColor() {
    if (widget.isDisabled) {
      return widget.disabledColor ?? Colors.grey[400]!;
    }

    if (widget.isSelected) {
      return _getSelectedIconColor();
    }

    if (widget.color != null) {
      return widget.color!;
    }

    switch (widget.type) {
      case SocialButtonType.like:
        return Colors.red[600]!;
      case SocialButtonType.comment:
        return Colors.blue[600]!;
      case SocialButtonType.share:
        return Colors.green[600]!;
      case SocialButtonType.follow:
        return Theme.of(context).primaryColor;
      case SocialButtonType.message:
        return Colors.blue[600]!;
      case SocialButtonType.bookmark:
        return Colors.amber[600]!;
      case SocialButtonType.report:
        return Colors.orange[600]!;
      case SocialButtonType.block:
      case SocialButtonType.delete:
        return Colors.red[600]!;
      case SocialButtonType.edit:
        return Colors.grey[600]!;
      case null:
        return Theme.of(context).iconTheme.color ?? Colors.grey[600]!;
    }
  }

  Color _getSelectedIconColor() {
    if (widget.selectedColor != null) {
      return widget.selectedColor!;
    }

    switch (widget.type) {
      case SocialButtonType.like:
        return Colors.red;
      case SocialButtonType.follow:
        return Colors.grey[600]!;
      case SocialButtonType.bookmark:
        return Colors.amber;
      default:
        return _getIconColor();
    }
  }

  Color? _getBackgroundColor() {
    if (widget.isSelected && widget.selectedBackgroundColor != null) {
      return widget.selectedBackgroundColor;
    }
    return widget.backgroundColor;
  }

  Color _getBorderColor() {
    return _getIconColor().withOpacity(0.3);
  }

  EdgeInsetsGeometry _getDefaultPadding() {
    switch (widget.size) {
      case SocialButtonSize.small:
        return const EdgeInsets.all(4);
      case SocialButtonSize.medium:
        return const EdgeInsets.all(8);
      case SocialButtonSize.large:
        return const EdgeInsets.all(12);
    }
  }

  BorderRadius _getDefaultBorderRadius() {
    switch (widget.size) {
      case SocialButtonSize.small:
        return BorderRadius.circular(4);
      case SocialButtonSize.medium:
        return BorderRadius.circular(8);
      case SocialButtonSize.large:
        return BorderRadius.circular(12);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case SocialButtonSize.small:
        return 16;
      case SocialButtonSize.medium:
        return 20;
      case SocialButtonSize.large:
        return 24;
    }
  }

  double _getTextSize() {
    switch (widget.size) {
      case SocialButtonSize.small:
        return 12;
      case SocialButtonSize.medium:
        return 14;
      case SocialButtonSize.large:
        return 16;
    }
  }

  String _getSemanticLabel() {
    String label = widget.text ?? widget.type?.name ?? 'Button';
    
    if (widget.badgeCount != null && widget.badgeCount! > 0) {
      label += ', ${widget.badgeCount} count';
    }
    
    if (widget.isSelected) {
      label += ', selected';
    }
    
    if (widget.isDisabled) {
      label += ', disabled';
    }
    
    return label;
  }
}

/// Extension for creating button groups
extension SocialButtonGroup on List<SocialButton> {
  Widget buildButtonRow({
    MainAxisAlignment alignment = MainAxisAlignment.spaceEvenly,
    double spacing = 16.0,
  }) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        for (int i = 0; i < length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          this[i],
        ],
      ],
    );
  }

  Widget buildButtonColumn({
    MainAxisAlignment alignment = MainAxisAlignment.start,
    double spacing = 8.0,
  }) {
    return Column(
      mainAxisAlignment: alignment,
      children: [
        for (int i = 0; i < length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          this[i],
        ],
      ],
    );
  }
}
