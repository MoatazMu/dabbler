import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_text_styles.dart';

class PointsHistoryChart extends StatelessWidget {
  const PointsHistoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for points history (last 7 days)
    final pointsData = [120, 85, 200, 150, 300, 180, 220];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxPoints = pointsData.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Points This Week',
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${pointsData.reduce((a, b) => a + b)} points',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(pointsData.length, (index) {
                final points = pointsData[index];
                final height = (points / maxPoints * 100).clamp(20.0, 100.0);
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.shade400,
                            Colors.blue.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms, delay: Duration(milliseconds: index * 100))
                      .slideY(begin: 1, end: 0, duration: 600.ms, delay: Duration(milliseconds: index * 100)),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade600,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Points Earned',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 800.ms, delay: 300.ms)
      .slideY(begin: -0.2, end: 0, duration: 800.ms, delay: 300.ms);
  }
}