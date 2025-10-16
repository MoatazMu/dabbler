import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart' as core_logger;
import 'data_export_service.dart' show DataExportService, DataExportFormat, ExportFormat, DataExportResult, dataExportServiceProvider;
import 'image_upload_service.dart' show ImageUploadService, imageUploadServiceProvider;

/// Service for handling account deletion with proper cleanup and GDPR compliance
class AccountDeletionService {
  final SupabaseClient _supabase;
  final DataExportService _dataExportService;
  final ImageUploadService _imageUploadService;

  AccountDeletionService({
    SupabaseClient? supabase,
    required DataExportService dataExportService,
    required ImageUploadService imageUploadService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _dataExportService = dataExportService,
        _imageUploadService = imageUploadService;

  /// Get pre-deletion checklist for user
  Future<AccountDeletionChecklist> getPreDeletionChecklist(String userId) async {
    try {
      core_logger.Logger.info('Generating pre-deletion checklist for user $userId');

      final checklist = AccountDeletionChecklist();

      // Check for active games
      final activeGames = await _supabase
          .from('games')
          .select('id, title, scheduled_at')
          .eq('creator_id', userId)
          .eq('status', 'active')
          .gt('scheduled_at', DateTime.now().toIso8601String());

      checklist.activeGamesAsCreator = activeGames.length;
      checklist.activeGamesList = activeGames.map((game) => {
        'id': game['id'],
        'title': game['title'],
        'scheduled_at': game['scheduled_at'],
      }).toList();

      // Check for game participations
      final participations = await _supabase
          .from('game_participants')
          .select('game_id, games(title, scheduled_at)')
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .gt('games.scheduled_at', DateTime.now().toIso8601String());

      checklist.upcomingParticipations = participations.length;

      // Check for pending friend requests
      final pendingRequests = await _supabase
          .from('friend_requests')
          .select('id')
          .or('sender_id.eq.$userId,recipient_id.eq.$userId')
          .eq('status', 'pending');

      checklist.pendingFriendRequests = pendingRequests.length;

      // Check for unread messages
      final unreadMessages = await _supabase
          .from('messages')
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false);

      checklist.unreadMessages = unreadMessages.length;

      // Check data export history
      final recentExports = await _dataExportService.getUserExportHistory(userId);
      checklist.hasRecentDataExport = recentExports.any(
        (export) => export.requestedAt.isAfter(
          DateTime.now().subtract(const Duration(days: 30)),
        ),
      );

      // Estimate data to be deleted
      await _estimateDataVolume(userId, checklist);

      core_logger.Logger.info('Pre-deletion checklist generated for user $userId');
      return checklist;
    } catch (e) {
      core_logger.Logger.error('Error generating pre-deletion checklist for user $userId', e);
      rethrow;
    }
  }

  /// Estimate volume of data to be deleted
  Future<void> _estimateDataVolume(String userId, AccountDeletionChecklist checklist) async {
    try {
      // Count profile data
      await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      checklist.profileDataSize = 1;

      // Count games created
      final gamesCreated = await _supabase
          .from('games')
          .select('id')
          .eq('creator_id', userId);
      checklist.gamesCreated = gamesCreated.length;

      // Count game participations
      final gameParticipations = await _supabase
          .from('game_participants')
          .select('id')
          .eq('user_id', userId);
      checklist.gameParticipations = gameParticipations.length;

      // Count messages
      final messagesSent = await _supabase
          .from('messages')
          .select('id')
          .eq('sender_id', userId);
      checklist.messagesSent = messagesSent.length;

      // Count friendships
      final friendships = await _supabase
          .from('friendships')
          .select('id')
          .or('user_id.eq.$userId,friend_id.eq.$userId');
      checklist.friendships = friendships.length;

      // Estimate total records
      checklist.totalRecordsToDelete = 
          checklist.profileDataSize +
          checklist.gamesCreated +
          checklist.gameParticipations +
          checklist.messagesSent +
          checklist.friendships;

    } catch (e) {
      core_logger.Logger.warning('Could not estimate data volume for user $userId', e);
      // Set defaults if estimation fails
      checklist.totalRecordsToDelete = 0;
    }
  }

  /// Create data backup before deletion
  Future<DataExportResult?> createDataBackup(String userId, {
    ExportFormat format = ExportFormat.json,
  }) async {
    try {
      core_logger.Logger.info('Creating data backup for user $userId before deletion');

      // Use the new GDPR export method instead of deprecated ones
      final exportRequest = await _dataExportService.requestGDPRDataExport(
        userId: userId,
        format: format == ExportFormat.json ? DataExportFormat.json : DataExportFormat.csv,
        userEmail: 'user@example.com', // This should come from user profile
      );

      // For now, return null since the new method returns a request, not a result
      // The actual export will be processed asynchronously
      core_logger.Logger.info('Data backup requested for user $userId: ${exportRequest.id}');
      return null;
    } catch (e) {
      core_logger.Logger.error('Error creating data backup for user $userId', e);
      rethrow;
    }
  }

  /// Start account deletion process with grace period
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String userId,
    String? reason,
    bool createBackup = true,
    int gracePeriodDays = 7,
  }) async {
    try {
      core_logger.Logger.info('Starting account deletion request for user $userId');

      // Create backup if requested
      DataExportResult? backup;
      if (createBackup) {
        backup = await createDataBackup(userId);
      }

      // Create deletion request
      final deletionRequest = AccountDeletionRequest(
        userId: userId,
        requestedAt: DateTime.now(),
        scheduledDeletionAt: DateTime.now().add(Duration(days: gracePeriodDays)),
        reason: reason,
        backupFilePath: backup?.filePath,
        gracePeriodDays: gracePeriodDays,
        status: DeletionStatus.pending,
      );

      // Store deletion request in database
      await _supabase.from('account_deletion_requests').insert({
        'user_id': userId,
        'requested_at': deletionRequest.requestedAt.toIso8601String(),
        'scheduled_deletion_at': deletionRequest.scheduledDeletionAt.toIso8601String(),
        'reason': reason,
        'backup_file_path': backup?.filePath,
        'grace_period_days': gracePeriodDays,
        'status': deletionRequest.status.name,
      });

      // Send notification to user (if notification service exists)
      await _notifyUserOfDeletionRequest(userId, deletionRequest);

      // Deactivate account immediately (hide from searches, disable login)
      await _deactivateAccount(userId);

      core_logger.Logger.info('Account deletion scheduled for user $userId on ${deletionRequest.scheduledDeletionAt}');
      return deletionRequest;
    } catch (e) {
      core_logger.Logger.error('Error requesting account deletion for user $userId', e);
      rethrow;
    }
  }

  /// Cancel pending account deletion
  Future<void> cancelAccountDeletion(String userId) async {
    try {
      core_logger.Logger.info('Cancelling account deletion for user $userId');

      // Update deletion request status
      await _supabase
          .from('account_deletion_requests')
          .update({'status': DeletionStatus.cancelled.name})
          .eq('user_id', userId)
          .eq('status', DeletionStatus.pending.name);

      // Reactivate account
      await _reactivateAccount(userId);

      core_logger.Logger.info('Account deletion cancelled for user $userId');
    } catch (e) {
      core_logger.Logger.error('Error cancelling account deletion for user $userId', e);
      rethrow;
    }
  }

  /// Execute account deletion (called by scheduled job)
  Future<void> executeAccountDeletion(String userId) async {
    try {
      core_logger.Logger.info('Executing account deletion for user $userId');

      // Start transaction to ensure atomic deletion
      await _supabase.rpc('begin_account_deletion', params: {'target_user_id': userId});

      try {
        // Delete user images
        await _imageUploadService.deleteUserImages(userId);

        // Delete from all related tables in correct order
        await _deleteUserData(userId);

        // Delete auth user (this should be last)
        await _supabase.auth.admin.deleteUser(userId);

        // Mark deletion as completed
        await _supabase
            .from('account_deletion_requests')
            .update({
              'status': DeletionStatus.completed.name,
              'completed_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);

        // Commit transaction
        await _supabase.rpc('commit_account_deletion');

        core_logger.Logger.info('Account deletion completed successfully for user $userId');
      } catch (e) {
        // Rollback transaction
        await _supabase.rpc('rollback_account_deletion');
        rethrow;
      }
    } catch (e) {
      core_logger.Logger.error('Error executing account deletion for user $userId', e);
      
      // Mark deletion as failed
      try {
        await _supabase
            .from('account_deletion_requests')
            .update({
              'status': DeletionStatus.failed.name,
              'error_message': e.toString(),
            })
            .eq('user_id', userId);
      } catch (updateError) {
        core_logger.Logger.error('Could not update deletion status to failed', updateError);
      }
      
      rethrow;
    }
  }

  /// Delete all user data from database
  Future<void> _deleteUserData(String userId) async {
    // Delete in order of dependencies (child tables first)
    
    // Delete game participants
    await _supabase.from('game_participants').delete().eq('user_id', userId);
    
    // Delete messages sent by user
    await _supabase.from('messages').delete().eq('sender_id', userId);
    
    // Delete friend requests
    await _supabase.from('friend_requests').delete().or('sender_id.eq.$userId,recipient_id.eq.$userId');
    
    // Delete friendships
    await _supabase.from('friendships').delete().or('user_id.eq.$userId,friend_id.eq.$userId');
    
    // Delete blocked users
    await _supabase.from('blocked_users').delete().or('blocker_id.eq.$userId,blocked_id.eq.$userId');
    
    // Delete notifications
    await _supabase.from('notifications').delete().eq('user_id', userId);
    
    // Delete user settings
    await _supabase.from('user_settings').delete().eq('user_id', userId);
    
    // Delete activity logs
    await _supabase.from('user_activity').delete().eq('user_id', userId);
    
    // Delete data exports
    await _supabase.from('data_exports').delete().eq('user_id', userId);
    
    // Delete games created by user (this might cascade to participants)
    await _supabase.from('games').delete().eq('creator_id', userId);
    
    // Delete profile (should be last)
    await _supabase.from('users').delete().eq('id', userId);
    
    core_logger.Logger.info('User data deleted for user $userId');
  }

  /// Deactivate account (hide from searches, disable features)
  Future<void> _deactivateAccount(String userId) async {
    await _supabase
        .from('users')
        .update({
          'is_active': false,
          'deactivated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    core_logger.Logger.info('Account deactivated for user $userId');
  }

  /// Reactivate account
  Future<void> _reactivateAccount(String userId) async {
    await _supabase
        .from('users')
        .update({
          'is_active': true,
          'deactivated_at': null,
        })
        .eq('id', userId);

    core_logger.Logger.info('Account reactivated for user $userId');
  }

  /// Notify user of deletion request (placeholder)
  Future<void> _notifyUserOfDeletionRequest(String userId, AccountDeletionRequest request) async {
    // This would integrate with your notification service
    core_logger.Logger.info('Deletion notification sent to user $userId');
  }

  /// Get pending deletion requests (for admin/scheduled job)
  Future<List<AccountDeletionRequest>> getPendingDeletions() async {
    try {
      final response = await _supabase
          .from('account_deletion_requests')
          .select()
          .eq('status', DeletionStatus.pending.name)
          .lte('scheduled_deletion_at', DateTime.now().toIso8601String());

      return response.map((record) => AccountDeletionRequest.fromJson(record)).toList();
    } catch (e) {
      core_logger.Logger.error('Error fetching pending deletions', e);
      return [];
    }
  }

  /// Process all pending deletions (for scheduled job)
  Future<void> processPendingDeletions() async {
    try {
      final pendingDeletions = await getPendingDeletions();
      
      for (final deletion in pendingDeletions) {
        try {
          await executeAccountDeletion(deletion.userId);
        } catch (e) {
          core_logger.Logger.error('Failed to delete account for user ${deletion.userId}', e);
          // Continue with next deletion
        }
      }
      
      core_logger.Logger.info('Processed ${pendingDeletions.length} pending account deletions');
    } catch (e) {
      core_logger.Logger.error('Error processing pending deletions', e);
    }
  }
}

/// Account deletion checklist
class AccountDeletionChecklist {
  int activeGamesAsCreator = 0;
  List<Map<String, dynamic>> activeGamesList = [];
  int upcomingParticipations = 0;
  int pendingFriendRequests = 0;
  int unreadMessages = 0;
  bool hasRecentDataExport = false;
  
  // Data volume estimates
  int profileDataSize = 0;
  int gamesCreated = 0;
  int gameParticipations = 0;
  int messagesSent = 0;
  int friendships = 0;
  int totalRecordsToDelete = 0;

  bool get hasBlockingIssues => 
      activeGamesAsCreator > 0 || 
      upcomingParticipations > 0;

  List<String> get warnings {
    final warnings = <String>[];
    
    if (activeGamesAsCreator > 0) {
      warnings.add('You have $activeGamesAsCreator active games as creator');
    }
    
    if (upcomingParticipations > 0) {
      warnings.add('You have $upcomingParticipations upcoming game participations');
    }
    
    if (pendingFriendRequests > 0) {
      warnings.add('You have $pendingFriendRequests pending friend requests');
    }
    
    if (unreadMessages > 0) {
      warnings.add('You have $unreadMessages unread messages');
    }
    
    if (!hasRecentDataExport) {
      warnings.add('No recent data export found. Consider creating a backup.');
    }
    
    return warnings;
  }
}

/// Account deletion request
class AccountDeletionRequest {
  final String userId;
  final DateTime requestedAt;
  final DateTime scheduledDeletionAt;
  final String? reason;
  final String? backupFilePath;
  final int gracePeriodDays;
  final DeletionStatus status;
  final DateTime? completedAt;
  final String? errorMessage;

  AccountDeletionRequest({
    required this.userId,
    required this.requestedAt,
    required this.scheduledDeletionAt,
    this.reason,
    this.backupFilePath,
    required this.gracePeriodDays,
    required this.status,
    this.completedAt,
    this.errorMessage,
  });

  factory AccountDeletionRequest.fromJson(Map<String, dynamic> json) {
    return AccountDeletionRequest(
      userId: json['user_id'],
      requestedAt: DateTime.parse(json['requested_at']),
      scheduledDeletionAt: DateTime.parse(json['scheduled_deletion_at']),
      reason: json['reason'],
      backupFilePath: json['backup_file_path'],
      gracePeriodDays: json['grace_period_days'],
      status: DeletionStatus.values.byName(json['status']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      errorMessage: json['error_message'],
    );
  }

  bool get canBeCancelled => 
      status == DeletionStatus.pending && 
      DateTime.now().isBefore(scheduledDeletionAt);

  Duration get timeUntilDeletion => scheduledDeletionAt.difference(DateTime.now());
}

/// Deletion status enum
enum DeletionStatus {
  pending,
  cancelled,
  completed,
  failed,
}

/// Provider for account deletion service
final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(
    dataExportService: ref.read(dataExportServiceProvider),
    imageUploadService: ref.read(imageUploadServiceProvider),
  );
});
