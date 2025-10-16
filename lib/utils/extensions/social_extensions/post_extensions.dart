import 'dart:math';
import '../../../features/social/data/models/post_model.dart';
import '../../enums/social_enums.dart';
import '../../helpers/social_helpers/engagement_helper.dart';

/// Extension on PostModel for social features
extension PostExtensions on PostModel {
  /// Formats post time in a user-friendly way
  String formatPostTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inSeconds < 30) {
      return 'Just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }
  
  /// Gets share URL with tracking parameters
  String getShareUrl({String? utm_source, String? utm_campaign}) {
    final baseUrl = 'https://dabbler.app/post/$id';
    final params = <String>[];
    
    if (utm_source != null) {
      params.add('utm_source=$utm_source');
    }
    if (utm_campaign != null) {
      params.add('utm_campaign=$utm_campaign');
    }
    
    // Add post tracking
    params.add('shared_at=${DateTime.now().millisecondsSinceEpoch}');
  params.add('post_type=${PostType.media.name}'); // No type field, default to media
    
    if (params.isNotEmpty) {
      return '$baseUrl?${params.join('&')}';
    }
    
    return baseUrl;
  }
  
  /// Checks if user can edit or delete this post
  bool canUserEditOrDelete(String userId) {
    // User can edit their own posts
    if (authorId == userId) return true;
    
    // Moderators can edit/delete posts (would check user roles in real implementation)
    // For now, just check if it's the author
    return false;
  }
  
  /// Gets post preview for notifications (first 100 characters)
  String getPostPreview({int maxLength = 100}) {
    if (content.isEmpty) {
      // If no text content, describe the media
      if (mediaUrls.isNotEmpty) {
        return '📷 Shared a media post';
      }
      return 'Shared a post';
    }
    
    // Clean the content (remove extra whitespace, newlines)
    final cleanContent = content
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    if (cleanContent.length <= maxLength) {
      return cleanContent;
    }
    
    // Find last complete word within limit
    final truncated = cleanContent.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');
    
    if (lastSpace > maxLength * 0.8) { // If we can keep most of the text
      return '${cleanContent.substring(0, lastSpace)}...';
    }
    
    return '$truncated...';
  }
  
  /// Extracts all mentions from content (@username)
  List<String> extractMentions() {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(content);
    
    return matches
        .map((match) => match.group(1)!)
        .toSet() // Remove duplicates
        .toList();
  }
  
  /// Extracts all hashtags from content (#hashtag)
  List<String> extractHashtags() {
    final hashtagRegex = RegExp(r'#(\w+)');
    final matches = hashtagRegex.allMatches(content);
    
    return matches
        .map((match) => match.group(1)!)
        .toSet() // Remove duplicates
        .toList();
  }
  
  /// Calculates estimated read time in minutes
  int calculateReadTime() {
    if (content.isEmpty) return 1;
    
    // Average reading speed is 200-250 words per minute
    const wordsPerMinute = 225;
    final wordCount = content.split(RegExp(r'\s+')).length;
    
    // Add time for media content
    int mediaTime = 0;
    if (mediaUrls.isNotEmpty) {
      mediaTime = 15; // Assume 15 seconds per media item
    }
    
    final readTimeSeconds = (wordCount / wordsPerMinute * 60) + mediaTime;
    final readTimeMinutes = (readTimeSeconds / 60).ceil();
    
    return max(1, readTimeMinutes); // Minimum 1 minute
  }
  
  /// Gets media preview URLs (thumbnails for images/videos)
  List<String> getMediaPreviewUrls() {
    final previews = <String>[];
    
    for (final mediaUrl in mediaUrls) {
      previews.add(mediaUrl);
    }
    
    return previews;
  }
  
  /// Checks if post is considered viral based on engagement
  bool isViral({double threshold = 1.0}) {
    final viralData = EngagementHelper.calculateViralCoefficient(this);
    return viralData.coefficient >= threshold;
  }
  
  /// Formats engagement count for display (1.2K likes, 500 comments)
  Map<String, String> getFormattedEngagementCounts() {
    return {
      'likes': EngagementHelper.formatEngagementCount(likesCount),
      'comments': EngagementHelper.formatEngagementCount(commentsCount),
      'shares': EngagementHelper.formatEngagementCount(sharesCount),
  'views': '0', // No viewsCount field in PostModel
    };
  }
  
  /// Gets engagement rate percentage
  double getEngagementRate() {
    return EngagementHelper.calculateEngagementRate(this);
  }
  
  /// Checks if post contains sensitive content
  bool hasSensitiveContent() {
    // Would use content moderation in real implementation
    final sensitiveWords = [
      'violence', 'explicit', 'nsfw', 'sensitive', 'warning'
    ];
    
    final lowerContent = content.toLowerCase();
    return sensitiveWords.any((word) => lowerContent.contains(word));
  }
  
  /// Gets content warnings if any
  List<String> getContentWarnings() {
    final warnings = <String>[];
    
    if (hasSensitiveContent()) {
      warnings.add('Sensitive Content');
    }
    
    if (content.length > 2000) {
      warnings.add('Long Read');
    }
    
    // Would check for other content issues in real implementation
    return warnings;
  }
  
  /// Gets post sentiment score (-1 to 1, negative to positive)
  double getSentimentScore() {
    // Simplified sentiment analysis
    final positiveWords = [
      'good', 'great', 'amazing', 'awesome', 'fantastic', 'excellent',
      'wonderful', 'perfect', 'love', 'happy', 'joy', 'best', 'beautiful'
    ];
    
    final negativeWords = [
      'bad', 'terrible', 'awful', 'horrible', 'hate', 'sad', 'angry',
      'worst', 'ugly', 'disgusting', 'disappointed', 'frustrated'
    ];
    
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in words) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    final totalSentimentWords = positiveCount + negativeCount;
    if (totalSentimentWords == 0) return 0.0; // Neutral
    
    return (positiveCount - negativeCount) / totalSentimentWords;
  }
  
  /// Checks if post is trending (high recent engagement)
  bool isTrending({Duration? timeWindow}) {
    timeWindow ??= const Duration(hours: 24);
    
    final postAge = DateTime.now().difference(createdAt);
    if (postAge > timeWindow) return false;
    
    // Simple trending logic: high engagement rate + recent
    final engagementRate = getEngagementRate();
    const trendingThreshold = 5.0; // 5% engagement rate
    
    return engagementRate >= trendingThreshold;
  }
  
  /// Gets post performance score (0-100)
  int getPerformanceScore() {
    double score = 0.0;
    
    // Engagement rate (0-40 points)
    final engagementRate = getEngagementRate();
    score += (engagementRate * 4).clamp(0.0, 40.0);
    
    // Reach/views (0-30 points)
  // No viewsCount field, skip viewScore
    
    // Shares bonus (0-20 points)
  final shareScore = (sharesCount * 2.0).clamp(0.0, 20.0);
  score += shareScore;
    
    // Recency bonus (0-10 points)
  final postAge = DateTime.now().difference(createdAt);
  final recencyScore = max(0, 10 - postAge.inDays).toDouble();
  score += recencyScore;
    
    return score.clamp(0.0, 100.0).round();
  }
  
  /// Gets related hashtag suggestions based on content
  List<String> getSuggestedHashtags() {
    final suggestions = <String>[];
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    
    // Sport-related keywords
    final sportsKeywords = {
      'football': ['football', 'soccer', 'sports'],
      'basketball': ['basketball', 'nba', 'sports'],
      'tennis': ['tennis', 'sports'],
      'running': ['running', 'marathon', 'fitness'],
      'gym': ['gym', 'fitness', 'workout'],
      'workout': ['workout', 'fitness', 'training'],
    };
    
    // Technology keywords
    final techKeywords = {
      'coding': ['coding', 'programming', 'developer'],
      'ai': ['ai', 'artificial intelligence', 'tech'],
      'mobile': ['mobile', 'app', 'tech'],
    };
    
    // Check for keyword matches
    for (final word in words) {
      sportsKeywords.forEach((key, tags) {
        if (word.contains(key)) {
          suggestions.addAll(tags);
        }
      });
      
      techKeywords.forEach((key, tags) {
        if (word.contains(key)) {
          suggestions.addAll(tags);
        }
      });
    }
    
    // Remove duplicates and existing hashtags
    final existing = extractHashtags().map((h) => h.toLowerCase()).toSet();
    final unique = suggestions.toSet()
        .where((tag) => !existing.contains(tag.toLowerCase()))
        .take(5)
        .toList();
    
    return unique;
  }
  
  /// Checks if user has liked this post
  bool hasUserLiked(String userId) {
    // Would check likes table in real implementation
    // For now, return false as we don't have likes data
    return false;
  }
  
  /// Gets optimal repost time based on original post performance
  DateTime? getOptimalRepostTime() {
    final postAge = DateTime.now().difference(createdAt);
    
    // Don't suggest reposting very recent posts
    if (postAge.inDays < 7) return null;
    
    // Don't suggest reposting low-performing posts
    if (getEngagementRate() < 1.0) return null;
    
    // Suggest reposting in 1-3 months for good content
    final randomDays = Random().nextInt(60) + 30; // 30-90 days
    return DateTime.now().add(Duration(days: randomDays));
  }
  
  /// Gets post accessibility score (how accessible the content is)
  double getAccessibilityScore() {
    double score = 1.0; // Start with perfect score
    
    // Check if images have alt text (would be in metadata)
  // Accessibility checks not implemented (no type/metadata fields)
  return score.clamp(0.0, 1.0);
  }
}
