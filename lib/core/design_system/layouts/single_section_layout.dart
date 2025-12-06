import 'package:flutter/material.dart';
import 'package:dabbler/core/design_system/tokens/design_tokens.dart';

/// Single-section layout for screens that only need the dark section
/// Uses Material Design 3 with design tokens
/// Section: Surface color with content (similar to bottom section of TwoSectionLayout)
class SingleSectionLayout extends StatelessWidget {
  /// Content for the section
  final Widget child;

  /// Optional padding for section (default: 24px)
  final EdgeInsets? padding;

  /// Custom section background color (overrides surface color)
  final Color? backgroundColor;

  /// Category for section color ('main', 'social', 'sports', 'activities', 'profile')
  final String? category;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// Optional floating action button location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Optional pull-to-refresh callback
  final Future<void> Function()? onRefresh;

  /// Optional app bar
  final PreferredSizeWidget? appBar;

  const SingleSectionLayout({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.category,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onRefresh,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    // Get color tokens for current theme/category
    final tokens = category != null
        ? context.getCategoryColorTokens(category!)
        : context.colorTokens;

    // Get device corner radius dynamically based on safe area insets
    final topInset = MediaQuery.of(context).padding.top;
    // Approximate device corner radius based on top safe area
    // iPhone models with notch/Dynamic Island have ~39-47px radius
    final deviceRadius = topInset > 20 ? 50.0 : 0.0;

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = appBar?.preferredSize.height ?? 0;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomNavHeight = MediaQuery.of(context).padding.bottom + 80;

    final scrollView = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: screenHeight - bottomNavHeight - appBarHeight - topPadding,
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: tokens.app, // Use token for app background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(deviceRadius > 0 ? 52 : 0),
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(24),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              // Use token section color (dark section background)
              color: backgroundColor ?? tokens.section,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(deviceRadius > 0 ? 50 : 0),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    return Scaffold(
      // Use token app color for background
      backgroundColor: tokens.app,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBody: true,
      body: onRefresh != null
          ? RefreshIndicator(onRefresh: onRefresh!, child: scrollView)
          : scrollView,
    );
  }
}
