import 'package:flutter/material.dart';
import 'elegant_loading_screen.dart';
import 'loading_spinner.dart';

/// Examples of how to use the different loading screen widgets
class LoadingScreenExamples {
  
  /// Show a full-screen elegant loading screen
  static Widget showElegantLoading({
    String? title,
    String? subtitle,
    String? logoPath,
    Color? accentColor,
    bool showProgress = true,
  }) {
    return ElegantLoadingScreen(
      title: title ?? 'Loading...',
      subtitle: subtitle ?? 'Please wait while we prepare your experience',
      logoPath: logoPath ?? 'assets/logo.png',
      accentColor: accentColor,
      showProgress: showProgress,
    );
  }
  
  /// Show a simple loading screen
  static Widget showSimpleLoading({
    String? message,
    String? logoPath,
    Color? accentColor,
  }) {
    return SimpleLoadingScreen(
      message: message ?? 'Loading...',
      logoPath: logoPath,
      accentColor: accentColor,
    );
  }
  
  /// Show an enhanced loading spinner with logo
  static Widget showEnhancedSpinner({
    String? message,
    String? logoPath,
    double size = 50,
    Color? color,
  }) {
    return LoadingSpinner(
      message: message,
      logoPath: logoPath,
      showLogo: logoPath != null,
      size: size,
      color: color,
    );
  }
  
  /// Show a minimal loading indicator
  static Widget showMinimalIndicator({
    double size = 20,
    Color? color,
    double strokeWidth = 2.0,
  }) {
    return MinimalLoadingIndicator(
      size: size,
      color: color,
      strokeWidth: strokeWidth,
    );
  }
  
  /// Show a loading overlay on top of existing content
  static Widget showLoadingOverlay({
    required Widget child,
    required bool isLoading,
    String? message,
    Color? backgroundColor,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MinimalLoadingIndicator(size: 40),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Show a loading button with text
  static Widget showLoadingButton({
    required String text,
    required bool isLoading,
    required VoidCallback? onPressed,
    String? loadingText,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(48),
      ),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MinimalLoadingIndicator(
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(loadingText ?? 'Loading...'),
              ],
            )
          : Text(text),
    );
  }
}

/// Usage examples for different scenarios
class LoadingScreenUsageExamples {
  
  /// Example: Show loading while fetching data
  static Widget buildDataLoadingExample() {
    return Scaffold(
      body: LoadingScreenExamples.showLoadingOverlay(
        child: const Center(
          child: Text('Your app content here'),
        ),
        isLoading: true,
        message: 'Fetching data...',
      ),
    );
  }
  
  /// Example: Show loading button
  static Widget buildLoadingButtonExample() {
    return Scaffold(
      body: Center(
        child: LoadingScreenExamples.showLoadingButton(
          text: 'Submit',
          isLoading: true,
          onPressed: () {},
          loadingText: 'Submitting...',
        ),
      ),
    );
  }
  
  /// Example: Show elegant loading screen
  static Widget buildElegantLoadingExample() {
    return LoadingScreenExamples.showElegantLoading(
      title: 'Welcome to Dabbler',
      subtitle: 'Setting up your personalized experience...',
      logoPath: 'assets/logo.png',
      accentColor: Colors.purple,
    );
  }
  
  /// Example: Show simple loading screen
  static Widget buildSimpleLoadingExample() {
    return LoadingScreenExamples.showSimpleLoading(
      message: 'Please wait...',
      logoPath: 'assets/logo.png',
    );
  }
}
