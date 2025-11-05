import 'package:flutter/material.dart';
import 'package:dabbler/core/design_system/colors/app_colors.dart';

/// Standard two-section layout for all screens
/// Top section: Purple background with rounded bottom corners
/// Bottom section: Dark background with content
class TwoSectionLayout extends StatelessWidget {
  /// Content for the top purple section
  final Widget topSection;

  /// Content for the bottom dark section
  final Widget bottomSection;

  /// Optional padding for top section (default: 20px all sides)
  final EdgeInsets? topPadding;

  /// Optional padding for bottom section (default: 20px all sides)
  final EdgeInsets? bottomPadding;

  /// Custom top section background color (default: purple)
  final Color? topBackgroundColor;

  /// Custom bottom section background color (default: dark)
  final Color? bottomBackgroundColor;

  const TwoSectionLayout({
    super.key,
    required this.topSection,
    required this.bottomSection,
    this.topPadding,
    this.bottomPadding,
    this.topBackgroundColor,
    this.bottomBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bottomBackgroundColor ?? AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== TOP SECTION - Purple Background ==========
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: topBackgroundColor ?? AppColors.primaryPurple,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(52),
                    bottomRight: Radius.circular(52),
                  ),
                ),
                padding:
                    topPadding ?? const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: topSection,
              ),

              // ========== BOTTOM SECTION - Dark Background ==========
              Padding(
                padding: bottomPadding ?? const EdgeInsets.all(20),
                child: bottomSection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
