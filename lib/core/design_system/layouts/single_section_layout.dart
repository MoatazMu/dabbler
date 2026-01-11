import 'package:flutter/material.dart';
import 'package:dabbler/themes/app_theme.dart';

/// Reusable single-section layout component
/// Can be used as a standalone screen (with Scaffold) or as a child widget
/// Maintains consistent styling with Material Design 3 tokens
class SingleSectionLayout extends StatelessWidget {
  /// Content for the section
  final Widget child;

  /// Optional padding for section (default: 24px)
  final EdgeInsets? padding;

  /// Custom section background color (overrides token color)
  final Color? backgroundColor;

  /// Category for section color ('main', 'social', 'sports', 'activities', 'profile')
  final String? category;

  /// Whether to wrap in Scaffold (true for standalone screens, false for nested use)
  final bool withScaffold;

  /// Whether to make content scrollable
  final bool scrollable;

  /// Optional app bar (only used when withScaffold is true)
  final PreferredSizeWidget? appBar;

  /// Optional floating action button (only used when withScaffold is true)
  final Widget? floatingActionButton;

  /// Optional floating action button location (only used when withScaffold is true)
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Optional pull-to-refresh callback (only used when scrollable is true)
  final Future<void> Function()? onRefresh;

  /// Custom scroll physics
  final ScrollPhysics? physics;

  const SingleSectionLayout({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.category,
    this.withScaffold = true,
    this.scrollable = true,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.onRefresh,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final currentScheme = Theme.of(context).colorScheme;
    final scheme = category != null
        ? context.getCategoryTheme(category!)
        : currentScheme;
    final sectionColor = backgroundColor ?? scheme.secondaryContainer;

    // Get device corner radius dynamically based on safe area insets
    final topInset = MediaQuery.of(context).padding.top;
    // Approximate device corner radius based on top safe area
    // iPhone models with notch/Dynamic Island have ~39-47px radius
    final deviceRadius = topInset > 20 ? 50.0 : 0.0;

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomNavHeight = MediaQuery.of(context).padding.bottom + 80;

    // Unified: Only one container, using sectionColor for background
    final content = Container(
      width: double.infinity,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 0, vertical: 48),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: sectionColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(deviceRadius > 0 ? 50 : 0),
        ),
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: scheme.onSecondaryContainer),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: scheme.onSecondaryContainer),
          child: child,
        ),
      ),
    );

    // Wrap in scrollable if needed
    Widget body = content;
    if (scrollable) {
      final appBarHeight = appBar?.preferredSize.height ?? 0;

      final scrollView = SingleChildScrollView(
        physics:
            physics ??
            const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (screenHeight - bottomNavHeight - appBarHeight)
                .clamp(0.0, double.infinity)
                .toDouble(),
          ),
          child: content,
        ),
      );

      body = onRefresh != null
          ? RefreshIndicator(onRefresh: onRefresh!, child: scrollView)
          : scrollView;
    }

    // Return with or without Scaffold based on configuration
    if (withScaffold) {
      return Scaffold(
        backgroundColor: sectionColor,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        extendBody: true,
        body: body,
      );
    }

    return body;
  }
}

/// Convenience constructor for using SingleSectionLayout as a nested widget (without Scaffold)
class SingleSectionContainer extends SingleSectionLayout {
  const SingleSectionContainer({
    super.key,
    required super.child,
    super.padding,
    super.backgroundColor,
    super.category,
    super.scrollable = false,
    super.physics,
  }) : super(withScaffold: false);
}
