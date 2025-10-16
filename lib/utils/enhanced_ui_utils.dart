import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../themes/app_theme.dart';

/// Enhanced UI Utilities for Beautiful, Minimal Design
/// Integrates with your existing Violet Fusion Color System
class EnhancedUIUtils {
  
  /// Beautiful animated card with violet theme
  static Widget animatedVioletCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return Card(
      child: Padding(
        padding: padding as EdgeInsets? ?? const EdgeInsets.all(16),
        child: child,
      ),
    ).animate()
      .fadeIn(duration: animationDuration ?? 600.ms, curve: animationCurve ?? Curves.easeOut)
      .slideY(begin: 0.2, duration: animationDuration ?? 600.ms, curve: animationCurve ?? Curves.easeOut);
  }

  /// Beautiful cached image with violet theme placeholder
  static Widget cachedVioletImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        placeholder: (context, url) => placeholder ?? 
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        errorWidget: (context, url, error) => errorWidget ?? 
          Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(Icons.image, size: 24),
            ),
          ),
      ),
    );
  }

  /// Beautiful staggered grid with violet theme
  static Widget violetStaggeredGrid({
    required List<Widget> children,
    int crossAxisCount = 2,
    double mainAxisSpacing = 8,
    double crossAxisSpacing = 8,
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        itemCount: children.length,
        itemBuilder: (context, index) => children[index]
          .animate(delay: (index * 100).ms)
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3, duration: 600.ms),
      ),
    );
  }

  /// Beautiful SVG icon with violet theme
  static Widget violetSvgIcon({
    required String svgPath,
    double? size,
    Color? color,
    Duration? animationDuration,
  }) {
    return Icon(
      Icons.image, // Fallback icon since SVG is not available
      size: size,
      color: color,
    ).animate()
      .fadeIn(duration: animationDuration ?? 400.ms)
      .scale(begin: const Offset(0.8, 0.8), duration: animationDuration ?? 400.ms);
  }

  /// Beautiful animated button with violet theme
  static Widget animatedVioletButton({
    required String text,
    required VoidCallback onPressed,
    Widget? icon,
    Duration? animationDuration,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      ),
    ).animate()
      .fadeIn(duration: animationDuration ?? 500.ms)
      .slideX(begin: -0.2, duration: animationDuration ?? 500.ms);
  }

  /// Beautiful loading skeleton with violet theme
  static Widget violetSkeleton({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 20,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  /// Beautiful animated list tile with violet theme
  static Widget animatedVioletListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    int index = 0,
  }) {
    return Card(
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    ).animate(delay: (index * 100).ms)
      .fadeIn(duration: 600.ms)
      .slideX(begin: -0.2, duration: 600.ms);
  }

  /// Beautiful status badge with violet theme
  static Widget violetStatusBadge({
    required String text,
    required String status, // 'success', 'warning', 'destructive', 'info'
    Duration? animationDuration,
  }) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'success':
        backgroundColor = SemanticColors.successBackground;
        textColor = SemanticColors.successForeground;
        break;
      case 'warning':
        backgroundColor = SemanticColors.warningBackground;
        textColor = SemanticColors.warningForeground;
        break;
      case 'destructive':
        backgroundColor = SemanticColors.destructiveBackground;
        textColor = SemanticColors.destructiveForeground;
        break;
      default:
        backgroundColor = VioletShades.lightCardBackground;
        textColor = VioletShades.lightTextPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ).animate()
      .fadeIn(duration: animationDuration ?? 400.ms)
      .scale(begin: const Offset(0.8, 0.8), duration: animationDuration ?? 400.ms);
  }

  /// Beautiful animated container with violet theme
  static Widget animatedVioletContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? VioletShades.lightCardBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: child,
    ).animate()
      .fadeIn(duration: animationDuration ?? 600.ms, curve: animationCurve ?? Curves.easeOut)
      .slideY(begin: 0.3, duration: animationDuration ?? 600.ms, curve: animationCurve ?? Curves.easeOut);
  }

  /// Beautiful shimmer loading effect
  static Widget violetShimmer({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 20,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  /// Beautiful animated text with violet theme
  static Widget animatedVioletText({
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
    ).animate()
      .fadeIn(duration: animationDuration ?? 800.ms, curve: animationCurve ?? Curves.easeOut)
      .slideY(begin: 0.2, duration: animationDuration ?? 800.ms, curve: animationCurve ?? Curves.easeOut);
  }

  /// Beautiful animated icon with violet theme
  static Widget animatedVioletIcon({
    required IconData icon,
    double? size,
    Color? color,
    Duration? animationDuration,
  }) {
    return Icon(
      icon,
      size: size,
      color: color,
    ).animate()
      .fadeIn(duration: animationDuration ?? 400.ms)
      .scale(begin: const Offset(0.5, 0.5), duration: animationDuration ?? 400.ms);
  }
}

/// Hook-based utilities for minimal state management
class VioletHooks {
  
  /// Hook for animated counter with violet theme
  static Widget animatedCounter({
    required int initialValue,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    final counter = useState(initialValue);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            counter.value--;
            onDecrement();
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(width: 16),
        Text(
          '${counter.value}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ).animate()
          .scale(begin: const Offset(1.2, 1.2), duration: 200.ms)
          .then()
          .scale(begin: const Offset(1.0, 1.0), duration: 200.ms),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            counter.value++;
            onIncrement();
          },
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  /// Hook for animated toggle with violet theme
  static Widget animatedToggle({
    required bool initialValue,
    required ValueChanged<bool> onChanged,
    String? label,
  }) {
    final isEnabled = useState(initialValue);
    
    return Row(
      children: [
        if (label != null) ...[
          Text(label),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: () {
            isEnabled.value = !isEnabled.value;
            onChanged(isEnabled.value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: isEnabled.value ? VioletShades.lightAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: isEnabled.value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Extension for easy access to enhanced UI utilities
extension EnhancedUIExtension on BuildContext {
  
  /// Quick access to animated violet card
  Widget animatedVioletCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Duration? animationDuration,
    Curve? animationCurve,
  }) => EnhancedUIUtils.animatedVioletCard(
    child: child,
    padding: padding,
    borderRadius: borderRadius,
    animationDuration: animationDuration,
    animationCurve: animationCurve,
  );

  /// Quick access to cached violet image
  Widget cachedVioletImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) => EnhancedUIUtils.cachedVioletImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    borderRadius: borderRadius,
    placeholder: placeholder,
    errorWidget: errorWidget,
  );

  /// Quick access to violet status badge
  Widget violetStatusBadge({
    required String text,
    required String status,
    Duration? animationDuration,
  }) => EnhancedUIUtils.violetStatusBadge(
    text: text,
    status: status,
    animationDuration: animationDuration,
  );

  /// Quick access to animated violet text
  Widget animatedVioletText({
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    Duration? animationDuration,
    Curve? animationCurve,
  }) => EnhancedUIUtils.animatedVioletText(
    text: text,
    style: style,
    textAlign: textAlign,
    animationDuration: animationDuration,
    animationCurve: animationCurve,
  );
} 