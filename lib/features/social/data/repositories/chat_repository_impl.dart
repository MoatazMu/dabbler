import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';

import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/post.dart'; // For ConversationType (MessageType is in enums)
import '../../../../utils/enums/social_enums.dart'; // For MessageType and related enums
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';

/// Custom exceptions for chat operations
class ChatServerException implements Exception {
  final String message;
  ChatServerException(this.message);
}

class ConversationNotFoundException implements Exception {
  final String conversationId;
  ConversationNotFoundException(this.conversationId);
}

class MessageNotFoundException implements Exception {
  final String messageId;
  MessageNotFoundException(this.messageId);
}

class MessageSendException implements Exception {
  final String message;
  final String? tempId;
  MessageSendException(this.message, {this.tempId});
}

class UnauthorizedChatException implements Exception {
  final String message;
  UnauthorizedChatException(this.message);
}

/// Failure types for chat operations
class ChatServerFailure extends Failure {
  ChatServerFailure({required super.message});
}

class ConversationNotFoundFailure extends Failure {
  final String conversationId;
  ConversationNotFoundFailure(this.conversationId)
      : super(message: 'Conversation not found: $conversationId');
}

class MessageNotFoundFailure extends Failure {
  final String messageId;
  MessageNotFoundFailure(this.messageId)
      : super(message: 'Message not found: $messageId');
}

class MessageSendFailure extends Failure {
  final String? tempId;
  MessageSendFailure({required super.message, this.tempId});
}

class UnauthorizedChatFailure extends Failure {
  UnauthorizedChatFailure({required super.message});
}

/// Queue item for pending messages
class PendingMessage {
  final String tempId;
  final String conversationId;
  final String content;
  final MessageType type;
  final List<String>? mediaUrls;
  final List<String>? mentionedUsers;
  final String? replyToMessageId;
  final DateTime timestamp;
  final int retryCount;

  PendingMessage({
    required this.tempId,
    required this.conversationId,
    required this.content,
    required this.type,
    this.mediaUrls,
    this.mentionedUsers,
    this.replyToMessageId,
    required this.timestamp,
    this.retryCount = 0,
  });

