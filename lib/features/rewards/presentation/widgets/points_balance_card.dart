import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../themes/app_text_styles.dart';
import '../../../../utils/helpers/number_formatter.dart';
import '../providers/rewards_providers.dart';

class PointsBalanceCard extends ConsumerWidget {
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const PointsBalanceCard({
    super.key,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPoints = ref.watch(userTotalPointsProvider);

    return Container(
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
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
                    'Total Points',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormatter.format(totalPoints),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to see history',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideX(begin: -0.2, end: 0, duration: 600.ms);
  }
}