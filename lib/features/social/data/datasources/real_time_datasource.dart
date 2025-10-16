import 'dart:async';
import 'dart:math';

/// Exception types for real-time data source operations
class RealTimeDataSourceException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  const RealTimeDataSourceException({
    required this.message,
    required this.code,
    this.details,
  });

  @override
  String toString() => 'RealTimeDataSourceException: $message (Code: $code)';
}

/// Connection exception
class ConnectionException extends RealTimeDataSourceException {
  const ConnectionException({
    required super.message,
    super.code = 'CONNECTION_ERROR',
    super.details,
  });
}

/// Subscription exception
class SubscriptionException extends RealTimeDataSourceException {
  const SubscriptionException({
    required super.message,
    super.code = 'SUBSCRIPTION_ERROR',
    super.details,
  });
}

/// Authentication exception for real-time
class RealTimeAuthException extends RealTimeDataSourceException {
  const RealTimeAuthException({
    required super.message,
    super.code = 'REALTIME_AUTH_ERROR',
    super.details,
  });
}

/// Connection state enumeration
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Event types for real-time updates
enum EventType {
  insert,
  update,
  delete,
  select,
  custom,
}

/// Real-time event data
class RealTimeEvent {
  final String id;
  final EventType type;
  final String table;
  final Map<String, dynamic> oldRecord;
  final Map<String, dynamic> newRecord;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const RealTimeEvent({
    required this.id,
    required this.type,
    required this.table,
    this.oldRecord = const {},
    this.newRecord = const {},
    required this.timestamp,
    this.metadata = const {},
  });

