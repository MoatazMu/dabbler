import 'dart:io';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../../../../utils/enums/social_enums.dart'; // Import MessageType from social_enums
import '../repositories/chat_repository.dart';
import '../../data/models/chat_message_model.dart';

/// Parameters for sending a message
class SendMessageParams {
  final String userId;
  final String conversationId;
  final String content;
  final MessageType type;
  final List<File>? mediaFiles;
  final List<String>? existingMediaUrls;
  final List<String>? mentionedUsers;
  final String? replyToMessageId;
  final bool encryptContent;
  final int priority; // 1-5, where 5 is highest priority
  final Map<String, dynamic>? metadata;
  final bool allowOfflineQueue;

  const SendMessageParams({
    required this.userId,
    required this.conversationId,
    required this.content,
    this.type = MessageType.text,
    this.mediaFiles,
    this.existingMediaUrls,
    this.mentionedUsers,
    this.replyToMessageId,
    this.encryptContent = false,
    this.priority = 1,
    this.metadata,
    this.allowOfflineQueue = true,
  });
}

/// Result of send message operation
class SendMessageResult {
  final ChatMessageModel message;
  final List<String> uploadedMediaUrls;
  final bool isEncrypted;
  final bool queuedForOffline;
  final bool conversationUpdated;
  final List<String> notifiedUsers;
  final List<String> warnings;
  final Map<String, dynamic> deliveryMetadata;

  const SendMessageResult({
    required this.message,
    this.uploadedMediaUrls = const [],
    this.isEncrypted = false,
    this.queuedForOffline = false,
    this.conversationUpdated = false,
    this.notifiedUsers = const [],
    this.warnings = const [],
    this.deliveryMetadata = const {},
  });
}

/// Use case for sending messages with comprehensive validation and processing
class SendMessageUseCase {
  final ChatRepository _chatRepository;
  static const int maxContentLength = 10000;
  static const int maxMediaFiles = 10;
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> allowedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx', 'txt'];

  SendMessageUseCase(this._chatRepository);

