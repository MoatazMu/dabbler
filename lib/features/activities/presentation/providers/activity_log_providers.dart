import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/activity_log.dart';
import '../../domain/usecases/activity_usecases.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../../data/datasources/activity_log_remote_data_source.dart';
import '../../data/repositories/activity_log_repository_impl.dart';

// Data source provider
final activityLogDataSourceProvider = Provider<ActivityLogRemoteDataSource>((
  ref,
) {
  return ActivityLogRemoteDataSourceImpl(
    supabaseClient: Supabase.instance.client,
  );
});

// Repository provider
final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  return ActivityLogRepositoryImpl(
    remoteDataSource: ref.watch(activityLogDataSourceProvider),
  );
});

// Use cases providers
final getUserActivitiesUseCaseProvider = Provider((ref) {
  return GetUserActivities(ref.watch(activityLogRepositoryProvider));
});

final getActivityStatsUseCaseProvider = Provider((ref) {
  return GetActivityStats(ref.watch(activityLogRepositoryProvider));
});

final createActivityLogUseCaseProvider = Provider((ref) {
  return CreateActivityLog(ref.watch(activityLogRepositoryProvider));
});

final getRecentActivitiesUseCaseProvider = Provider((ref) {
  return GetRecentActivities(ref.watch(activityLogRepositoryProvider));
});

final getCategoryStatsUseCaseProvider = Provider((ref) {
  return GetCategoryStats(ref.watch(activityLogRepositoryProvider));
});

// Activity log state
class ActivityLogState {
  final List<ActivityLog> activities;
  final Map<String, int> categoryStats;
  final bool isLoading;
  final String? error;
  final String selectedCategory;

  const ActivityLogState({
    this.activities = const [],
    this.categoryStats = const {},
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'All',
  });

  ActivityLogState copyWith({
    List<ActivityLog>? activities,
    Map<String, int>? categoryStats,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) {
    return ActivityLogState(
      activities: activities ?? this.activities,
      categoryStats: categoryStats ?? this.categoryStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

// Activity log controller
class ActivityLogController extends StateNotifier<ActivityLogState> {
  final GetUserActivities getUserActivities;
  final GetCategoryStats getCategoryStats;
  final CreateActivityLog createActivityLog;

  ActivityLogController({
    required this.getUserActivities,
    required this.getCategoryStats,
    required this.createActivityLog,
  }) : super(const ActivityLogState());

  /// Load activities for user
  Future<void> loadActivities(String userId, {String? category}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await getUserActivities(
      userId: userId,
      category: category != 'All' ? category : null,
      limit: 100,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (activities) =>
          state = state.copyWith(activities: activities, isLoading: false),
    );
  }

  /// Load category statistics
  Future<void> loadCategoryStats(String userId) async {
    final result = await getCategoryStats(userId);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (stats) => state = state.copyWith(categoryStats: stats),
    );
  }

  /// Filter activities by category
  void filterByCategory(String category, String userId) {
    state = state.copyWith(selectedCategory: category);
    loadActivities(userId, category: category);
  }

  /// Get filtered activities
  List<ActivityLog> get filteredActivities {
    if (state.selectedCategory == 'All') {
      return state.activities;
    }
    return state.activities
        .where((a) => a.category == state.selectedCategory)
        .toList();
  }

  /// Get activities grouped by date
  Map<String, List<ActivityLog>> get groupedActivities {
    final Map<String, List<ActivityLog>> grouped = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'This Month': [],
      'Older': [],
    };

    for (final activity in filteredActivities) {
      grouped[activity.formattedDate]?.add(activity);
    }

    return grouped;
  }

  /// Create activity log entry
  Future<bool> createActivity({
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
  }) async {
    final result = await createActivityLog(
      userId: userId,
      type: type,
      subType: subType,
      title: title,
      description: description,
      status: status,
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

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (activity) {
        // Add to local state
        state = state.copyWith(activities: [activity, ...state.activities]);
        return true;
      },
    );
  }

  /// Refresh activities
  Future<void> refresh(String userId) async {
    await Future.wait([
      loadActivities(userId, category: state.selectedCategory),
      loadCategoryStats(userId),
    ]);
  }
}

// Activity log controller provider
final activityLogControllerProvider =
    StateNotifierProvider.family<
      ActivityLogController,
      ActivityLogState,
      String
    >((ref, userId) {
      final controller = ActivityLogController(
        getUserActivities: ref.watch(getUserActivitiesUseCaseProvider),
        getCategoryStats: ref.watch(getCategoryStatsUseCaseProvider),
        createActivityLog: ref.watch(createActivityLogUseCaseProvider),
      );

      // Load data on initialization
      controller.loadActivities(userId);
      controller.loadCategoryStats(userId);

      return controller;
    });

// Category stats provider
final categoryStatsProvider = Provider.family<Map<String, int>, String>((
  ref,
  userId,
) {
  final state = ref.watch(activityLogControllerProvider(userId));
  return state.categoryStats;
});
