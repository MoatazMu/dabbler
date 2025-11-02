import 'package:fpdart/fpdart.dart';
import 'package:dabbler/core/fp/failure.dart';
import '../entities/activity_log.dart';

/// Repository interface for activity log operations
abstract class ActivityLogRepository {
  /// Get all activities for a user with optional filtering
  Future<Either<Failure, List<ActivityLog>>> getUserActivities({
    required String userId,
    ActivityType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });

  /// Get activity statistics for a user
  Future<Either<Failure, Map<String, int>>> getUserActivityStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Create a new activity log entry
  Future<Either<Failure, ActivityLog>> createActivity({
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
  Future<Either<Failure, ActivityLog>> updateActivity({
    required String activityId,
    ActivityStatus? status,
    String? description,
    Map<String, dynamic>? metadata,
  });

  /// Delete an activity log entry
  Future<Either<Failure, bool>> deleteActivity(String activityId);

  /// Get activities by date range
  Future<Either<Failure, Map<String, List<ActivityLog>>>>
  getActivitiesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get recent activities (last 7 days)
  Future<Either<Failure, List<ActivityLog>>> getRecentActivities({
    required String userId,
    int days = 7,
  });

  /// Get activity count by category
  Future<Either<Failure, Map<String, int>>> getCategoryStats(String userId);
}
