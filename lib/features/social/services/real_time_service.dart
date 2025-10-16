import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../../../core/utils/either.dart';
import '../../../core/analytics/analytics_service.dart';
import '../data/models/message_model.dart';
import '../data/models/post_model.dart';
import '../data/models/friend_request_model.dart';
import '../../../core/models/user_model.dart';

/// Service for managing real-time WebSocket connections and event handling
class RealTimeService {
  final AnalyticsService _analyticsService;

  // WebSocket connection
  WebSocketChannel? _channel;
  String? _websocketUrl;
  String? _authToken;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Subscribed channels
  final Set<String> _subscribedChannels = {};
  
  // Event streams
  final StreamController<MessageModel> _messageController = 
      StreamController<MessageModel>.broadcast();
  final StreamController<PostModel> _postUpdateController = 
      StreamController<PostModel>.broadcast();
  final StreamController<Map<String, dynamic>> _postReactionController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<FriendRequestModel> _friendRequestController = 
      StreamController<FriendRequestModel>.broadcast();
  final StreamController<Map<String, dynamic>> _typingStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _readReceiptsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<UserModel> _userStatusController = 
      StreamController<UserModel>.broadcast();

  // Event deduplication
  final Set<String> _processedEvents = {};
  Timer? _eventCleanupTimer;

  // Battery optimization
  bool _isInBackground = false;

  RealTimeService({
    required AnalyticsService analyticsService,
  })  : _analyticsService = analyticsService {
    _initializeService();
  }

  // Public stream getters
  Stream<MessageModel> get onMessage => _messageController.stream;
  Stream<PostModel> get onPostUpdate => _postUpdateController.stream;
  Stream<Map<String, dynamic>> get onPostReaction => _postReactionController.stream;
  Stream<FriendRequestModel> get onFriendRequest => _friendRequestController.stream;
  Stream<Map<String, dynamic>> get onTypingStatus => _typingStatusController.stream;
  Stream<Map<String, dynamic>> get onReadReceipts => _readReceiptsController.stream;
  Stream<UserModel> get onUserStatus => _userStatusController.stream;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  void _initializeService() {
    _startEventCleanup();
    _loadConnectionConfig();
  }

  /// Initialize WebSocket connection
  Future<Either<String, bool>> connect({
    required String websocketUrl,
    required String authToken,
  }) async {
    if (_isConnected || _isConnecting) {
      return Right(true);
    }

    try {
      _isConnecting = true;
      _websocketUrl = websocketUrl;
      _authToken = authToken;

      debugPrint('Connecting to WebSocket: $websocketUrl');

      // Create WebSocket connection with headers
      final uri = Uri.parse(websocketUrl);
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'User-Agent': 'Dabbler-App/1.0',
        },
      );

      // Listen for connection establishment
      await _channel!.ready;
      
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      // Start listening to messages
      _listenToWebSocket();
      
      // Start heartbeat
      _startHeartbeat();

      // Resubscribe to channels
      await _resubscribeToChannels();

      // Track analytics
      _analyticsService.trackEvent('websocket_connected', {
        'reconnect_attempts': _reconnectAttempts,
      });

      debugPrint('WebSocket connected successfully');
      return Right(true);
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      
      debugPrint('WebSocket connection failed: $e');
      
      // Schedule reconnection
      _scheduleReconnect();
      
      return Left('Failed to connect to real-time service: ${e.toString()}');
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    debugPrint('Disconnecting WebSocket');

    _isConnected = false;
    _isConnecting = false;
    
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    try {
      await _channel?.sink.close();
      _channel = null;
    } catch (e) {
      debugPrint('Error closing WebSocket: $e');
    }

    _subscribedChannels.clear();
    
