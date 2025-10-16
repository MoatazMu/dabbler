
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'rewards_analytics_dashboard.dart'; // Import analytics data classes

// Tier Progression Statistics Dashboard
class TierProgressionDashboard extends ConsumerWidget {
  const TierProgressionDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierData = ref.watch(tierAnalyticsProvider);

    return tierData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tier Distribution Overview
            _buildSectionHeader('Current Tier Distribution'),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: data.tierDistribution.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}%',
                      color: _getTierColor(entry.key),
                      radius: 80,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Tier Progression Rate
            _buildSectionHeader('Monthly Tier Progression'),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.monthlyProgressions.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barGroups: data.monthlyProgressions.entries.map((entry) {
                    final index = data.monthlyProgressions.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: _getTierColor(entry.key),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final tiers = data.monthlyProgressions.keys.toList();
                          if (value.toInt() < tiers.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                tiers[value.toInt()],
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Average Time to Tier
            _buildSectionHeader('Average Time to Reach Tier'),
            const SizedBox(height: 16),
            ...data.averageTimeToTier.entries.map((entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getTierColor(entry.key),
                  child: Text(
                    entry.key.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text('${entry.key} Tier'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.value} days',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze': return Colors.brown;
      case 'silver': return Colors.grey;
      case 'gold': return Colors.amber;
      case 'platinum': return Colors.blue[200]!;
      case 'diamond': return Colors.cyan;
      default: return Colors.grey;
    }
  }
}

// Popular Achievements Dashboard
class PopularAchievementsDashboard extends ConsumerWidget {
  const PopularAchievementsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularData = ref.watch(popularAchievementsProvider);

    return popularData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Achievements by Completion Rate
            _buildSectionHeader('Most Completed Achievements'),
            const SizedBox(height: 16),
            ...data.mostCompleted.asMap().entries.map((entry) {
              final index = entry.key;
              final achievement = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _getRankColor(index),
                          _getRankColor(index).withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    achievement.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${achievement.category} • ${achievement.difficulty}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(achievement.completionRate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${achievement.completedCount} users',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            
            // Trending Achievements
            _buildSectionHeader('Trending Achievements (This Week)'),
            const SizedBox(height: 16),
            ...data.trending.map((achievement) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.red[600],
                  ),
                ),
                title: Text(
                  achievement.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  achievement.category,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${achievement.weeklyGrowth.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '${achievement.weeklyCompletions} this week',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),
            
            // Least Popular Achievements
            _buildSectionHeader('Underperforming Achievements'),
            const SizedBox(height: 16),
            ...data.underperforming.map((achievement) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.orange[50],
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber,
                    color: Colors.orange[600],
                  ),
                ),
                title: Text(
                  achievement.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${achievement.category} • Needs attention',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(achievement.completionRate * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Low completion rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0: return Colors.amber; // Gold
      case 1: return Colors.grey; // Silver
      case 2: return Colors.brown; // Bronze
      default: return Colors.blue;
    }
  }
}

// Abandonment Analysis Dashboard
class AbandonmentAnalysisDashboard extends ConsumerWidget {
  const AbandonmentAnalysisDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abandonmentData = ref.watch(abandonmentAnalyticsProvider);

    return abandonmentData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Overall Abandonment Rate',
                    '${(data.overallAbandonmentRate * 100).toStringAsFixed(1)}%',
                    Icons.exit_to_app,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Average Progress at Abandonment',
                    '${(data.averageProgressAtAbandonment * 100).toStringAsFixed(1)}%',
                    Icons.timeline,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Abandonment by Progress Stage
            _buildSectionHeader('Abandonment by Progress Stage'),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          '${(value * 10).toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 10,
                  minY: 0,
                  maxY: data.abandonmentByProgress.values.reduce((a, b) => a > b ? a : b) * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.abandonmentByProgress.entries.map((entry) {
                        return FlSpot(entry.key, entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Most Abandoned Achievements
            _buildSectionHeader('Most Abandoned Achievements'),
            const SizedBox(height: 16),
            ...data.mostAbandonedAchievements.map((achievement) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.red[50],
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cancel,
                    color: Colors.red[600],
                  ),
                ),
                title: Text(
                  achievement.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${achievement.category} • ${achievement.difficulty}'),
                    const SizedBox(height: 4),
                    Text(
                      'Common drop-off: ${achievement.commonDropOffPoint}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(achievement.abandonmentRate * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '${achievement.abandonedCount} users',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),
            
            // Recommendations
            _buildSectionHeader('Optimization Recommendations'),
            const SizedBox(height: 16),
            ...data.recommendations.map((recommendation) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.blue[50],
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRecommendationIcon(recommendation.type),
                    color: Colors.blue[600],
                  ),
                ),
                title: Text(
                  recommendation.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(recommendation.description),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(recommendation.priority),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    recommendation.priority.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRecommendationIcon(String type) {
    switch (type) {
      case 'difficulty': return Icons.tune;
      case 'rewards': return Icons.star;
      case 'guidance': return Icons.help;
      case 'progression': return Icons.trending_up;
      default: return Icons.lightbulb;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }
}

// Data classes for additional dashboards
class TierAnalyticsData {
  final Map<String, int> tierDistribution;
  final Map<String, int> monthlyProgressions;
  final Map<String, int> averageTimeToTier;

  TierAnalyticsData({
    required this.tierDistribution,
    required this.monthlyProgressions,
    required this.averageTimeToTier,
  });
}

class PopularAchievementsData {
  final List<PopularAchievement> mostCompleted;
  final List<TrendingAchievement> trending;
  final List<PopularAchievement> underperforming;

  PopularAchievementsData({
    required this.mostCompleted,
    required this.trending,
    required this.underperforming,
  });
}

class PopularAchievement {
  final String id;
  final String name;
  final String category;
  final String difficulty;
  final double completionRate;
  final int completedCount;

  PopularAchievement({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.completionRate,
    required this.completedCount,
  });
}

class TrendingAchievement {
  final String id;
  final String name;
  final String category;
  final double weeklyGrowth;
  final int weeklyCompletions;

  TrendingAchievement({
    required this.id,
    required this.name,
    required this.category,
    required this.weeklyGrowth,
    required this.weeklyCompletions,
  });
}

class AbandonmentAnalyticsData {
  final double overallAbandonmentRate;
  final double averageProgressAtAbandonment;
  final Map<double, double> abandonmentByProgress;
  final List<AbandonedAchievement> mostAbandonedAchievements;
  final List<Recommendation> recommendations;

  AbandonmentAnalyticsData({
    required this.overallAbandonmentRate,
    required this.averageProgressAtAbandonment,
    required this.abandonmentByProgress,
    required this.mostAbandonedAchievements,
    required this.recommendations,
  });
}

class AbandonedAchievement {
  final String id;
  final String name;
  final String category;
  final String difficulty;
  final double abandonmentRate;
  final int abandonedCount;
  final String commonDropOffPoint;

  AbandonedAchievement({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.abandonmentRate,
    required this.abandonedCount,
    required this.commonDropOffPoint,
  });
}

class Recommendation {
  final String type;
  final String title;
  final String description;
  final String priority;

  Recommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
  });
}

// Additional providers
final tierAnalyticsProvider = FutureProvider<TierAnalyticsData>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return await analyticsService.getTierAnalytics();
});

final popularAchievementsProvider = FutureProvider<PopularAchievementsData>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return await analyticsService.getPopularAchievementsData();
});

final abandonmentAnalyticsProvider = FutureProvider<AbandonmentAnalyticsData>((ref) async {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return await analyticsService.getAbandonmentAnalytics();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Mock Analytics Service for demonstration
class AnalyticsService {
  Future<AchievementAnalyticsData> getAchievementAnalytics() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    // Return mock data...
    throw UnimplementedError('Analytics service implementation needed');
  }

  Future<EngagementAnalyticsData> getEngagementAnalytics() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Analytics service implementation needed');
  }

  Future<PointsAnalyticsData> getPointsAnalytics() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Analytics service implementation needed');
  }

  Future<TierAnalyticsData> getTierAnalytics() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Analytics service implementation needed');
  }

  Future<PopularAchievementsData> getPopularAchievementsData() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Analytics service implementation needed');
  }

  Future<AbandonmentAnalyticsData> getAbandonmentAnalytics() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Analytics service implementation needed');
  }
}