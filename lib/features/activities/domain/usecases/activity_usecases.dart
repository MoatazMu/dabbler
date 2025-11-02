import 'package:dabbler/core/fp/failure.dart';
import 'package:dabbler/core/fp/result.dart';
import 'package:dabbler/data/models/activities/activity_log.dart';
import '../repositories/activity_log_repository.dart';

/// Use case for getting user activities with filtering
class GetUserActivities {
  final ActivityLogRepository repository;

  GetUserActivities(this.repository);

  Future<Result<List<ActivityLog>, Failure>> call({
    required String userId,
    ActivityType? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) {
    return repository.getUserActivities(
      userId: userId,
      type: type,
      category: category,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );
  }
}

/// Use case for getting activity statistics
class GetActivityStats {
  final ActivityLogRepository repository;

  GetActivityStats(this.repository);

  Future<Result<Map<String, int>, Failure>> call({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return repository.getUserActivityStats(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// Use case for creating activity log
class CreateActivityLog {
  final ActivityLogRepository repository;

  CreateActivityLog(this.repository);

  Future<Result<ActivityLog, Failure>> call({
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
  }) {
    return repository.createActivity(
      userId: userId,
      type: type,
      subType: subType,
      title: title,
      description: description,
      status: status ?? ActivityStatus.completed,
      targetId: targetId,
      targetType: targetType,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserAvatar: targetUserAvatar,
      venue: venue,
      location: location,
      amount: amount,
      currency: currency,
      points: points,
      count: count,
      scheduledDate: scheduledDate,
      metadata: metadata,
      iconUrl: iconUrl,
      thumbnailUrl: thumbnailUrl,
      actionRoute: actionRoute,
    );
  }
}

/// Use case for getting recent activities
class GetRecentActivities {
  final ActivityLogRepository repository;

  GetRecentActivities(this.repository);

  Future<Result<List<ActivityLog>, Failure>> call({
    required String userId,
    int days = 7,
  }) {
    return repository.getRecentActivities(userId: userId, days: days);
  }
}

/// Use case for getting category statistics
class GetCategoryStats {
  final ActivityLogRepository repository;

  GetCategoryStats(this.repository);

  Future<Result<Map<String, int>, Failure>> call(String userId) {
    return repository.getCategoryStats(userId);
  }
}