    _analyticsService.trackEvent('websocket_disconnected', {});
  }

  /// Subscribe to a specific channel
  Future<Either<String, bool>> subscribe(String channel) async {
    if (!_isConnected) {
      return Left('Not connected to real-time service');
    }

    try {
      final subscribeMessage = {
        'action': 'subscribe',
        'channel': channel,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(subscribeMessage));
      _subscribedChannels.add(channel);

      debugPrint('Subscribed to channel: $channel');
      
      _analyticsService.trackEvent('channel_subscribed', {
        'channel': channel,
      });

      return Right(true);
    } catch (e) {
      debugPrint('Error subscribing to channel $channel: $e');
      return Left('Failed to subscribe to channel: ${e.toString()}');
    }
  }

  /// Unsubscribe from a specific channel
  Future<Either<String, bool>> unsubscribe(String channel) async {
    if (!_isConnected) {
      return Left('Not connected to real-time service');
    }

    try {
      final unsubscribeMessage = {
        'action': 'unsubscribe',
        'channel': channel,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(unsubscribeMessage));
      _subscribedChannels.remove(channel);

      debugPrint('Unsubscribed from channel: $channel');
      
      _analyticsService.trackEvent('channel_unsubscribed', {
        'channel': channel,
      });

      return Right(true);
    } catch (e) {
      debugPrint('Error unsubscribing from channel $channel: $e');
      return Left('Failed to unsubscribe from channel: ${e.toString()}');
    }
  }

  /// Subscribe to friend-related events
  Future<Either<String, bool>> subscribeFriendEvents(String userId) async {
    final channels = [
      'user:$userId:friend_requests',
      'user:$userId:friends',
    ];

    for (final channel in channels) {
      final result = await subscribe(channel);
      if (result.isLeft) {
        return result;
      }
    }

    return Right(true);
  }

  /// Subscribe to chat events for a conversation
  Future<Either<String, bool>> subscribeChatEvents(String conversationId) async {
    final channels = [
      'conversation:$conversationId:messages',
      'conversation:$conversationId:typing',
      'conversation:$conversationId:read_receipts',
    ];

    for (final channel in channels) {
      final result = await subscribe(channel);
      if (result.isLeft) {
        return result;
      }
    }

    return Right(true);
  }

  /// Subscribe to social feed events
  Future<Either<String, bool>> subscribeSocialEvents(String userId) async {
    final channels = [
      'user:$userId:feed',
      'user:$userId:posts',
      'user:$userId:reactions',
      'user:$userId:comments',
    ];

    for (final channel in channels) {
      final result = await subscribe(channel);
      if (result.isLeft) {
        return result;
      }
    }

    return Right(true);
  }

  /// Broadcast a message to other clients
  Future<void> broadcastMessage(MessageModel message) async {
    if (!_isConnected) return;

    try {
      final broadcastData = {
        'action': 'broadcast',
        'type': 'message',
        'data': message.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(broadcastData));
    } catch (e) {
      debugPrint('Error broadcasting message: $e');
    }
  }

  /// Broadcast typing status
  Future<void> broadcastTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    if (!_isConnected) return;

    try {
      final broadcastData = {
        'action': 'broadcast',
        'type': 'typing_status',
        'data': {
          'conversation_id': conversationId,
          'user_id': userId,
          'is_typing': isTyping,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(broadcastData));
    } catch (e) {
      debugPrint('Error broadcasting typing status: $e');
    }
  }

  /// Broadcast read receipts
  Future<void> broadcastReadReceipts({
    required String conversationId,
    required List<String> messageIds,
    required String userId,
  }) async {
    if (!_isConnected) return;

    try {
      final broadcastData = {
        'action': 'broadcast',
        'type': 'read_receipts',
        'data': {
          'conversation_id': conversationId,
          'message_ids': messageIds,
          'user_id': userId,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(broadcastData));
    } catch (e) {
      debugPrint('Error broadcasting read receipts: $e');
    }
  }

  /// Broadcast message deletion
  Future<void> broadcastMessageDeletion(String messageId, bool forEveryone) async {
    if (!_isConnected) return;

    try {
      final broadcastData = {
        'action': 'broadcast',
        'type': 'message_deleted',
        'data': {
          'message_id': messageId,
          'for_everyone': forEveryone,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(broadcastData));
    } catch (e) {
      debugPrint('Error broadcasting message deletion: $e');
    }
  }

  /// Handle app lifecycle changes for battery optimization
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isInBackground = true;
        _optimizeForBackground();
        break;
      case AppLifecycleState.resumed:
        _isInBackground = false;
        _optimizeForForeground();
        break;
      default:
        break;
    }
  }

  void _listenToWebSocket() {
    _channel!.stream.listen(
      _handleWebSocketMessage,
      onError: _handleWebSocketError,
      onDone: _handleWebSocketDone,
    );
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final eventId = data['id'] as String?;
      
      // Check for event deduplication
      if (eventId != null) {
        if (_processedEvents.contains(eventId)) {
          return; // Skip duplicate event
        }
        _processedEvents.add(eventId);
      }

      final type = data['type'] as String?;
      final eventData = data['data'] as Map<String, dynamic>?;

      if (type == null || eventData == null) {
        debugPrint('Invalid WebSocket message format');
        return;
      }

      // Route message to appropriate handler
      switch (type) {
        case 'message':
          _handleIncomingMessage(eventData);
          break;
        case 'post_update':
          _handlePostUpdate(eventData);
          break;
        case 'post_reaction':
          _handlePostReaction(eventData);
          break;
        case 'friend_request':
          _handleFriendRequest(eventData);
          break;
        case 'typing_status':
          _handleTypingStatus(eventData);
          break;
        case 'read_receipts':
          _handleReadReceipts(eventData);
          break;
        case 'user_status':
          _handleUserStatus(eventData);
          break;
        case 'heartbeat':
          _handleHeartbeat(eventData);
          break;
        default:
          debugPrint('Unknown WebSocket message type: $type');
      }

      // Track analytics for received events
      _analyticsService.trackEvent('websocket_event_received', {
        'type': type,
        'has_event_id': eventId != null,
      });
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      final message = MessageModel.fromJson(data);
      _messageController.add(message);
    } catch (e) {
      debugPrint('Error parsing incoming message: $e');
    }
  }

  void _handlePostUpdate(Map<String, dynamic> data) {
    try {
      final post = PostModel.fromJson(data);
      _postUpdateController.add(post);
    } catch (e) {
      debugPrint('Error parsing post update: $e');
    }
  }

  void _handlePostReaction(Map<String, dynamic> data) {
    _postReactionController.add(data);
  }

  void _handleFriendRequest(Map<String, dynamic> data) {
    try {
      final friendRequest = FriendRequestModel.fromJson(data);
      _friendRequestController.add(friendRequest);
    } catch (e) {
      debugPrint('Error parsing friend request: $e');
    }
  }

  void _handleTypingStatus(Map<String, dynamic> data) {
    _typingStatusController.add(data);
  }

  void _handleReadReceipts(Map<String, dynamic> data) {
    _readReceiptsController.add(data);
  }

  void _handleUserStatus(Map<String, dynamic> data) {
    try {
      final user = UserModel.fromJson(data);
      _userStatusController.add(user);
    } catch (e) {
      debugPrint('Error parsing user status: $e');
    }
  }

  void _handleHeartbeat(Map<String, dynamic> data) {
    debugPrint('Received heartbeat response');
  }

  void _handleWebSocketError(dynamic error) {
    debugPrint('WebSocket error: $error');
    
    _isConnected = false;
    
    _analyticsService.trackEvent('websocket_error', {
      'error': error.toString(),
    });
    
    _scheduleReconnect();
  }

  void _handleWebSocketDone() {
    debugPrint('WebSocket connection closed');
    
    _isConnected = false;
    _heartbeatTimer?.cancel();
    
    _analyticsService.trackEvent('websocket_connection_closed', {});
    
    if (!_isInBackground) {
      _scheduleReconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  void _sendHeartbeat() {
    if (!_isConnected) return;

    try {
      final heartbeat = {
        'action': 'heartbeat',
        'timestamp': DateTime.now().toIso8601String(),
      };

      _channel!.sink.add(jsonEncode(heartbeat));
    } catch (e) {
      debugPrint('Error sending heartbeat: $e');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return; // Reconnect already scheduled
    }

    _reconnectAttempts++;
    
    if (_reconnectAttempts > _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      _analyticsService.trackEvent('websocket_max_reconnect_attempts_reached', {});
      return;
    }

    // Exponential backoff with jitter
    final delay = Duration(
      milliseconds: (_initialReconnectDelay.inMilliseconds * 
          (1 << (_reconnectAttempts - 1))).clamp(
        _initialReconnectDelay.inMilliseconds,
        _maxReconnectDelay.inMilliseconds,
      ),
    );

    debugPrint('Scheduling reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      if (_websocketUrl != null && _authToken != null) {
        connect(websocketUrl: _websocketUrl!, authToken: _authToken!);
      }
    });
  }

  Future<void> _resubscribeToChannels() async {
    if (_subscribedChannels.isEmpty) return;

    debugPrint('Resubscribing to ${_subscribedChannels.length} channels');

    for (final channel in _subscribedChannels.toList()) {
      try {
        final subscribeMessage = {
          'action': 'subscribe',
          'channel': channel,
          'timestamp': DateTime.now().toIso8601String(),
        };

        _channel!.sink.add(jsonEncode(subscribeMessage));
      } catch (e) {
        debugPrint('Error resubscribing to channel $channel: $e');
      }
    }
  }

  void _optimizeForBackground() {
    // Reduce heartbeat frequency
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _sendHeartbeat(),
    );

    debugPrint('Optimized WebSocket for background');
  }

  void _optimizeForForeground() {
    // Restore normal heartbeat frequency
    _startHeartbeat();

    // Ensure connection is still active
    if (!_isConnected && _websocketUrl != null && _authToken != null) {
      connect(websocketUrl: _websocketUrl!, authToken: _authToken!);
    }

    debugPrint('Optimized WebSocket for foreground');
  }

  void _startEventCleanup() {
    _eventCleanupTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _cleanupProcessedEvents(),
    );
  }

  void _cleanupProcessedEvents() {
    // Keep only recent event IDs to prevent unbounded growth
    const maxEvents = 1000;
    if (_processedEvents.length > maxEvents) {
      final eventsToRemove = _processedEvents.length - maxEvents;
      final eventsList = _processedEvents.toList();
      
      for (int i = 0; i < eventsToRemove; i++) {
        _processedEvents.remove(eventsList[i]);
      }
    }

    debugPrint('Event cleanup completed. Tracking ${_processedEvents.length} events');
  }

  void _loadConnectionConfig() {
    // Load any saved connection preferences
    debugPrint('Real-time service initialized');
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'is_connected': _isConnected,
      'is_connecting': _isConnecting,
      'reconnect_attempts': _reconnectAttempts,
      'subscribed_channels_count': _subscribedChannels.length,
      'processed_events_count': _processedEvents.length,
      'is_in_background': _isInBackground,
    };
  }

  /// Dispose service and cleanup
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _eventCleanupTimer?.cancel();

    // Close stream controllers
    _messageController.close();
    _postUpdateController.close();
    _postReactionController.close();
    _friendRequestController.close();
    _typingStatusController.close();
    _readReceiptsController.close();
    _userStatusController.close();

    // Disconnect WebSocket
    disconnect();

    _processedEvents.clear();
    _subscribedChannels.clear();
  }
}
