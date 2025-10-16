import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_text_styles.dart';
import '../../../../utils/helpers/number_formatter.dart';
import '../providers/rewards_providers.dart';

class TierProgressCard extends ConsumerWidget {
  final double animationValue;
  final EdgeInsetsGeometry? margin;

  const TierProgressCard({
    super.key,
    this.animationValue = 1.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTier = ref.watch(userCurrentTierProvider);

    if (currentTier == null) {
      return const SizedBox.shrink();
    }

    final tierName = currentTier.level.displayName;
    final progress = currentTier.calculateProgress() / 100.0;
    final pointsToNext = currentTier.getPointsToNextTier();
    final nextTier = currentTier.getNextTier();

    return Container(
      margin: margin,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getTierColor(currentTier.level.displayName).withOpacity(0.8),
              _getTierColor(currentTier.level.displayName).withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getTierColor(currentTier.level.displayName).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Tier',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tierName.toUpperCase(),
                      style: AppTextStyles.title.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTierIcon(currentTier.level.displayName),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (nextTier != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next: ${nextTier.displayName.toUpperCase()}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${NumberFormatter.format(pointsToNext.round())} pts to go',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress * animationValue,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${(progress * 100).toStringAsFixed(1)}% complete',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white70,
                ),
              ),
            ] else ...[
              // Max tier reached
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Maximum tier reached!',
                    style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Tier benefits preview
            if (currentTier.benefits.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Current Benefits',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: currentTier.benefits.entries.take(3).map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.key,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 200.ms)
      .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms);
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'fresh player':
        return const Color(0xFF8B4513);
      case 'rookie':
        return const Color(0xFFCD7F32);
      case 'novice':
        return const Color(0xFFC0C0C0);
      case 'amateur':
        return const Color(0xFFFFD700);
      case 'enthusiast':
        return const Color(0xFF50C878);
      case 'competitor':
        return const Color(0xFF4169E1);
      case 'skilled':
        return const Color(0xFF8A2BE2);
      case 'expert':
        return const Color(0xFFFF6347);
      case 'veteran':
        return const Color(0xFFFF1493);
      case 'elite':
        return const Color(0xFF00CED1);
      case 'master':
        return const Color(0xFFFF4500);
      case 'grandmaster':
        return const Color(0xFFDC143C);
      case 'legend':
        return const Color(0xFF8B0000);
      case 'champion':
        return const Color(0xFFFFD700);
      case 'dabbler':
        return const Color(0xFFFF6B35);
      default:
        return Colors.blue;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'fresh player':
        return Icons.eco;
      case 'rookie':
        return Icons.star_border;
      case 'novice':
        return Icons.security;
      case 'amateur':
        return Icons.workspace_premium;
      case 'enthusiast':
        return Icons.local_fire_department;
      case 'competitor':
        return Icons.sports_esports;
      case 'skilled':
        return Icons.diamond_outlined;
      case 'expert':
        return Icons.emoji_events;
      case 'veteran':
        return Icons.terrain;
      case 'elite':
        return Icons.diamond;
      case 'master':
        return Icons.auto_stories;
      case 'grandmaster':
        return Icons.flight;
      case 'legend':
        return Icons.whatshot;
      case 'champion':
        return Icons.emoji_events;
      case 'dabbler':
        return Icons.all_inclusive;
      default:
        return Icons.star_border;
    }
  }
}