import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/activity_log.dart';
import '../models/activity_log_model.dart';

/// Remote data source for activity logs using Supabase
abstract class ActivityLogRemoteDataSource {
  Future<List<ActivityLogModel>> getUserActivities({
    required String userId,
    ActivityType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });

  Future<Map<String, int>> getUserActivityStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ActivityLogModel> createActivity(ActivityLogModel activity);

  Future<ActivityLogModel> updateActivity({
    required String activityId,
    ActivityStatus? status,
    String? description,
    Map<String, dynamic>? metadata,
  });

  Future<bool> deleteActivity(String activityId);

  Future<Map<String, int>> getCategoryStats(String userId);
}

class ActivityLogRemoteDataSourceImpl implements ActivityLogRemoteDataSource {
  final SupabaseClient supabaseClient;

  ActivityLogRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ActivityLogModel>> getUserActivities({
    required String userId,
    ActivityType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Build query step by step
      var query = supabaseClient
          .from('activity_log')
          .select()
          .eq('user_id', userId);

      // Apply type filter
      if (type != null) {
        query = query.eq('activity_type', type.name);
      }

      // Apply date range filters
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // Apply ordering and pagination at the end
      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      List<ActivityLogModel> activities = (response as List)
          .map(
            (json) => ActivityLogModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      // Apply category filter in memory (since category is derived)
      if (category != null && category != 'All') {
        activities = activities.where((a) => a.category == category).toList();
      }

      return activities;
    } catch (e) {
      throw Exception('Failed to fetch activities: $e');
    }
  }

  @override
  Future<Map<String, int>> getUserActivityStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = supabaseClient
          .from('activity_log')
          .select('activity_type')
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query;

      final Map<String, int> stats = {};

      for (final item in response as List) {
        final type = item['activity_type'] as String;
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch activity stats: $e');
    }
  }

  @override
  Future<ActivityLogModel> createActivity(ActivityLogModel activity) async {
    try {
      final data = activity.toJson();
      data.remove('id'); // Let database generate ID

      final response = await supabaseClient
          .from('activity_log')
          .insert(data)
          .select()
          .single();

      return ActivityLogModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create activity: $e');
    }
  }

  @override
  Future<ActivityLogModel> updateActivity({
    required String activityId,
    ActivityStatus? status,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status != null) {
        updates['status'] = status.name;
      }

      if (description != null) {
        updates['description'] = description;
      }

      if (metadata != null) {
        updates['metadata'] = metadata;
      }

      final response = await supabaseClient
          .from('activity_log')
          .update(updates)
          .eq('id', activityId)
          .select()
          .single();

      return ActivityLogModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update activity: $e');
    }
  }

  @override
  Future<bool> deleteActivity(String activityId) async {
    try {
      await supabaseClient.from('activity_log').delete().eq('id', activityId);

      return true;
    } catch (e) {
      throw Exception('Failed to delete activity: $e');
    }
  }

  @override
  Future<Map<String, int>> getCategoryStats(String userId) async {
    try {
      final activities = await getUserActivities(
        userId: userId,
        limit: 1000, // Get all for stats
      );

      final Map<String, int> categoryStats = {
        'All': activities.length,
        'Games': 0,
        'Bookings': 0,
        'Teams': 0,
        'Challenges': 0,
        'Payments': 0,
        'Community': 0,
        'Groups': 0,
        'Events': 0,
        'Rewards': 0,
      };

      for (final activity in activities) {
        final category = activity.category;
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      }

      return categoryStats;
    } catch (e) {
      throw Exception('Failed to get category stats: $e');
    }
  }
}
