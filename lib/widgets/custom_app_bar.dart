import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants/route_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;
  final bool showBackButton;
  final bool useGlassmorphism;

  const CustomAppBar({
    super.key,
    this.actionIcon,
    this.onActionPressed,
    this.showBackButton = true,
    this.useGlassmorphism = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 44);

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: Size.fromHeight(statusBarHeight + kToolbarHeight + 16),
      child: ClipRect(
        child: BackdropFilter(
          filter: useGlassmorphism
              ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.85),
                        Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.75),
                      ]
                    : [
                        Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.85),
                        Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.75),
                      ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.3),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 14, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home Button
                Flexible(
                  child: _AppBarButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go(RoutePaths.home);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Home',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Action Icon
                if (actionIcon != null)
                  _AppBarIconButton(
                    icon: actionIcon!,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onActionPressed?.call();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Styled button for app bar with glassmorphism effect
class _AppBarButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _AppBarButton({required this.onTap, required this.child});

  @override
  State<_AppBarButton> createState() => _AppBarButtonState();
}

class _AppBarButtonState extends State<_AppBarButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    _isPressed
                        ? const Color(0xFF3D2463)
                        : const Color(0xFF4A2F7A),
                    _isPressed
                        ? const Color(0xFF301C4D)
                        : const Color(0xFF3D2463),
                  ]
                : [
                    _isPressed
                        ? const Color(0xFF9B7FDE)
                        : const Color(0xFFA78BFA),
                    _isPressed
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF9B7FDE),
                  ],
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color:
                        (isDark
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF9B7FDE))
                            .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Icon button for app bar
class _AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIconButton({required this.icon, required this.onTap});

  @override
  State<_AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<_AppBarIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _isPressed
              ? Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
              : Theme.of(context).colorScheme.surfaceContainer.withValues(
                  alpha: isDark ? 0.7 : 0.8,
                ),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: isDark ? 0.4 : 0.6),
            width: 1.5,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(
          widget.icon,
          size: 22,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
