import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!),
      highlightColor: highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[100]!),
      period: period,
      child: child,
    );
  }
}

// Predefined shimmer shapes
class ShimmerCard extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class ShimmerText extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerText({
    super.key,
    this.height = 16,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: size,
        width: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Loading list item
class ShimmerListItem extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;

  const ShimmerListItem({
    super.key,
    this.showAvatar = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          if (showAvatar) ...[
            const ShimmerCircle(size: 48),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerText(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 16,
                ),
                const SizedBox(height: 8),
                ShimmerText(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 14,
                ),
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            const ShimmerText(width: 60, height: 14),
          ],
        ],
      ),
    );
  }
}

// Loading grid item
class ShimmerGridItem extends StatelessWidget {
  final double aspectRatio;

  const ShimmerGridItem({
    super.key,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: const ShimmerCard(height: double.infinity),
    );
  }
}

// Complex loading card
class ShimmerComplexCard extends StatelessWidget {
  final double height;

  const ShimmerComplexCard({
    super.key,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerCircle(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 14,
              width: double.infinity,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: MediaQuery.of(context).size.width * 0.7,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: MediaQuery.of(context).size.width * 0.5,
              color: Colors.grey[300],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 32,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Container(
                  height: 32,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}