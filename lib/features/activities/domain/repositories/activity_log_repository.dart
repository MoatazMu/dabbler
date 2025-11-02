import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/activities/activity_log.dart';

/// Repository interface for activity log operations
abstract class ActivityLogRepository {
  /// Get all activities for a user with optional filtering
  Future<Result<List<ActivityLog>, Failure>> getUserActivities({
    required String userId,
    ActivityType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });

  /// Get activity statistics for a user
  Future<Result<Map<String, int>, Failure>> getUserActivityStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Create a new activity log entry
  Future<Result<ActivityLog, Failure>> createActivity({
    required String userId,
    required ActivityType type,
    String? subType,
    required String title,
    String? description,
    ActivityStatus? status,
    String? targetId,
    String? targetType,
    String? targetUserId,
    String? targetUserName,
    String? targetUserAvatar,
    String? venue,
    String? location,
    double? amount,
    String? currency,
    int? points,
    int? count,
    DateTime? scheduledDate,
    Map<String, dynamic>? metadata,
    String? iconUrl,
    String? thumbnailUrl,
    String? actionRoute,
  });

  /// Update an existing activity log
  Future<Result<ActivityLog, Failure>> updateActivity({
    required String activityId,
    ActivityStatus? status,
    String? description,
    Map<String, dynamic>? metadata,
  });

  /// Delete an activity log entry
  Future<Result<bool, Failure>> deleteActivity(String activityId);

  /// Get activities by date range
  Future<Result<Map<String, List<ActivityLog>>, Failure>>
  getActivitiesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get recent activities (last 7 days)
  Future<Result<List<ActivityLog>, Failure>> getRecentActivities({
    required String userId,
    int days = 7,
  });

  /// Get activity count by category
  Future<Result<Map<String, int>, Failure>> getCategoryStats(String userId);
}
