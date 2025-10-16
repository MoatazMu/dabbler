import 'social_constants.dart';
import 'social_helpers.dart';

/// Helper functions for chat and messaging features
class ChatHelpers {
  /// Group messages by date for display
  static Map<DateTime, List<T>> groupMessagesByDate<T>(
    List<T> messages,
    DateTime Function(T) getDate,
  ) {
    final grouped = <DateTime, List<T>>{};
    
    for (final message in messages) {
      final messageDate = getDate(message);
      final dateKey = DateTime(messageDate.year, messageDate.month, messageDate.day);
      
      grouped.putIfAbsent(dateKey, () => []).add(message);
    }
    
    return grouped;
  }

  /// Format message time for display (9:30 AM, Yesterday, etc.)
  static String formatMessageTime(DateTime messageTime, {bool showFullDate = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);
    
    if (showFullDate) {
      return '${_formatTime(messageTime)} • ${_formatDate(messageTime)}';
    }
    
    if (messageDate == today) {
      return _formatTime(messageTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${_formatTime(messageTime)}';
    } else if (now.difference(messageTime).inDays < 7) {
      return '${_getDayName(messageTime.weekday)} ${_formatTime(messageTime)}';
    } else {
      return _formatDate(messageTime);
    }
  }

  /// Check if message timestamp should be shown (based on time gap)
  static bool shouldShowTimestamp(DateTime currentMessage, DateTime? previousMessage) {
    if (previousMessage == null) return true;
    
    final timeDifference = currentMessage.difference(previousMessage);
    return timeDifference.inMinutes >= 5; // Show timestamp if 5+ minutes apart
  }

  /// Generate conversation title based on participants
  static String generateConversationTitle(List<String> participantNames, {String? currentUserName}) {
    if (participantNames.isEmpty) return 'Empty Chat';
    
    // Remove current user from the list for title generation
    final otherParticipants = currentUserName != null 
        ? participantNames.where((name) => name != currentUserName).toList()
        : participantNames;
    
    if (otherParticipants.isEmpty) return 'You';
    if (otherParticipants.length == 1) return otherParticipants.first;
    if (otherParticipants.length == 2) return '${otherParticipants[0]}, ${otherParticipants[1]}';
    
    // For group chats with 3+ people
    return '${otherParticipants.first}, ${otherParticipants[1]} +${otherParticipants.length - 2}';
  }

  /// Calculate unread message counts for conversations
  static Map<String, int> calculateUnreadCounts(
    List<ConversationData> conversations,
    String currentUserId,
  ) {
    final unreadCounts = <String, int>{};
    
    for (final conversation in conversations) {
      var unreadCount = 0;
      
      for (final message in conversation.messages.reversed) {
        if (message.senderId == currentUserId) break; // Stop at first message from current user
        if (!message.readBy.contains(currentUserId)) {
          unreadCount++;
        } else {
          break; // Stop at first read message
        }
      }
      
      unreadCounts[conversation.id] = unreadCount;
    }
    
    return unreadCounts;
  }

  /// Format typing indicator text
  static String formatTypingIndicator(List<String> typingUsers, {String? currentUserName}) {
    final otherTyping = currentUserName != null 
        ? typingUsers.where((name) => name != currentUserName).toList()
        : typingUsers;
    
    if (otherTyping.isEmpty) return '';
    
    if (otherTyping.length == 1) {
      return '${otherTyping.first} is typing...';
    } else if (otherTyping.length == 2) {
      return '${otherTyping[0]} and ${otherTyping[1]} are typing...';
    } else {
      return '${otherTyping.length} people are typing...';
    }
  }

  /// Generate message preview for conversation list
  static String generateMessagePreview(String content, String messageType, {int maxLength = 50}) {
    String preview;
    
    switch (messageType.toLowerCase()) {
      case SocialConstants.contentTypeImage:
        preview = '📷 Photo';
        break;
      case SocialConstants.contentTypeVideo:
        preview = '🎥 Video';
        break;
      case SocialConstants.contentTypeAudio:
        preview = '🎵 Audio';
        break;
      case SocialConstants.contentTypeDocument:
        preview = '📄 Document';
        break;
      case SocialConstants.contentTypeLocation:
        preview = '📍 Location';
        break;
      case SocialConstants.contentTypePoll:
        preview = '📊 Poll';
        break;
      default:
        preview = content;
    }
    
    return SocialHelpers.generateContentPreview(preview, maxLength: maxLength);
  }

  /// Check if messages should be grouped together (same sender, close time)
  static bool shouldGroupMessages(
    String currentSender,
    DateTime currentTime,
    String? previousSender,
    DateTime? previousTime,
  ) {
    if (previousSender == null || previousTime == null) return false;
    if (currentSender != previousSender) return false;
    
    final timeDifference = currentTime.difference(previousTime);
    return timeDifference.inMinutes < 2; // Group if less than 2 minutes apart
  }

  /// Generate delivery status text
  static String formatDeliveryStatus(MessageDeliveryStatus status, List<String> readBy) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return 'Sending...';
      case MessageDeliveryStatus.sent:
        return 'Sent';
      case MessageDeliveryStatus.delivered:
        return 'Delivered';
      case MessageDeliveryStatus.read:
        if (readBy.length == 1) return 'Read';
        return 'Read by ${readBy.length}';
      case MessageDeliveryStatus.failed:
        return 'Failed to send';
    }
  }

  /// Calculate conversation activity score
  static double calculateActivityScore(List<MessageData> messages, Duration timeWindow) {
    final cutoff = DateTime.now().subtract(timeWindow);
    final recentMessages = messages.where((m) => m.timestamp.isAfter(cutoff)).length;
    
    // Score based on message frequency
    final hoursInWindow = timeWindow.inHours;
    return recentMessages / hoursInWindow;
  }

  /// Get suggested quick replies based on message content
  static List<String> getSuggestedReplies(String messageContent, String messageType) {
    final content = messageContent.toLowerCase();
    
    // Question detection
    if (content.contains('?') || content.startsWith('how') || content.startsWith('what') || 
        content.startsWith('when') || content.startsWith('where') || content.startsWith('why')) {
      return ['Sure!', 'Let me check', 'Not sure', 'Maybe later'];
    }
    
    // Greeting detection
    if (content.contains('hello') || content.contains('hi') || content.contains('hey')) {
      return ['Hi there!', 'Hello!', 'Hey! 👋', 'Good to hear from you'];
    }
    
    // Thanks detection
    if (content.contains('thank') || content.contains('thanks')) {
      return ['You\'re welcome!', 'No problem!', 'Anytime! 😊', 'Glad to help'];
    }
    
    // Media messages
    if (messageType == SocialConstants.contentTypeImage) {
      return ['Nice pic! 👍', 'Love it!', 'Cool!', 'Where was this?'];
    }
    
    // Default replies
    return ['👍', '😊', 'Okay', 'Sure', 'Thanks'];
  }

  /// Format message search results
  static List<MessageSearchResult> formatSearchResults(
    List<MessageData> messages,
    String query,
  ) {
    final results = <MessageSearchResult>[];
    final queryLower = query.toLowerCase();
    
    for (final message in messages) {
      final contentLower = message.content.toLowerCase();
      final index = contentLower.indexOf(queryLower);
      
      if (index != -1) {
        // Extract context around the match
        const contextLength = 30;
        final start = (index - contextLength).clamp(0, message.content.length);
        final end = (index + query.length + contextLength).clamp(0, message.content.length);
        
        String contextBefore = message.content.substring(start, index);
        String matchedText = message.content.substring(index, index + query.length);
        String contextAfter = message.content.substring(index + query.length, end);
        
        if (start > 0) contextBefore = '...$contextBefore';
        if (end < message.content.length) contextAfter = '$contextAfter...';
        
        results.add(MessageSearchResult(
          message: message,
          contextBefore: contextBefore,
          matchedText: matchedText,
          contextAfter: contextAfter,
          relevanceScore: _calculateRelevanceScore(message.content, query),
        ));
      }
    }
    
    // Sort by relevance and recency
    results.sort((a, b) {
      final scoreComparison = b.relevanceScore.compareTo(a.relevanceScore);
      if (scoreComparison != 0) return scoreComparison;
      return b.message.timestamp.compareTo(a.message.timestamp);
    });
    
    return results;
  }

  // Private helper methods
  static String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static double _calculateRelevanceScore(String content, String query) {
    final contentLower = content.toLowerCase();
    final queryLower = query.toLowerCase();
    
    // Exact match gets highest score
    if (contentLower == queryLower) return 100.0;
    
    // Word boundary matches get high scores
    if (RegExp(r'\b' + RegExp.escape(queryLower) + r'\b').hasMatch(contentLower)) {
      return 90.0;
    }
    
    // Start of content match
    if (contentLower.startsWith(queryLower)) return 80.0;
    
    // Contains match
    if (contentLower.contains(queryLower)) return 70.0;
    
    return 0.0;
  }
}

/// Data classes for chat helpers
class ConversationData {
  final String id;
  final List<MessageData> messages;
  final List<String> participantIds;
  final DateTime lastActivity;

  const ConversationData({
    required this.id,
    required this.messages,
    required this.participantIds,
    required this.lastActivity,
  });
}

class MessageData {
  final String id;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime timestamp;
  final List<String> readBy;
  final MessageDeliveryStatus deliveryStatus;

  const MessageData({
    required this.id,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.timestamp,
    required this.readBy,
    required this.deliveryStatus,
  });
}

class MessageSearchResult {
  final MessageData message;
  final String contextBefore;
  final String matchedText;
  final String contextAfter;
  final double relevanceScore;

  const MessageSearchResult({
    required this.message,
    required this.contextBefore,
    required this.matchedText,
    required this.contextAfter,
    required this.relevanceScore,
  });
}

enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