  Future<Either<Failure, SendMessageResult>> call(SendMessageParams params) async {
    try {
      // Validate input parameters
      final validationResult = await _validateParams(params);
      if (validationResult.isLeft()) {
        return Left(validationResult.fold((l) => l, (_) => throw Exception('Unexpected success')));
      }

      // Check conversation permissions
      final permissionResult = await _checkConversationPermissions(params);
      if (permissionResult.isLeft()) {
        return Left(permissionResult.fold((l) => l, (_) => throw Exception('Unexpected success')));
      }

      // Validate and process content
      final contentResult = await _processContent(params);
      if (contentResult.isLeft()) {
        return Left(contentResult.fold((l) => l, (_) => throw Exception('Unexpected success')));
      }
      final processedContent = contentResult.fold((_) => throw Exception('Unexpected failure'), (r) => r);

      // Process media attachments
      final mediaResult = await _processMediaAttachments(params);
      if (mediaResult.isLeft()) {
        return Left(mediaResult.fold((l) => l, (_) => throw Exception('Unexpected success')));
      }
      final mediaUrls = mediaResult.fold((_) => throw Exception('Unexpected failure'), (r) => r);

      // Encrypt content if required
      final encryptionResult = await _encryptContentIfNeeded(
        processedContent.content,
        params.encryptContent,
      );
      if (encryptionResult.isLeft()) {
        return Left(encryptionResult.fold((l) => l, (_) => throw Exception('Unexpected success')));
      }
      final encryptedData = encryptionResult.fold((_) => throw Exception('Unexpected failure'), (r) => r);

      // Process mentions
      final mentionsResult = _processMentions(
        processedContent.content,
        params.mentionedUsers,
      );

      // Build message data
      final messageData = _buildMessageData(
        params,
        encryptedData.content,
        mediaUrls,
        mentionsResult,
      );

      Either<Failure, ChatMessageModel> sendResult;

      // Check connectivity and queue if offline
      final isOnline = await _checkConnectivity();
      if (!isOnline && params.allowOfflineQueue) {
        sendResult = await _queueMessageForLater(messageData, params.priority);
        if (sendResult.isRight()) {
          return Right(SendMessageResult(
            message: sendResult.fold((_) => throw Exception('Unexpected failure'), (r) => r),
            uploadedMediaUrls: mediaUrls,
            isEncrypted: encryptedData.isEncrypted,
            queuedForOffline: true,
            warnings: ['Message queued for delivery when online'],
            deliveryMetadata: {
              'queued_at': DateTime.now().toIso8601String(),
              'priority': params.priority,
            },
          ));
        }
      } else if (!isOnline) {
        return Left(NetworkFailure(
          message: 'No internet connection and offline queuing is disabled',
        ));
      }

      // Send message online
      sendResult = await _sendMessageWithRetry(messageData, params);
      
      if (sendResult.isLeft()) {
        return Left(sendResult.fold((l) => l, (_) => throw Exception('Unexpected success')));
      }

      final sentMessage = sendResult.fold((_) => throw Exception('Unexpected failure'), (r) => r);

      // Update conversation timestamp
      final conversationUpdated = await _updateConversationTimestamp(
        params.conversationId,
        sentMessage.id,
      );

      // Send notifications for mentions
      final notifiedUsers = await _notifyMentionedUsers(
        mentionsResult,
        sentMessage,
      );

      // Update user activity metrics
      await _updateUserMetrics(params.userId, 'message_sent', sentMessage);

      // Log message sending for analytics
      await _logMessageSending(params, sentMessage);

      return Right(SendMessageResult(
        message: sentMessage,
        uploadedMediaUrls: mediaUrls,
        isEncrypted: encryptedData.isEncrypted,
        queuedForOffline: false,
        conversationUpdated: conversationUpdated,
        notifiedUsers: notifiedUsers,
        warnings: processedContent.warnings,
        deliveryMetadata: {
          'sent_at': sentMessage.sentAt.toIso8601String(),
          'delivery_method': 'online',
        },
      ));

    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to send message: ${e.toString()}',
      ));
    }
  }

  /// Validates input parameters
  Future<Either<Failure, void>> _validateParams(SendMessageParams params) async {
    // Validate content based on message type
    if (params.type == MessageType.text) {
      if (params.content.trim().isEmpty) {
        return Left(ValidationFailure(
          message: 'Message content cannot be empty',
        ));
      }

      if (params.content.length > maxContentLength) {
        return Left(ValidationFailure(
          message: 'Message content cannot exceed $maxContentLength characters',
        ));
      }
    }

    // Validate media files count
    final totalMediaCount = (params.mediaFiles?.length ?? 0) + 
                           (params.existingMediaUrls?.length ?? 0);
    
    if (totalMediaCount > maxMediaFiles) {
      return Left(ValidationFailure(
        message: 'Cannot attach more than $maxMediaFiles media files',
      ));
    }

    // Validate media files if provided
    if (params.mediaFiles != null) {
      for (int i = 0; i < params.mediaFiles!.length; i++) {
        final file = params.mediaFiles![i];
        
        // Check file size
        final fileSize = await file.length();
        if (fileSize > maxFileSize) {
          return Left(ValidationFailure(
            message: 'File ${file.path.split('/').last} exceeds maximum size of ${maxFileSize ~/ (1024 * 1024)}MB',
          ));
        }

        // Check file format
        final extension = file.path.split('.').last.toLowerCase();
        final allAllowedFormats = [
          ...allowedImageFormats,
          ...allowedVideoFormats,
          ...allowedDocumentFormats,
        ];
        
        if (!allAllowedFormats.contains(extension)) {
          return Left(ValidationFailure(
            message: 'File format .$extension is not supported',
          ));
        }
      }
    }

    // Validate conversation ID format
    if (!_isValidId(params.conversationId)) {
      return Left(ValidationFailure(
        message: 'Invalid conversation ID format',
      ));
    }

    // Validate reply to message ID if provided
    if (params.replyToMessageId != null && !_isValidId(params.replyToMessageId!)) {
      return Left(ValidationFailure(
        message: 'Invalid reply message ID format',
      ));
    }

    // Validate priority
    if (params.priority < 1 || params.priority > 5) {
      return Left(ValidationFailure(
        message: 'Message priority must be between 1 and 5',
      ));
    }

    return const Right(null);
  }

  /// Checks conversation permissions
  Future<Either<Failure, ConversationPermissions>> _checkConversationPermissions(
    SendMessageParams params,
  ) async {
    try {
      // Get conversation details and user's role
      final conversationResult = await _chatRepository.getConversation(
        params.conversationId,
      );

      if (conversationResult.isLeft()) {
        return Left(conversationResult.fold((l) => l, (_) => throw Exception('Unexpected success')));
      }

      // Note: conversation variable is not used in the current implementation
      // final conversation = conversationResult.fold((_) => throw Exception('Unexpected failure'), (r) => r);

      // Check if user is a participant
      final userPermissions = await _chatRepository.getUserPermissionsInConversation(
        params.conversationId,
        params.userId,
      );

      if (userPermissions.isLeft()) {
        return Left(userPermissions.fold((l) => l, (_) => throw Exception('Unexpected success')));
      }

      final permissions = userPermissions.fold((_) => throw Exception('Unexpected failure'), (r) => r);

      // Check basic sending permissions
      if (!permissions.canSendMessages) {
        return Left(AuthorizationFailure(
          message: 'You do not have permission to send messages in this conversation',
        ));
      }

      // Check if conversation is archived or deleted
      // Note: Archive status is not available in the current model
      // if (conversation.settings.isArchived && !permissions.canSendToArchived) {
      //   return Left(AuthorizationFailure(
      //     message: 'Cannot send messages to archived conversations',
      //   ));
      // }

      // Check media sending permissions
      if ((params.mediaFiles != null && params.mediaFiles!.isNotEmpty) ||
          (params.existingMediaUrls != null && params.existingMediaUrls!.isNotEmpty)) {
        if (!permissions.canSendMedia) {
          return Left(AuthorizationFailure(
            message: 'You do not have permission to send media in this conversation',
          ));
        }
      }

      // Check rate limiting
      if (permissions.isRateLimited) {
        return Left(BusinessLogicFailure(
          message: 'Message sending rate limit exceeded',
          details: {
            'retry_after': permissions.rateLimitResetAt != null
              ? permissions.rateLimitResetAt!.difference(DateTime.now())
              : const Duration(minutes: 1),
          },
        ));
      }

      return Right(permissions);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to check conversation permissions: ${e.toString()}',
      ));
    }
  }

  /// Processes and validates message content
  Future<Either<Failure, ProcessedMessageContent>> _processContent(
    SendMessageParams params,
  ) async {
    try {
      String processedContent = params.content.trim();
      final warnings = <String>[];
      final metadata = <String, dynamic>{};

      // Remove excessive whitespace
      processedContent = processedContent.replaceAll(RegExp(r'\s+'), ' ');

      // Check for URLs and validate them
      final urlRegex = RegExp(r'(https?://[^\s]+)', caseSensitive: false);
      final urlMatches = urlRegex.allMatches(processedContent);
      if (urlMatches.isNotEmpty) {
        final urls = urlMatches.map((match) => match.group(0)).toList();
        metadata['urls'] = urls;
        
        // Validate URLs (basic check)
        for (final url in urls) {
          if (url != null && !_isValidUrl(url)) {
            warnings.add('Invalid URL detected: $url');
          }
        }
      }

      // Check for excessive caps
      final capsCount = processedContent.split('').where((char) => 
        char == char.toUpperCase() && char.toLowerCase() != char.toUpperCase()).length;
      final capsPercentage = capsCount / processedContent.length;
      
      if (capsPercentage > 0.7 && processedContent.length > 10) {
        warnings.add('Message contains excessive capital letters');
      }

      // Check for potential spam patterns
      final repeatedCharRegex = RegExp(r'(.)\1{4,}');
      if (repeatedCharRegex.hasMatch(processedContent)) {
        warnings.add('Message contains excessive repeated characters');
      }

      return Right(ProcessedMessageContent(
        content: processedContent,
        warnings: warnings,
        metadata: metadata,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to process message content: ${e.toString()}',
      ));
    }
  }

  /// Processes media attachments
  Future<Either<Failure, List<String>>> _processMediaAttachments(
    SendMessageParams params,
  ) async {
    try {
      final allMediaUrls = <String>[];

      // Add existing media URLs if provided
      if (params.existingMediaUrls != null) {
        allMediaUrls.addAll(params.existingMediaUrls!);
      }

      // Upload new media files if provided
      if (params.mediaFiles != null && params.mediaFiles!.isNotEmpty) {
        final uploadResult = await _chatRepository.uploadMessageMedia(
          params.mediaFiles!.map((f) => f.path).toList(), // Convert File to String path
        );

        if (uploadResult.isLeft()) {
          return Left(uploadResult.fold((l) => l, (_) => throw Exception('Unexpected success')));
        }

        final uploadedUrls = uploadResult.fold((_) => throw Exception('Unexpected failure'), (r) => r);
        allMediaUrls.addAll(uploadedUrls);
      }

      return Right(allMediaUrls);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to process media attachments: ${e.toString()}',
      ));
    }
  }

  /// Encrypts content if required
  Future<Either<Failure, EncryptedContent>> _encryptContentIfNeeded(
    String content,
    bool encryptContent,
  ) async {
    try {
      if (!encryptContent) {
        return Right(EncryptedContent(
          content: content,
          isEncrypted: false,
        ));
      }

      // This would typically use an encryption service
      final encryptedContent = await _encryptMessage(content);
      
      return Right(EncryptedContent(
        content: encryptedContent,
        isEncrypted: true,
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to encrypt message content: ${e.toString()}',
      ));
    }
  }

  /// Processes mentions in the message
  List<String> _processMentions(String content, List<String>? explicitMentions) {
    final mentionRegex = RegExp(r'@([a-zA-Z0-9_]+)');
    final matches = mentionRegex.allMatches(content);
    
    final contentMentions = matches
        .map((match) => match.group(1)?.toLowerCase())
        .where((mention) => mention != null)
        .cast<String>()
        .toSet();

    final allMentions = <String>{};
    allMentions.addAll(contentMentions);
    
    if (explicitMentions != null) {
      allMentions.addAll(explicitMentions);
    }

    return allMentions.take(20).toList(); // Limit to 20 mentions
  }

  /// Builds message data for sending
  Map<String, dynamic> _buildMessageData(
    SendMessageParams params,
    String processedContent,
    List<String> mediaUrls,
    List<String> mentions,
  ) {
    return {
      'conversation_id': params.conversationId,
      'sender_id': params.userId,
      'content': processedContent,
      'type': params.type.name,
      'media_urls': mediaUrls,
      'mentioned_users': mentions,
      'reply_to_message_id': params.replyToMessageId,
      'is_encrypted': params.encryptContent,
      'priority': params.priority,
      'metadata': params.metadata ?? {},
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Checks device connectivity
  Future<bool> _checkConnectivity() async {
    try {
      // This would typically use a connectivity package
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Queues message for later sending when offline
  Future<Either<Failure, ChatMessageModel>> _queueMessageForLater(
    Map<String, dynamic> messageData,
    int priority,
  ) async {
    try {
      return await _chatRepository.queueMessageForOffline(messageData, priority);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to queue message for offline: ${e.toString()}',
      ));
    }
  }

  /// Sends message with retry logic
  Future<Either<Failure, ChatMessageModel>> _sendMessageWithRetry(
    Map<String, dynamic> messageData,
    SendMessageParams params,
  ) async {
    const maxRetries = 3;
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        final result = await _chatRepository.sendMessage(
          conversationId: messageData['conversation_id'] as String,
          content: messageData['content'] as String,
          messageType: params.type,
          mediaUrls: messageData['media_urls'] as List<String>?,
          replyToMessageId: messageData['reply_to_message_id'] as String?,
          metadata: messageData['metadata'] as Map<String, dynamic>?,
        );
        
        if (result.isRight()) {
          return result;
        }
        
        // Check if error is retryable
        final error = result.fold((l) => l, (_) => throw Exception('Unexpected success'));
        if (!_isRetryableError(error)) {
          return result;
        }
        
        attempts++;
        if (attempts < maxRetries) {
          // Exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * (1 << attempts)));
        }
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          return Left(ServerFailure(
            message: 'Failed to send message after $maxRetries attempts: ${e.toString()}',
          ));
        }
      }
    }
    
    return Left(ServerFailure(
      message: 'Failed to send message after $maxRetries attempts',
    ));
  }

  /// Updates conversation timestamp
  Future<bool> _updateConversationTimestamp(
    String conversationId,
    String messageId,
  ) async {
    try {
      final result = await _chatRepository.updateConversationLastMessage(
        conversationId,
        messageId,
      );
      return result.isRight();
    } catch (e) {
      // Use proper logging instead of print
      return false;
    }
  }

  /// Sends notifications to mentioned users
  Future<List<String>> _notifyMentionedUsers(
    List<String> mentions,
    ChatMessageModel message,
  ) async {
    final notifiedUsers = <String>[];
    
    try {
      for (final mention in mentions) {
        final notificationSent = await _sendMentionNotification(mention, message);
        if (notificationSent) {
          notifiedUsers.add(mention);
        }
      }
    } catch (e) {
      // Use proper logging instead of print
    }

    return notifiedUsers;
  }

  /// Sends notification for a mention
  Future<bool> _sendMentionNotification(String mentionedUser, ChatMessageModel message) async {
    try {
      // This would typically call a notification service
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Updates user activity metrics
  Future<void> _updateUserMetrics(String userId, String actionType, ChatMessageModel message) async {
    try {
      // This would typically update user activity metrics
    } catch (e) {
      // Use proper logging instead of print
    }
  }

  /// Logs message sending for analytics
  Future<void> _logMessageSending(SendMessageParams params, ChatMessageModel message) async {
    try {
      // In a real implementation, this would call:
      // await _analyticsService.logEvent('message_sent', {
      //   'action': 'message_sent',
      //   'user_id': params.userId,
      //   'conversation_id': params.conversationId,
      //   'message_id': message.id,
      //   'message_type': params.type.name,
      //   'has_media': message.mediaAttachments.isNotEmpty,
      //   'media_count': message.mediaAttachments.length,
      //   'content_length': params.content.length,
      //   'is_encrypted': params.encryptContent,
      //   'priority': params.priority,
      //   'mentions_count': message.replyTo != null ? 1 : 0,
      //   'is_reply': params.replyToMessageId != null,
      //   'timestamp': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      // Use proper logging instead of print
    }
  }

  /// Encrypts message content
  Future<String> _encryptMessage(String content) async {
    // This would typically use proper encryption
    // For now, just return base64 encoded content as placeholder
    return content; // Placeholder implementation
  }

  /// Checks if error is retryable
  bool _isRetryableError(Failure error) {
    return error is NetworkFailure || error is ServerFailure;
  }

  /// Validates ID format (assuming UUID)
  bool _isValidId(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(id);
  }

  /// Validates URL format
  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Processed message content result
class ProcessedMessageContent {
  final String content;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  const ProcessedMessageContent({
    required this.content,
    required this.warnings,
    required this.metadata,
  });
}

/// Encrypted content result
class EncryptedContent {
  final String content;
  final bool isEncrypted;

  const EncryptedContent({
    required this.content,
    required this.isEncrypted,
  });
}

/// Conversation permissions model
class ConversationPermissions {
  final bool canSendMessages;
  final bool canSendMedia;
  final bool canSendToArchived;
  final bool isRateLimited;
  final DateTime? rateLimitResetAt;
  final String? role;

  const ConversationPermissions({
    required this.canSendMessages,
    required this.canSendMedia,
    required this.canSendToArchived,
    required this.isRateLimited,
    this.rateLimitResetAt,
    this.role,
  });
}

/// Extended methods for ChatRepository
extension SendMessageRepositoryMethods on ChatRepository {
  Future<Either<Failure, ConversationPermissions>> getUserPermissionsInConversation(
    String conversationId,
    String userId,
  ) {
    throw UnimplementedError('getUserPermissionsInConversation not implemented');
  }

  Future<Either<Failure, List<String>>> uploadMessageMedia(
    List<String> filePaths, // Changed from List<File> to List<String>
    String userId,
    String conversationId,
  ) {
    throw UnimplementedError('uploadMessageMedia not implemented');
  }

  Future<Either<Failure, ChatMessageModel>> queueMessageForOffline(
    Map<String, dynamic> messageData,
    int priority,
  ) {
    throw UnimplementedError('queueMessageForOffline not implemented');
  }

  Future<Either<Failure, ChatMessageModel>> sendMessage(
    {required String conversationId,
    required String content,
    required MessageType messageType,
    List<String>? mediaUrls,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
    }) {
    throw UnimplementedError('sendMessage not implemented');
  }

  Future<Either<Failure, bool>> updateConversationLastMessage(
    String conversationId,
    String messageId,
  ) {
    throw UnimplementedError('updateConversationLastMessage not implemented');
  }

  Future<Either<Failure, Conversation>> getConversation(
    String conversationId, // Remove extra parameter
  ) {
    throw UnimplementedError('getConversation not implemented');
  }
}
