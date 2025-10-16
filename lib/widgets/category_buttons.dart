import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../themes/app_theme.dart';

/// Category Buttons Widget - Community, Sports, Activities
/// Polished with proper button states and theme support
class CategoryButtons extends StatelessWidget {
  const CategoryButtons({
    super.key,
    this.onCommunityTap,
    this.onSportsTap,
    this.onActivitiesTap,
  });

  final VoidCallback? onCommunityTap;
  final VoidCallback? onSportsTap;
  final VoidCallback? onActivitiesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Community Button
        _CategoryButton(
          icon: Iconsax.hashtag_copy,
          label: 'Community',
          accentColor: const Color(0xFFFFCA71), // Golden yellow
          onTap: onCommunityTap,
        ),
        const SizedBox(width: 8),
        
        // Sports Button
        _CategoryButton(
          icon: Iconsax.game_copy,
          label: 'Sports',
          accentColor: const Color(0xFF05DF72), // Green
          onTap: onSportsTap,
        ),
        const SizedBox(width: 8),
        
        // Activities Button
        _CategoryButton(
          icon: Iconsax.archive_copy,
          label: 'Activities',
          accentColor: const Color(0xFFFF8383), // Coral red
          onTap: onActivitiesTap,
        ),
      ],
    );
  }
}

class _CategoryButton extends StatefulWidget {
  const _CategoryButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  State<_CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<_CategoryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Background colors based on theme and state
    final backgroundColor = _getBackgroundColor(isDark);
    final borderColor = _getBorderColor(isDark);
    
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: _isHovered ? 1.5 : 1,
              ),
              color: backgroundColor,
              boxShadow: _isPressed
                  ? []
                  : _isHovered
                      ? [
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
            ),
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.96 : 1.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: _getIconColor(isDark),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: _getTextColor(isDark),
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    if (_isPressed) {
      return isDark
          ? VioletShades.darkAccent
          : VioletShades.lightAccent;
    }
    
    if (_isHovered) {
      return isDark
          ? VioletShades.darkWidgetBackground
          : VioletShades.lightWidgetBackground;
    }
    
    return isDark
        ? VioletShades.darkCardBackground
        : VioletShades.lightCardBackground;
  }

  Color _getBorderColor(bool isDark) {
    if (_isHovered || _isPressed) {
      return widget.accentColor.withOpacity(_isPressed ? 0.6 : 0.4);
    }
    
    return isDark
        ? VioletShades.darkBorder.withOpacity(0.3)
        : VioletShades.lightBorder.withOpacity(0.5);
  }

  Color _getIconColor(bool isDark) {
    if (_isPressed || _isHovered) {
      return widget.accentColor;
    }
    
    return widget.accentColor.withOpacity(isDark ? 0.9 : 0.85);
  }

  Color _getTextColor(bool isDark) {
    if (_isPressed || _isHovered) {
      return widget.accentColor;
    }
    
    return widget.accentColor.withOpacity(isDark ? 0.9 : 0.85);
  }
}