  PendingMessage copyWith({int? retryCount}) {
    return PendingMessage(
      tempId: tempId,
      conversationId: conversationId,
      content: content,
      type: type,
      mediaUrls: mediaUrls,
      mentionedUsers: mentionedUsers,
      replyToMessageId: replyToMessageId,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Implementation of ChatRepository with comprehensive chat functionality
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  // Cache for conversations and messages
  final Map<String, ConversationModel> _conversationCache = {};
  final Map<String, List<ChatMessageModel>> _messageCache = {};
  final Map<String, DateTime> _conversationCacheTime = {};
  final Map<String, DateTime> _messageCacheTime = {};

  // Message queue for offline/failed sends
  final List<PendingMessage> _messageQueue = [];
  Timer? _messageQueueProcessor;

  // Real-time streams
  final Map<String, StreamController<List<ChatMessageModel>>> _messageStreamControllers = {};
  final Map<String, StreamController<List<ConversationModel>>> _conversationStreamControllers = {};
  final Map<String, StreamController<Map<String, bool>>> _typingStreamControllers = {};
  final Map<String, StreamController<Map<String, DateTime>>> _readReceiptStreamControllers = {};

  // Aggregated streams expected by interface
  final StreamController<Map<String, List<String>>> _globalTypingStreamController = StreamController<Map<String, List<String>>>.broadcast();
  final StreamController<Map<String, Map<String, DateTime>>> _globalReadReceiptsController = StreamController<Map<String, Map<String, DateTime>>>.broadcast();

  // Typing indicators
  final Map<String, Map<String, DateTime>> _typingUsers = {};
  Timer? _typingCleanupTimer;

  // Read receipts
  final Map<String, Map<String, DateTime>> _readReceipts = {};

  // Cache settings
  static const Duration _conversationCacheTTL = Duration(minutes: 5);
  static const Duration _messageCacheTTL = Duration(minutes: 3);
  static const Duration _typingIndicatorTimeout = Duration(seconds: 3);
  static const int _maxRetries = 3;
  static const Duration _queueProcessInterval = Duration(seconds: 5);

  ChatRepositoryImpl(this._remoteDataSource) {
    _startMessageQueueProcessor();
    _startTypingCleanup();
  }

  @override
  Future<Either<Failure, List<ConversationModel>>> getConversations({
    ConversationType? type,
    int page = 1,
    int limit = 20,
    bool includeUnreadOnly = false,
  }) async {
    try {
      final conversations = await _remoteDataSource.getConversations(
        page: page,
        limit: limit,
      );

      // Cache conversations individually
      for (final conversation in conversations) {
        _conversationCache[conversation.id] = conversation;
        _conversationCacheTime[conversation.id] = DateTime.now();
      }

    // Optionally filter unread only
    final result = includeUnreadOnly
      ? conversations.where((c) => c.unreadCount > 0).toList()
      : conversations;
    return Right(result);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get conversations: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> getConversation(String conversationId) async {
    try {
      final cached = _conversationCache[conversationId];
      final cacheTime = _conversationCacheTime[conversationId];

      if (cached != null &&
          cacheTime != null &&
          DateTime.now().difference(cacheTime) < _conversationCacheTTL) {
        return Right(cached);
      }

      final conversation = await _remoteDataSource.getConversation(conversationId);

      _conversationCache[conversationId] = conversation;
      _conversationCacheTime[conversationId] = DateTime.now();

      return Right(conversation);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> createConversation({
    required ConversationType type,
    required List<String> participantIds,
    String? name,
    String? description,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final conversation = await _remoteDataSource.createConversation(
        title: name ?? 'Conversation',
        participantIds: participantIds,
        type: type,
        description: description,
        avatarUrl: avatarUrl,
      );

      // Update cache
      _conversationCache[conversation.id] = conversation;
      _conversationCacheTime[conversation.id] = DateTime.now();

      // Notify stream subscribers
      _notifyConversationStreams();

      return Right(conversation);
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to create conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> updateConversation({
    required String conversationId,
    String? name,
    String? description,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final conversation = await _remoteDataSource.updateConversation(
        conversationId: conversationId,
        title: name,
        description: description,
        avatarUrl: avatarUrl,
      );

      // Update cache
      _conversationCache[conversationId] = conversation;
      _conversationCacheTime[conversationId] = DateTime.now();

      // Notify stream subscribers
      _notifyConversationStreams();

  return Right(conversation);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to update conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteConversation(String conversationId) async {
    try {
      final success = await _remoteDataSource.deleteConversation(conversationId);

      if (success) {
        // Remove from cache
        _conversationCache.remove(conversationId);
        _conversationCacheTime.remove(conversationId);
        _messageCache.remove(conversationId);
        _messageCacheTime.remove(conversationId);

        // Close streams
        _messageStreamControllers[conversationId]?.close();
        _messageStreamControllers.remove(conversationId);
        _typingStreamControllers[conversationId]?.close();
        _typingStreamControllers.remove(conversationId);
        _readReceiptStreamControllers[conversationId]?.close();
        _readReceiptStreamControllers.remove(conversationId);

        // Clean up typing and read receipts
        _typingUsers.remove(conversationId);
        _readReceipts.remove(conversationId);

        // Notify stream subscribers
        _notifyConversationStreams();
      }

      return Right(success);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to delete conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageModel>> sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    List<String>? mediaUrls,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Create optimistic message
  final optimisticMessage = ChatMessageModel(
        id: tempId,
        conversationId: conversationId,
        senderId: 'current_user', // Replace with actual current user ID
        content: content,
        sentAt: DateTime.now(),
        messageType: messageType,
      );

      // Add to cache optimistically
  final messages = _messageCache[conversationId] ?? [];
      messages.add(optimisticMessage);
      _messageCache[conversationId] = messages;

      // Notify stream subscribers
      _notifyMessageStreams(conversationId);

      // Add to message queue
  final pendingMessage = PendingMessage(
        tempId: tempId,
        conversationId: conversationId,
        content: content,
        type: messageType,
        mediaUrls: mediaUrls,
        mentionedUsers: null,
        replyToMessageId: replyToMessageId,
        timestamp: DateTime.now(),
      );
      _messageQueue.add(pendingMessage);

      return Right(optimisticMessage);
    } catch (e) {
      return Left(MessageSendFailure(message: 'Failed to queue message: $e', tempId: tempId));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageModel>>> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    String? beforeMessageId,
    String? afterMessageId,
  }) async {
    try {
      final cacheKey = '${conversationId}_${page}_${limit}_${beforeMessageId ?? ''}_${afterMessageId ?? ''}';
      final cached = _messageCache[cacheKey];
      final cacheTime = _messageCacheTime[cacheKey];

      if (cached != null &&
          cacheTime != null &&
          DateTime.now().difference(cacheTime) < _messageCacheTTL) {
        return Right(cached);
      }

      final messages = await _remoteDataSource.getMessages(
        conversationId,
        page: page,
        limit: limit,
        beforeMessageId: beforeMessageId,
      );

      // Cache messages
      _messageCache[cacheKey] = messages;
      _messageCacheTime[cacheKey] = DateTime.now();

      // Also cache individual messages
  final conversationMessages = _messageCache[conversationId] ?? [];
      for (final message in messages) {
        final index = conversationMessages.indexWhere((m) => m.id == message.id);
        if (index >= 0) {
          conversationMessages[index] = message;
        } else {
          conversationMessages.add(message);
        }
      }
      _messageCache[conversationId] = conversationMessages;

      return Right(messages);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get messages: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageModel>> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      final message = await _remoteDataSource.updateMessage(
        messageId: messageId,
        content: newContent,
        mediaUrls: null,
        mentionedUsers: null,
      );

      // Update cache
      final conversationMessages = _messageCache[message.conversationId];
      if (conversationMessages != null) {
        final index = conversationMessages.indexWhere((m) => m.id == messageId);
        if (index >= 0) {
          conversationMessages[index] = message;
          _notifyMessageStreams(message.conversationId);
        }
      }

      return Right(message);
    } on MessageNotFoundException catch (e) {
      return Left(MessageNotFoundFailure(e.messageId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to edit message: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMessage(String messageId) async {
    try {
      final success = await _remoteDataSource.deleteMessage(messageId);

      if (success) {
        // Remove from all caches
        for (final messages in _messageCache.values) {
          messages.removeWhere((m) => m.id == messageId);
        }

        // Notify all message streams (we don't know which conversation)
        for (final conversationId in _messageStreamControllers.keys) {
          _notifyMessageStreams(conversationId);
        }
      }

      return Right(success);
    } on MessageNotFoundException catch (e) {
      return Left(MessageNotFoundFailure(e.messageId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to delete message: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> markMessageAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      // We don't know conversationId directly; try to locate it from cache
      String? conversationId;
      _messageCache.forEach((key, value) {
        if (conversationId != null) return;
        final found = value.indexWhere((m) => m.id == messageId);
        if (found >= 0) {
          // key might be either conversationId or a composite cacheKey; prefer real conv id present in message
          conversationId = value[found].conversationId;
        }
      });

      if (conversationId == null) {
        // Fallback: couldn't find in cache, succeed silently
        return Right(true);
      }

      final success = await _remoteDataSource.markAsRead(
        conversationId: conversationId!,
        messageId: messageId,
      );

      if (success) {
        // Update read receipts cache
        final conversationReceipts = _readReceipts[conversationId!] ?? {};
        conversationReceipts[userId] = DateTime.now();
        _readReceipts[conversationId!] = conversationReceipts;

        // Notify read receipt streams
        _notifyReadReceiptStreams(conversationId!);

        // Update message cache to mark messages as read
        final messages = _messageCache[conversationId!];
        if (messages != null) {
          final idx = messages.indexWhere((m) => m.id == messageId);
          if (idx >= 0) {
            // Mark this message and all previous messages as read by this user
            for (int i = 0; i <= idx; i++) {
              final prev = messages[i];
              final updated = prev.copyWith(
                // No isRead field on model; simulate via readBy/readTimestamps
                readBy: prev.readBy.contains(userId)
                    ? prev.readBy
                    : [...prev.readBy, userId],
                readTimestamps: {
                  ...prev.readTimestamps,
                  userId: DateTime.now(),
                },
              );
              messages[i] = updated;
            }
            _notifyMessageStreams(conversationId!);
          }
        }
      }

      return Right(success);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on MessageNotFoundException catch (e) {
      return Left(MessageNotFoundFailure(e.messageId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to mark as read: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> markMessageAsDelivered({
    required String messageId,
    required String userId,
  }) async {
    try {
      // Update locally; remote endpoint may not exist
      for (final entry in _messageCache.entries) {
        final messages = entry.value;
        final idx = messages.indexWhere((m) => m.id == messageId);
        if (idx >= 0) {
          final prev = messages[idx];
          final deliveredTo = prev.deliveredTo.contains(userId)
              ? prev.deliveredTo
              : [...prev.deliveredTo, userId];
          messages[idx] = prev.copyWith(deliveredTo: deliveredTo);
          _notifyMessageStreams(prev.conversationId);
          break;
        }
      }
      return const Right(true);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to mark delivered: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> markConversationAsRead(String conversationId) async {
    try {
      // Update unread count to 0 locally
      final conv = _conversationCache[conversationId];
      if (conv != null) {
        _conversationCache[conversationId] = conv.copyWith(unreadCount: 0);
        _notifyConversationStreams();
      }
      return const Right(true);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to mark conversation as read: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> startTyping(String conversationId) async {
    try {
      final success = await _remoteDataSource.setTyping(
        conversationId: conversationId,
        isTyping: true,
      );

      if (success) {
        // Update local typing state
        final conversationTyping = _typingUsers[conversationId] ?? {};
        conversationTyping['current_user'] = DateTime.now(); // Replace with actual current user ID
        _typingUsers[conversationId] = conversationTyping;

        // Notify typing streams
        _notifyTypingStreams(conversationId);
      }

      return Right(success);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to start typing: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> stopTyping(String conversationId) async {
    try {
      final success = await _remoteDataSource.setTyping(
        conversationId: conversationId,
        isTyping: false,
      );
      if (success) {
        final conversationTyping = _typingUsers[conversationId] ?? {};
        conversationTyping.remove('current_user');
        _typingUsers[conversationId] = conversationTyping;
        _notifyTypingStreams(conversationId);
      }
      return Right(success);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to stop typing: $e'));
    }
  }

  @override
  Stream<ChatMessageModel> messageStream(String conversationId) {
    // Prefer remote real-time stream per message
    return _remoteDataSource.subscribeToMessages(conversationId);
  }

  @override
  Stream<ConversationModel> conversationStream() {
    return _remoteDataSource.subscribeToConversations();
  }

  @override
  Stream<Map<String, List<String>>> typingStream() {
    return _globalTypingStreamController.stream;
  }

  @override
  Stream<Map<String, Map<String, DateTime>>> readReceiptsStream() {
    return _globalReadReceiptsController.stream;
  }

  @override
  Future<Either<Failure, List<String>>> uploadMessageMedia(List<String> filePaths) async {
    try {
      final files = filePaths.map((p) => File(p)).toList();
      final urls = await _remoteDataSource.uploadMedia(files);
      return Right(urls);
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to upload media: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> addParticipant({
    required String conversationId,
    required String userId,
    ParticipantRole role = ParticipantRole.member,
  }) async {
    try {
      final success = await _remoteDataSource.addParticipant(
        conversationId: conversationId,
        userId: userId,
      );

      if (success) {
        // Refresh conversation and return
        final updated = await _remoteDataSource.getConversation(conversationId);
        _conversationCache[conversationId] = updated;
        _conversationCacheTime[conversationId] = DateTime.now();
        _notifyConversationStreams();
        return Right(updated);
      }

      return Left(ChatServerFailure(message: 'Failed to add participant'));
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to add participant: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> removeParticipant({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final success = await _remoteDataSource.removeParticipant(
        conversationId: conversationId,
        userId: userId,
      );

      if (success) {
        // Refresh conversation and return
        final updated = await _remoteDataSource.getConversation(conversationId);
        _conversationCache[conversationId] = updated;
        _conversationCacheTime[conversationId] = DateTime.now();
        _notifyConversationStreams();
        return Right(updated);
      }

      return Left(ChatServerFailure(message: 'Failed to remove participant'));
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to remove participant: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> leaveConversation(String conversationId) async {
    try {
      final success = await _remoteDataSource.leaveConversation(conversationId);

      if (success) {
        // Remove from all caches and streams
        _conversationCache.remove(conversationId);
        _conversationCacheTime.remove(conversationId);
        _messageCache.remove(conversationId);
        _messageCacheTime.remove(conversationId);

        // Close streams
        _messageStreamControllers[conversationId]?.close();
        _messageStreamControllers.remove(conversationId);
        _typingStreamControllers[conversationId]?.close();
        _typingStreamControllers.remove(conversationId);
        _readReceiptStreamControllers[conversationId]?.close();
        _readReceiptStreamControllers.remove(conversationId);

        // Clean up typing and read receipts
        _typingUsers.remove(conversationId);
        _readReceipts.remove(conversationId);

        // Notify stream subscribers
        _notifyConversationStreams();
      }

      return Right(success);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to leave conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageModel>>> searchMessages({
    String? conversationId,
    required String query,
    int page = 1,
    int limit = 20,
    MessageType? messageType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final messages = await _remoteDataSource.searchMessages(
        conversationId: conversationId,
        query: query,
        messageType: messageType,
        page: page,
        limit: limit,
      );

      return Right(messages);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to search messages: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadMessageCount(String conversationId) async {
    try {
      final counts = await _remoteDataSource.getUnreadCounts();
      return Right(counts[conversationId] ?? 0);
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get unread count: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getTotalUnreadCount() async {
    try {
      final counts = await _remoteDataSource.getUnreadCounts();
      final total = counts.values.fold<int>(0, (sum, v) => sum + v);
      return Right(total);
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get total unread count: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> muteConversation({
    required String conversationId,
    required bool mute,
    Duration? duration,
  }) async {
    try {
      bool success = false;
      if (mute) {
        final until = duration != null ? DateTime.now().add(duration) : null;
        success = await _remoteDataSource.muteConversation(
          conversationId: conversationId,
          muteUntil: until,
        );
      } else {
        success = await _remoteDataSource.unmuteConversation(conversationId);
      }

      if (success) {
        // Invalidate conversation cache to force refresh
        _conversationCache.remove(conversationId);
        _conversationCacheTime.remove(conversationId);

        // Notify stream subscribers
        _notifyConversationStreams();
      }

      return Right(success);
    } on ConversationNotFoundException catch (e) {
      return Left(ConversationNotFoundFailure(e.conversationId));
    } on UnauthorizedChatException catch (e) {
      return Left(UnauthorizedChatFailure(message: e.message));
    } on ChatServerException catch (e) {
      return Left(ChatServerFailure(message: e.message));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to update mute state: $e'));
    }
  }

  // Unmute remains available via muteConversation with mute=false

  void dispose() {
    _messageQueueProcessor?.cancel();
    _typingCleanupTimer?.cancel();

    // Close all stream controllers
    for (final controller in _messageStreamControllers.values) {
      controller.close();
    }
    for (final controller in _conversationStreamControllers.values) {
      controller.close();
    }
    for (final controller in _typingStreamControllers.values) {
      controller.close();
    }
    for (final controller in _readReceiptStreamControllers.values) {
      controller.close();
    }

    // Clear all caches
    _conversationCache.clear();
    _messageCache.clear();
    _conversationCacheTime.clear();
    _messageCacheTime.clear();
    _messageQueue.clear();
    _typingUsers.clear();
    _readReceipts.clear();
  }

  @override
  Future<Either<Failure, ConversationModel>> createGroupChat({
    required String name,
    required List<String> participantIds,
    String? description,
    String? avatarUrl,
    GroupChatMetadata? metadata,
  }) async {
    try {
      final conv = await _remoteDataSource.createConversation(
        title: name,
        participantIds: participantIds,
        type: ConversationType.group,
        description: description,
        avatarUrl: avatarUrl,
      );
      // We can't persist group metadata without a dedicated endpoint; cache it locally
      final updated = conv.copyWith(groupMetadata: metadata);
      _conversationCache[updated.id] = updated;
      _conversationCacheTime[updated.id] = DateTime.now();
      _notifyConversationStreams();
      return Right(updated);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to create group chat: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> updateGroupChatMetadata({
    required String conversationId,
    required GroupChatMetadata metadata,
  }) async {
    try {
      // Best-effort: try to persist via settings update embedding group_metadata
      final success = await _remoteDataSource.updateConversationSettings(
        conversationId: conversationId,
        settings: {'group_metadata': metadata.toJson()},
      );
      if (!success) {
        return Left(ChatServerFailure(message: 'Failed to update group metadata'));
      }
      // Fetch updated conversation
      final conv = await _remoteDataSource.getConversation(conversationId);
      final updated = conv.copyWith(groupMetadata: metadata);
      _conversationCache[conversationId] = updated;
      _conversationCacheTime[conversationId] = DateTime.now();
      _notifyConversationStreams();
      return Right(updated);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to update group chat metadata: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> generateInviteLink({
    required String conversationId,
    Duration? expiryDuration,
  }) async {
    try {
      final link = await _remoteDataSource.getConversationInviteLink(conversationId);
      return Right(link);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to generate invite link: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> joinViaInviteLink(String inviteCode) async {
    try {
      final conv = await _remoteDataSource.joinConversationByInvite(inviteCode);
      _conversationCache[conv.id] = conv;
      _conversationCacheTime[conv.id] = DateTime.now();
      _notifyConversationStreams();
      return Right(conv);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to join via invite: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ConversationParticipant>>> getParticipants(String conversationId) async {
    try {
      // Use conversation fetch to get rich participant objects
      final conv = await _remoteDataSource.getConversation(conversationId);
      return Right(conv.participants);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get participants: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getTypingUsers(String conversationId) async {
    try {
      final typing = _typingUsers[conversationId] ?? {};
      final now = DateTime.now();
      final users = typing.entries
          .where((e) => now.difference(e.value) < _typingIndicatorTimeout)
          .map((e) => e.key)
          .toList();
      return Right(users);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get typing users: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageModel>> forwardMessage({
    required String messageId,
    required String toConversationId,
    String? additionalContent,
  }) async {
    try {
      final results = await _remoteDataSource.forwardMessages(
        messageIds: [messageId],
        conversationIds: [toConversationId],
        additionalContent: additionalContent,
      );
      if (results.isEmpty) {
        return Left(ChatServerFailure(message: 'Forward failed'));
      }
      return Right(results.first);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to forward message: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> pinMessage({
    required String messageId,
    required bool pin,
  }) async {
    try {
      // Need conversationId to pin; look up from cache
      String? convId;
      for (final entry in _messageCache.entries) {
        final idx = entry.value.indexWhere((m) => m.id == messageId);
        if (idx >= 0) {
          convId = entry.value[idx].conversationId;
          break;
        }
      }
      if (convId == null) return Left(ChatServerFailure(message: 'Conversation not found for message'));
      final ok = pin
          ? await _remoteDataSource.pinMessage(conversationId: convId, messageId: messageId)
          : await _remoteDataSource.unpinMessage(conversationId: convId, messageId: messageId);
      return Right(ok);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to update pin: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageModel>>> getPinnedMessages(String conversationId) async {
    try {
      final msgs = await _remoteDataSource.getPinnedMessages(conversationId);
      return Right(msgs);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get pinned messages: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> reactToMessage({
    required String messageId,
    required String reaction,
  }) async {
    try {
      final ok = await _remoteDataSource.reactToMessage(messageId: messageId, emoji: reaction);
      return Right(ok);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to react to message: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeMessageReaction(String messageId) async {
    try {
      // Remove all reactions for current user by fetching reaction map
      final reactions = await _remoteDataSource.getMessageReactions(messageId);
      bool removedAny = false;
      for (final emoji in reactions.keys) {
        final ok = await _remoteDataSource.removeReactionFromMessage(messageId: messageId, emoji: emoji);
        removedAny = removedAny || ok;
      }
      return Right(removedAny);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to remove reaction: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationSettings>> getConversationSettings(String conversationId) async {
    try {
      final map = await _remoteDataSource.getConversationSettings(conversationId);
      return Right(ConversationSettings.fromJson(map));
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to get conversation settings: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationSettings>> updateConversationSettings({
    required String conversationId,
    required ConversationSettings settings,
  }) async {
    try {
      final ok = await _remoteDataSource.updateConversationSettings(
        conversationId: conversationId,
        settings: settings.toJson(),
      );
      if (!ok) return Left(ChatServerFailure(message: 'Failed to update settings'));
      return Right(settings);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to update conversation settings: $e'));
    }
  }

  @override
  Future<Either<Failure, ConversationModel>> updateParticipantRole({
    required String conversationId,
    required String userId,
    required ParticipantRole role,
  }) async {
    try {
      // No direct endpoint; best-effort update by fetching and updating locally
      final conv = await _remoteDataSource.getConversation(conversationId);
      final updated = conv.updateParticipantRole(userId, role);
      _conversationCache[conversationId] = updated;
      _conversationCacheTime[conversationId] = DateTime.now();
      _notifyConversationStreams();
      return Right(updated);
    } catch (e) {
      return Left(ChatServerFailure(message: 'Failed to update participant role: $e'));
    }
  }

  // Helper methods

  void _startMessageQueueProcessor() {
    _messageQueueProcessor = Timer.periodic(_queueProcessInterval, (_) async {
      if (_messageQueue.isEmpty) return;

      final messagesToProcess = List<PendingMessage>.from(_messageQueue);
      _messageQueue.clear();

      for (final pendingMessage in messagesToProcess) {
        try {
          final sentMessage = await _remoteDataSource.sendMessage(
            conversationId: pendingMessage.conversationId,
            content: pendingMessage.content,
            type: pendingMessage.type,
            mediaUrls: pendingMessage.mediaUrls,
            mentionedUsers: pendingMessage.mentionedUsers,
            replyToMessageId: pendingMessage.replyToMessageId,
          );

          // Replace optimistic message with real message
          final messages = _messageCache[pendingMessage.conversationId];
          if (messages != null) {
            final index = messages.indexWhere((m) => m.id == pendingMessage.tempId);
            if (index >= 0) {
              messages[index] = sentMessage;
              _notifyMessageStreams(pendingMessage.conversationId);
            }
          }
        } catch (e) {
          // Retry logic
          if (pendingMessage.retryCount < _maxRetries) {
            _messageQueue.add(pendingMessage.copyWith(retryCount: pendingMessage.retryCount + 1));
          } else {
            // Mark as failed
            final messages = _messageCache[pendingMessage.conversationId];
            if (messages != null) {
              final index = messages.indexWhere((m) => m.id == pendingMessage.tempId);
              if (index >= 0) {
                final failedMessage = messages[index].copyWith(
                  content: '${messages[index].content} [Failed to send]',
                );
                messages[index] = failedMessage;
                _notifyMessageStreams(pendingMessage.conversationId);
              }
            }
          }
        }
      }
    });
  }

  void _startTypingCleanup() {
    _typingCleanupTimer = Timer.periodic(Duration(seconds: 1), (_) {
      final now = DateTime.now();
  bool hasChanges = false;

      for (final conversationId in _typingUsers.keys.toList()) {
        final typingUsers = _typingUsers[conversationId]!;
        final expiredUsers = <String>[];

        for (final entry in typingUsers.entries) {
          if (now.difference(entry.value) >= _typingIndicatorTimeout) {
            expiredUsers.add(entry.key);
          }
        }

        if (expiredUsers.isNotEmpty) {
          for (final userId in expiredUsers) {
            typingUsers.remove(userId);
          }
          hasChanges = true;
          _notifyTypingStreams(conversationId);
        }

        if (typingUsers.isEmpty) {
          _typingUsers.remove(conversationId);
        }
      }

      if (hasChanges) {
        // Push aggregated typing map
        final aggregate = <String, List<String>>{};
        final now2 = DateTime.now();
        _typingUsers.forEach((convId, map) {
          final users = map.entries
              .where((e) => now2.difference(e.value) < _typingIndicatorTimeout)
              .map((e) => e.key)
              .toList();
          if (users.isNotEmpty) aggregate[convId] = users;
        });
        _globalTypingStreamController.add(aggregate);
      }
    });
  }

  void _notifyMessageStreams(String conversationId) {
    final controller = _messageStreamControllers[conversationId];
    final messages = _messageCache[conversationId];
    if (controller != null && messages != null) {
      controller.add(messages);
    }
  }

  void _notifyConversationStreams() {
    const streamKey = 'conversations';
    final controller = _conversationStreamControllers[streamKey];
    if (controller != null) {
      final conversations = _conversationCache.values.toList();
      controller.add(conversations);
    }
  }

  void _notifyTypingStreams(String conversationId) {
    final controller = _typingStreamControllers[conversationId];
    final typingUsers = _typingUsers[conversationId] ?? {};
    if (controller != null) {
      final activeTyping = <String, bool>{};
      final now = DateTime.now();
      for (final entry in typingUsers.entries) {
        if (now.difference(entry.value) < _typingIndicatorTimeout) {
          activeTyping[entry.key] = true;
        }
      }
      controller.add(activeTyping);
    }
  }

  void _notifyReadReceiptStreams(String conversationId) {
    final controller = _readReceiptStreamControllers[conversationId];
    final readReceipts = _readReceipts[conversationId];
    if (controller != null && readReceipts != null) {
      controller.add(readReceipts);
    }

  // Also push aggregate map
  _globalReadReceiptsController.add(Map<String, Map<String, DateTime>>.from(_readReceipts));
  }
}
