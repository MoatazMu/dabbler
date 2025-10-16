import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_text_styles.dart';

class AchievementCarousel extends StatelessWidget {
  final Function(dynamic) onAchievementTap;
  final Function(String) onShare;

  const AchievementCarousel({
    super.key,
    required this.onAchievementTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    // Mock achievement data
    final achievements = [
      {'name': 'First Victory', 'description': 'Win your first game', 'icon': Icons.emoji_events},
      {'name': 'Social Butterfly', 'description': 'Make 10 friends', 'icon': Icons.people},
      {'name': 'Explorer', 'description': 'Visit 5 different venues', 'icon': Icons.explore},
      {'name': 'Streak Master', 'description': 'Play for 7 days straight', 'icon': Icons.local_fire_department},
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => onAchievementTap(achievement),
            onLongPress: () => onShare(achievement['name'] as String),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      achievement['icon'] as IconData,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    achievement['name'] as String,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['description'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ).animate()
          .fadeIn(duration: 600.ms, delay: Duration(milliseconds: index * 100))
          .slideX(begin: 0.2, end: 0, duration: 600.ms, delay: Duration(milliseconds: index * 100));
      },
    );
  }
}