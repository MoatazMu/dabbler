import 'package:flutter/material.dart';
import 'package:dabbler/themes/app_theme.dart';

/// Standard two-section layout for all screens using Material Design 3
/// Top section: Category-colored background with rounded bottom corners
/// Bottom section: Surface color with content
class TwoSectionLayout extends StatelessWidget {
  /// Content for the top section
  final Widget topSection;

  /// Content for the bottom section
  final Widget bottomSection;

  /// Optional padding for top section (default: 24px)
  final EdgeInsets? topPadding;

  /// Optional padding for bottom section (default: 24px)
  final EdgeInsets? bottomPadding;

  /// Custom top section background color (overrides category color)
  final Color? topBackgroundColor;

  /// Custom bottom section background color (overrides surface color)
  final Color? bottomBackgroundColor;

  /// Category for top section color ('main', 'social', 'sports', 'activities', 'profile')
  final String? category;

  const TwoSectionLayout({
    super.key,
    required this.topSection,
    required this.bottomSection,
    this.topPadding,
    this.bottomPadding,
    this.topBackgroundColor,
    this.bottomBackgroundColor,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    // Get device corner radius dynamically based on safe area insets
    final topInset = MediaQuery.of(context).padding.top;
    // Approximate device corner radius based on top safe area
    // iPhone models with notch/Dynamic Island have ~39-47px radius
    final deviceRadius = topInset > 20 ? 50.0 : 0.0;

    return Scaffold(
      // Black background to simulate device bezel
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(4),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(deviceRadius > 0 ? 52 : 0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== TOP SECTION - Category Background ==========
              Container(
                width: double.infinity,
                padding:
                    topPadding ??
                    const EdgeInsets.only(
                      top: 24,
                      left: 24,
                      right: 24,
                      bottom: 18,
                    ),
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  // Use category color or custom color or default to primary
                  color:
                      topBackgroundColor ??
                      (category != null
                          ? Theme.of(context).colorScheme.getCategoryColor(category!)
                          : Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(deviceRadius > 0 ? 50 : 0),
                      topRight: Radius.circular(deviceRadius > 0 ? 50 : 0),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                ),
                child: topSection,
              ),

              // 4px gap between sections
              const SizedBox(height: 4),

              // ========== BOTTOM SECTION - Material 3 Surface ==========
              Container(
                width: double.infinity,
                padding: bottomPadding ?? const EdgeInsets.all(24),
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color:
                      bottomBackgroundColor ??
                      Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(deviceRadius > 0 ? 50 : 0),
                      bottomRight: Radius.circular(deviceRadius > 0 ? 50 : 0),
                    ),
                  ),
                ),
                child: bottomSection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