  factory RealTimeEvent.fromJson(Map<String, dynamic> json) {
    return RealTimeEvent(
      id: json['id'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.custom,
      ),
      table: json['table'] ?? '',
      oldRecord: Map<String, dynamic>.from(json['old_record'] ?? {}),
      newRecord: Map<String, dynamic>.from(json['new_record'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'table': table,
      'old_record': oldRecord,
      'new_record': newRecord,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Subscription configuration
class SubscriptionConfig {
  final String table;
  final String? filter;
  final List<String>? columns;
  final Map<String, dynamic> params;
  final bool autoReconnect;
  final Duration heartbeatInterval;

  const SubscriptionConfig({
    required this.table,
    this.filter,
    this.columns,
    this.params = const {},
    this.autoReconnect = true,
    this.heartbeatInterval = const Duration(seconds: 30),
  });
}

/// Connection configuration
class ConnectionConfig {
  final String endpoint;
  final Map<String, String> headers;
  final Duration connectTimeout;
  final Duration keepAliveInterval;
  final int maxReconnectAttempts;
  final Duration initialReconnectDelay;
  final Duration maxReconnectDelay;
  final double reconnectBackoffMultiplier;
  final bool enableLogging;

  const ConnectionConfig({
    required this.endpoint,
    this.headers = const {},
    this.connectTimeout = const Duration(seconds: 10),
    this.keepAliveInterval = const Duration(seconds: 30),
    this.maxReconnectAttempts = 5,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.reconnectBackoffMultiplier = 1.5,
    this.enableLogging = false,
  });
}

/// Queued event for offline scenarios
class QueuedEvent {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final DateTime? nextRetry;

  const QueuedEvent({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.nextRetry,
  });

  QueuedEvent copyWith({
    int? retryCount,
    DateTime? nextRetry,
  }) {
    return QueuedEvent(
      id: id,
      type: type,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      nextRetry: nextRetry ?? this.nextRetry,
    );
  }
}

/// Abstract interface for real-time data source operations
abstract class RealTimeDataSource {
  /// Connection management
  Future<void> connect({
    ConnectionConfig? config,
    Map<String, String>? authHeaders,
  });

  Future<void> disconnect();

  Future<bool> isConnected();

  ConnectionState get connectionState;

  Stream<ConnectionState> get connectionStateStream;

  /// Subscribe to table changes with filtering
  Future<String> subscribeToTable({
    required String table,
    String? filter,
    List<String>? columns,
    List<EventType>? eventTypes,
    Map<String, dynamic>? params,
  });

  /// Subscribe to specific record changes
  Future<String> subscribeToRecord({
    required String table,
    required String recordId,
    List<String>? columns,
    List<EventType>? eventTypes,
  });

  /// Subscribe to user-specific events
  Future<String> subscribeToUserEvents({
    required String userId,
    required String table,
    String? additionalFilter,
    List<EventType>? eventTypes,
  });

  /// Subscribe to multiple tables
  Future<Map<String, String>> subscribeToMultipleTables({
    required Map<String, SubscriptionConfig> subscriptions,
  });

  /// Custom subscription with advanced filtering
  Future<String> subscribeCustom({
    required String channel,
    required Map<String, dynamic> config,
    List<EventType>? eventTypes,
  });

  /// Unsubscribe operations
  Future<bool> unsubscribe(String subscriptionId);

  Future<void> unsubscribeFromTable(String table);

  Future<void> unsubscribeAll();

  /// Event streams
  Stream<RealTimeEvent> getEventStream(String subscriptionId);

  Stream<RealTimeEvent> getTableEventStream(String table);

  Stream<RealTimeEvent> getAllEventsStream();

  /// Specific social feature subscriptions
  
  /// Friends real-time updates
  Future<String> subscribeFriendRequests(String userId);

  Future<String> subscribeFriendsUpdates(String userId);

  Future<String> subscribeBlockedUsersUpdates(String userId);

  /// Posts real-time updates
  Future<String> subscribeFeedUpdates(String userId);

  Future<String> subscribePostComments(String postId);

  Future<String> subscribePostReactions(String postId);

  Future<String> subscribeUserPosts(String userId);

  /// Chat real-time updates
  Future<String> subscribeMessages(String conversationId);

  Future<String> subscribeConversations(String userId);

  Future<String> subscribeTypingIndicators(String conversationId);

  Future<String> subscribeReadReceipts(String conversationId);

  Future<String> subscribeUnreadCounts(String userId);

  /// Connection health and monitoring
  Future<Map<String, dynamic>> getConnectionInfo();

  Future<List<String>> getActiveSubscriptions();

  Future<Map<String, dynamic>> getSubscriptionInfo(String subscriptionId);

  /// Handle connection drops and reconnection
  void enableAutoReconnect({
    int maxAttempts = 5,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    double backoffMultiplier = 1.5,
  });

  void disableAutoReconnect();

  /// Event queuing for offline scenarios
  void enableOfflineQueuing({
    int maxQueueSize = 1000,
    Duration maxEventAge = const Duration(hours: 24),
  });

  void disableOfflineQueuing();

  Future<void> processQueuedEvents();

  Future<List<QueuedEvent>> getQueuedEvents();

  Future<void> clearEventQueue();

  /// Authentication and authorization
  Future<void> updateAuthHeaders(Map<String, String> headers);

  Future<void> refreshAuthentication();

  /// Error handling and retry logic
  void setErrorHandler(Function(RealTimeDataSourceException) onError);

  void setReconnectHandler(Function(int attempt, Duration delay) onReconnect);

  /// Heartbeat and keep-alive
  void startHeartbeat({Duration interval = const Duration(seconds: 30)});

  void stopHeartbeat();

  /// Performance monitoring
  Future<Map<String, dynamic>> getPerformanceMetrics();

  void enablePerformanceTracking();

  void disablePerformanceTracking();

  /// Cleanup and disposal
  Future<void> dispose();
}

/// Event queue manager for offline scenarios
class EventQueueManager {
  final List<QueuedEvent> _queue = [];
  final int _maxQueueSize;
  final Duration _maxEventAge;
  
  EventQueueManager({
    int maxQueueSize = 1000,
    Duration maxEventAge = const Duration(hours: 24),
  }) : _maxQueueSize = maxQueueSize,
       _maxEventAge = maxEventAge;

  void enqueue(QueuedEvent event) {
    // Remove old events
    _queue.removeWhere((e) => 
        DateTime.now().difference(e.timestamp) > _maxEventAge);

    // Remove oldest events if queue is full
    while (_queue.length >= _maxQueueSize) {
      _queue.removeAt(0);
    }

    _queue.add(event);
  }

  List<QueuedEvent> dequeueAll() {
    final events = List<QueuedEvent>.from(_queue);
    _queue.clear();
    return events;
  }

  List<QueuedEvent> dequeuePending() {
    final now = DateTime.now();
    final pendingEvents = _queue.where((event) => 
        event.nextRetry == null || now.isAfter(event.nextRetry!)).toList();
    
    _queue.removeWhere((event) => pendingEvents.contains(event));
    return pendingEvents;
  }

  void requeueWithBackoff(QueuedEvent event, {
    Duration baseDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(minutes: 5),
  }) {
    final delay = Duration(
      milliseconds: min(
        baseDelay.inMilliseconds * pow(backoffMultiplier, event.retryCount),
        maxDelay.inMilliseconds,
      ).toInt(),
    );

    final updatedEvent = event.copyWith(
      retryCount: event.retryCount + 1,
      nextRetry: DateTime.now().add(delay),
    );

    _queue.add(updatedEvent);
  }

  int get length => _queue.length;

  bool get isEmpty => _queue.isEmpty;

  bool get isNotEmpty => _queue.isNotEmpty;

  void clear() => _queue.clear();

  List<QueuedEvent> get events => List.unmodifiable(_queue);
}

/// Connection health monitor
class ConnectionHealthMonitor {
  final Duration _checkInterval;
  final Function(bool isHealthy) _onHealthChanged;
  Timer? _healthCheckTimer;
  bool _lastHealthState = true;

  ConnectionHealthMonitor({
    Duration checkInterval = const Duration(seconds: 10),
    required Function(bool) onHealthChanged,
  }) : _checkInterval = checkInterval,
       _onHealthChanged = onHealthChanged;

  void start(Future<bool> Function() healthCheck) {
    _healthCheckTimer = Timer.periodic(_checkInterval, (_) async {
      try {
        final isHealthy = await healthCheck();
        if (isHealthy != _lastHealthState) {
          _lastHealthState = isHealthy;
          _onHealthChanged(isHealthy);
        }
      } catch (e) {
        if (_lastHealthState) {
          _lastHealthState = false;
          _onHealthChanged(false);
        }
      }
    });
  }

  void stop() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }
}

/// Performance metrics tracker
class PerformanceMetrics {
  final Map<String, int> _eventCounts = {};
  final Map<String, Duration> _latencies = {};
  final List<DateTime> _connectionEvents = [];
  DateTime? _startTime;

  void start() {
    _startTime = DateTime.now();
    _eventCounts.clear();
    _latencies.clear();
    _connectionEvents.clear();
  }

  void recordEvent(String eventType) {
    _eventCounts[eventType] = (_eventCounts[eventType] ?? 0) + 1;
  }

  void recordLatency(String operation, Duration latency) {
    _latencies[operation] = latency;
  }

  void recordConnectionEvent() {
    _connectionEvents.add(DateTime.now());
  }

  Map<String, dynamic> getMetrics() {
    final now = DateTime.now();
    final uptime = _startTime != null ? now.difference(_startTime!) : Duration.zero;

    return {
      'uptime_seconds': uptime.inSeconds,
      'event_counts': Map.from(_eventCounts),
      'average_latencies_ms': _latencies.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
      'connection_events': _connectionEvents.length,
      'events_per_minute': _eventCounts.values.isEmpty
          ? 0
          : _eventCounts.values.reduce((a, b) => a + b) / 
            max(1, uptime.inMinutes),
    };
  }

  void reset() {
    _eventCounts.clear();
    _latencies.clear();
    _connectionEvents.clear();
    _startTime = DateTime.now();
  }
}
