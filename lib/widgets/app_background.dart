import 'package:flutter/material.dart';

/// AppBackground renders a full-screen gradient behind the entire app.
///
/// Gradients:
/// - Light: linear-gradient(137deg, #F5EDFF 10.52%, #EADAFF 89.32%)
/// - Dark:  linear-gradient(137deg, #1E0E33 10.52%, #5B2B99 89.32%)
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Approximate 137° using a diagonal gradient direction.
    // Fine-grained angle control isn’t required; visual parity is the goal.
    final begin = const Alignment(-0.8, -1.0); // near top-left
    final end = const Alignment(1.0, 0.8); // near bottom-right

    final colors = isDark
        ? const [Color(0xFF1E0E33), Color(0xFF5B2B99)]
        : const [Color(0xFFF5EDFF), Color(0xFFEADAFF)];

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: colors,
            stops: const [0.1052, 0.8932],
          ),
        ),
      ),
    );
  }
}
