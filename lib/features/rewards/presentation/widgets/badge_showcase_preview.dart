import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_text_styles.dart';

class BadgeShowcasePreview extends StatelessWidget {
  final VoidCallback? onTap;

  const BadgeShowcasePreview({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Mock badge data
    const totalBadges = 12;
    const rareBadges = 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Badges',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBadgeStack(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalBadges Total',
                        style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$rareBadges rare badges',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 800.ms)
      .slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 800.ms);
  }

  Widget _buildBadgeStack() {
    return SizedBox(
      width: 50,
      height: 40,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.military_tech,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          Positioned(
            left: 18,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}