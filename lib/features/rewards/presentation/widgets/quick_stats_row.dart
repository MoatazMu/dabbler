import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_text_styles.dart';
import '../../../../utils/helpers/number_formatter.dart';

class QuickStatsRow extends ConsumerWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for demonstration
    const badgeCount = 12;
    const rank = 156;
    const streak = 7;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.military_tech,
            label: 'Badges',
            value: badgeCount.toString(),
            color: Colors.amber,
          ).animate()
            .fadeIn(duration: 600.ms, delay: 100.ms)
            .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 100.ms),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.leaderboard,
            label: 'Rank',
            value: NumberFormatter.formatRank(rank),
            color: Colors.green,
          ).animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '$streak days',
            color: Colors.orange,
          ).animate()
            .fadeIn(duration: 600.ms, delay: 300.ms)
            .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 300.ms),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}