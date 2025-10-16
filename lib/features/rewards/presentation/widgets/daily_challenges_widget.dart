import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_text_styles.dart';

class DailyChallengesWidget extends StatelessWidget {
  final Function(String) onChallengeComplete;

  const DailyChallengesWidget({
    super.key,
    required this.onChallengeComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Mock challenge data
    final challenges = [
      {'id': '1', 'title': 'Play 3 Games', 'progress': 2, 'target': 3, 'completed': false},
      {'id': '2', 'title': 'Win a Match', 'progress': 0, 'target': 1, 'completed': false},
      {'id': '3', 'title': 'Make a Friend', 'progress': 1, 'target': 1, 'completed': true},
    ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Challenges',
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${challenges.where((c) => c['completed'] == true).length}/${challenges.length}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...challenges.map((challenge) {
            final progress = challenge['progress'] as int;
            final target = challenge['target'] as int;
            final completed = challenge['completed'] as bool;
            final progressPercent = progress / target;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: completed 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: completed 
                    ? Border.all(color: Colors.green.withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: completed ? Colors.green : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      completed ? Icons.check : Icons.radio_button_unchecked,
                      color: completed ? Colors.white : Colors.grey.shade600,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge['title'] as String,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: completed ? Colors.green : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (!completed) ...[
                          LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade400,
                            ),
                            minHeight: 4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$progress/$target',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Completed! 🎉',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: 1000.ms)
      .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 1000.ms);
  }
}