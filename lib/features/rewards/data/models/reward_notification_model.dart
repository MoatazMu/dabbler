/// Types of reward celebrations
enum CelebrationType {
  /// Simple badge unlock notification
  badgeUnlock,
  /// Achievement completion celebration
  achievementComplete,
  /// Tier promotion celebration
  tierPromotion,
  /// Leaderboard position milestone
  leaderboardMilestone,
  /// Special event reward
  specialEvent,
  /// Streak milestone celebration
  streakMilestone,
  /// Points milestone reached
  pointsMilestone,
  /// Rare badge collection
  rareBadge,
}

/// Animation styles for notifications
enum NotificationAnimation {
  /// No animation
  none,
  /// Simple slide in/out
  slide,
  /// Fade in/out
  fade,
  /// Bounce effect
  bounce,
  /// Scale animation
  scale,
  /// Confetti celebration
  confetti,
  /// Fireworks animation
  fireworks,
  /// Particles effect
  particles,
}

/// Display duration presets
enum DisplayDuration {
  /// 2 seconds
  short,
  /// 5 seconds
  medium,
  /// 10 seconds
  long,
  /// Manual dismissal required
  persistent,
  /// Auto-dismiss based on content
  adaptive,
}

/// Share options for achievements
enum ShareOption {
  /// Share via social media
  social,
  /// Share to game feed
  gameFeed,
  /// Share to friends
  friends,
  /// Generate shareable link
  link,
  /// Save achievement image
  saveImage,
  /// Copy achievement text
  copyText,
}

/// Sound effects for notifications
enum NotificationSound {
  /// No sound
  none,
  /// Simple notification beep
  beep,
  /// Success chime
  success,
  /// Achievement fanfare
  fanfare,
  /// Level up sound
  levelUp,
  /// Rare item sound
  rare,
  /// Epic achievement sound
  epic,
  /// Victory celebration
  victory,
}

/// Data model for reward notifications
class RewardNotificationModel {
  final String id;
  final String userId;
  final String? achievementId;
  final String? badgeId;
  final String? tierId;
  final CelebrationType type;
  final String title;
  final String message;
  final String? subtitle;
  final String? iconUrl;
  final String? imageUrl;
  final Map<String, dynamic> celebrationData;
  final NotificationAnimation animation;
  final DisplayDuration duration;
  final NotificationSound sound;
  final List<ShareOption> shareOptions;
  final Map<String, dynamic> animationSettings;
  final Map<String, dynamic> displaySettings;
  final bool isRead;
  final bool isShared;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? sharedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  const RewardNotificationModel({
    required this.id,
    required this.userId,
    this.achievementId,
    this.badgeId,
    this.tierId,
    required this.type,
    required this.title,
    required this.message,
    this.subtitle,
    this.iconUrl,
    this.imageUrl,
    this.celebrationData = const {},
    this.animation = NotificationAnimation.slide,
    this.duration = DisplayDuration.medium,
    this.sound = NotificationSound.success,
    this.shareOptions = const [],
    this.animationSettings = const {},
    this.displaySettings = const {},
    this.isRead = false,
    this.isShared = false,
    required this.createdAt,
    this.readAt,
    this.sharedAt,
    this.expiresAt,
    this.metadata = const {},
  });

  /// Creates a RewardNotificationModel from JSON
  factory RewardNotificationModel.fromJson(Map<String, dynamic> json) {
    return RewardNotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String?,
      badgeId: json['badge_id'] as String?,
      tierId: json['tier_id'] as String?,
      type: _parseCelebrationType(json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
      subtitle: json['subtitle'] as String?,
      iconUrl: json['icon_url'] as String?,
      imageUrl: json['image_url'] as String?,
      celebrationData: _parseMap(json['celebration_data']),
      animation: _parseNotificationAnimation(json['animation']),
      duration: _parseDisplayDuration(json['duration']),
      sound: _parseNotificationSound(json['sound']),
      shareOptions: _parseShareOptions(json['share_options']),
      animationSettings: _parseMap(json['animation_settings']),
      displaySettings: _parseMap(json['display_settings']),
      isRead: json['is_read'] as bool? ?? false,
      isShared: json['is_shared'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      readAt: _parseDateTime(json['read_at']),
      sharedAt: _parseDateTime(json['shared_at']),
      expiresAt: _parseDateTime(json['expires_at']),
      metadata: _parseMap(json['metadata']),
    );
  }

  /// Converts the model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'badge_id': badgeId,
      'tier_id': tierId,
      'type': type.name,
      'title': title,
      'message': message,
      'subtitle': subtitle,
      'icon_url': iconUrl,
      'image_url': imageUrl,
      'celebration_data': celebrationData,
      'animation': animation.name,
      'duration': duration.name,
      'sound': sound.name,
      'share_options': shareOptions.map((option) => option.name).toList(),
      'animation_settings': animationSettings,
      'display_settings': displaySettings,
      'is_read': isRead,
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'shared_at': sharedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Static parsing methods

  static CelebrationType _parseCelebrationType(dynamic value) {
    if (value == null) return CelebrationType.badgeUnlock;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'badge_unlock':
        case 'badgeunlock':
          return CelebrationType.badgeUnlock;
        case 'achievement_complete':
        case 'achievementcomplete':
          return CelebrationType.achievementComplete;
        case 'tier_promotion':
        case 'tierpromotion':
          return CelebrationType.tierPromotion;
        case 'leaderboard_milestone':
        case 'leaderboardmilestone':
          return CelebrationType.leaderboardMilestone;
        case 'special_event':
        case 'specialevent':
          return CelebrationType.specialEvent;
        case 'streak_milestone':
        case 'streakmilestone':
          return CelebrationType.streakMilestone;
        case 'points_milestone':
        case 'pointsmilestone':
          return CelebrationType.pointsMilestone;
        case 'rare_badge':
        case 'rarebadge':
          return CelebrationType.rareBadge;
        default:
          return CelebrationType.badgeUnlock;
      }
    }
    
    return CelebrationType.badgeUnlock;
  }

  static NotificationAnimation _parseNotificationAnimation(dynamic value) {
    if (value == null) return NotificationAnimation.slide;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'none':
          return NotificationAnimation.none;
        case 'slide':
          return NotificationAnimation.slide;
        case 'fade':
          return NotificationAnimation.fade;
        case 'bounce':
          return NotificationAnimation.bounce;
        case 'scale':
          return NotificationAnimation.scale;
        case 'confetti':
          return NotificationAnimation.confetti;
        case 'fireworks':
          return NotificationAnimation.fireworks;
        case 'particles':
          return NotificationAnimation.particles;
        default:
          return NotificationAnimation.slide;
      }
    }
    
    return NotificationAnimation.slide;
  }

  static DisplayDuration _parseDisplayDuration(dynamic value) {
    if (value == null) return DisplayDuration.medium;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'short':
          return DisplayDuration.short;
        case 'medium':
          return DisplayDuration.medium;
        case 'long':
          return DisplayDuration.long;
        case 'persistent':
          return DisplayDuration.persistent;
        case 'adaptive':
          return DisplayDuration.adaptive;
        default:
          return DisplayDuration.medium;
      }
    }
    
    return DisplayDuration.medium;
  }

  static NotificationSound _parseNotificationSound(dynamic value) {
    if (value == null) return NotificationSound.success;
    
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'none':
          return NotificationSound.none;
        case 'beep':
          return NotificationSound.beep;
        case 'success':
          return NotificationSound.success;
        case 'fanfare':
          return NotificationSound.fanfare;
        case 'level_up':
        case 'levelup':
          return NotificationSound.levelUp;
        case 'rare':
          return NotificationSound.rare;
        case 'epic':
          return NotificationSound.epic;
        case 'victory':
          return NotificationSound.victory;
        default:
          return NotificationSound.success;
      }
    }
    
    return NotificationSound.success;
  }

  static List<ShareOption> _parseShareOptions(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value
          .map((item) => _parseShareOption(item))
          .where((option) => option != null)
          .cast<ShareOption>()
          .toList();
    }
    
    return [];
  }

  static ShareOption? _parseShareOption(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'social':
          return ShareOption.social;
        case 'game_feed':
        case 'gamefeed':
          return ShareOption.gameFeed;
        case 'friends':
          return ShareOption.friends;
        case 'link':
          return ShareOption.link;
        case 'save_image':
        case 'saveimage':
          return ShareOption.saveImage;
        case 'copy_text':
        case 'copytext':
          return ShareOption.copyText;
      }
    }
    return null;
  }

  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is DateTime) return value;
    return null;
  }

  /// Creates a copy with updated values
  RewardNotificationModel copyWith({
    String? id,
    String? userId,
    String? achievementId,
    String? badgeId,
    String? tierId,
    CelebrationType? type,
    String? title,
    String? message,
    String? subtitle,
    String? iconUrl,
    String? imageUrl,
    Map<String, dynamic>? celebrationData,
    NotificationAnimation? animation,
    DisplayDuration? duration,
    NotificationSound? sound,
    List<ShareOption>? shareOptions,
    Map<String, dynamic>? animationSettings,
    Map<String, dynamic>? displaySettings,
    bool? isRead,
    bool? isShared,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? sharedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return RewardNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      badgeId: badgeId ?? this.badgeId,
      tierId: tierId ?? this.tierId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      subtitle: subtitle ?? this.subtitle,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      celebrationData: celebrationData ?? this.celebrationData,
      animation: animation ?? this.animation,
      duration: duration ?? this.duration,
      sound: sound ?? this.sound,
      shareOptions: shareOptions ?? this.shareOptions,
      animationSettings: animationSettings ?? this.animationSettings,
      displaySettings: displaySettings ?? this.displaySettings,
      isRead: isRead ?? this.isRead,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      sharedAt: sharedAt ?? this.sharedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a RewardNotificationModel from Supabase row
  factory RewardNotificationModel.fromSupabase(Map<String, dynamic> data) {
    return RewardNotificationModel.fromJson({
      ...data,
      'user_id': data['user_id'] ?? data['userId'],
      'achievement_id': data['achievement_id'] ?? data['achievementId'],
      'badge_id': data['badge_id'] ?? data['badgeId'],
      'tier_id': data['tier_id'] ?? data['tierId'],
      'icon_url': data['icon_url'] ?? data['iconUrl'],
      'image_url': data['image_url'] ?? data['imageUrl'],
      'celebration_data': data['celebration_data'] ?? data['celebrationData'],
      'animation_settings': data['animation_settings'] ?? data['animationSettings'],
      'display_settings': data['display_settings'] ?? data['displaySettings'],
      'is_read': data['is_read'] ?? data['isRead'],
      'is_shared': data['is_shared'] ?? data['isShared'],
      'created_at': data['created_at'] ?? data['createdAt'],
      'read_at': data['read_at'] ?? data['readAt'],
      'shared_at': data['shared_at'] ?? data['sharedAt'],
      'expires_at': data['expires_at'] ?? data['expiresAt'],
      'share_options': data['share_options'] ?? data['shareOptions'],
    });
  }

  /// Converts to format suitable for Supabase insertion
  Map<String, dynamic> toSupabase() {
    final json = toJson();
    json.removeWhere((key, value) => value == null);
    
    return {
      ...json,
      'user_id': json['user_id'],
      'achievement_id': json['achievement_id'],
      'badge_id': json['badge_id'],
      'tier_id': json['tier_id'],
      'icon_url': json['icon_url'],
      'image_url': json['image_url'],
      'celebration_data': json['celebration_data'],
      'animation_settings': json['animation_settings'],
      'display_settings': json['display_settings'],
      'is_read': json['is_read'],
      'is_shared': json['is_shared'],
      'created_at': json['created_at'],
      'read_at': json['read_at'],
      'shared_at': json['shared_at'],
      'expires_at': json['expires_at'],
      'share_options': json['share_options'],
    };
  }

  /// Creates a mock RewardNotificationModel for testing
  factory RewardNotificationModel.mock({
    String? id,
    String? userId,
    CelebrationType type = CelebrationType.badgeUnlock,
    String? title,
    String? message,
    NotificationAnimation animation = NotificationAnimation.slide,
  }) {
    return RewardNotificationModel(
      id: id ?? 'mock_notification',
      userId: userId ?? 'mock_user',
      type: type,
      title: title ?? 'Achievement Unlocked!',
      message: message ?? 'You\'ve earned a new badge!',
      animation: animation,
      createdAt: DateTime.now(),
    );
  }

  /// Gets the display duration in milliseconds
  int getDurationInMilliseconds() {
    switch (duration) {
      case DisplayDuration.short:
        return 2000;
      case DisplayDuration.medium:
        return 5000;
      case DisplayDuration.long:
        return 10000;
      case DisplayDuration.persistent:
        return -1; // Indicates manual dismissal
      case DisplayDuration.adaptive:
        return _calculateAdaptiveDuration();
    }
  }

  int _calculateAdaptiveDuration() {
    // Base duration on content length and type
    int baseDuration = 3000; // 3 seconds base
    
    // Add time based on content length
    final contentLength = title.length + message.length + (subtitle?.length ?? 0);
    baseDuration += (contentLength / 10).round() * 100;
    
    // Adjust based on celebration type
    switch (type) {
      case CelebrationType.tierPromotion:
      case CelebrationType.rareBadge:
        baseDuration += 2000; // Extra time for important celebrations
        break;
      case CelebrationType.specialEvent:
        baseDuration += 1500;
        break;
      case CelebrationType.achievementComplete:
        baseDuration += 1000;
        break;
      default:
        break;
    }
    
    // Cap at reasonable limits
    return baseDuration.clamp(2000, 15000);
  }

  /// Gets the celebration priority (higher = more important)
  int getCelebrationPriority() {
    switch (type) {
      case CelebrationType.tierPromotion:
        return 100;
      case CelebrationType.rareBadge:
        return 90;
      case CelebrationType.leaderboardMilestone:
        return 80;
      case CelebrationType.specialEvent:
        return 70;
      case CelebrationType.pointsMilestone:
        return 60;
      case CelebrationType.streakMilestone:
        return 50;
      case CelebrationType.achievementComplete:
        return 40;
      case CelebrationType.badgeUnlock:
        return 30;
    }
  }

  /// Checks if the notification has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Checks if this is a high-priority notification
  bool get isHighPriority {
    return getCelebrationPriority() >= 70;
  }

  /// Gets the animation configuration
  Map<String, dynamic> getAnimationConfig() {
    final baseConfig = {
      'type': animation.name,
      'duration': _getAnimationDuration(),
      'easing': _getAnimationEasing(),
    };
    
    // Merge with custom animation settings
    return {...baseConfig, ...animationSettings};
  }

  int _getAnimationDuration() {
    switch (animation) {
      case NotificationAnimation.none:
        return 0;
      case NotificationAnimation.slide:
        return 300;
      case NotificationAnimation.fade:
        return 400;
      case NotificationAnimation.bounce:
        return 600;
      case NotificationAnimation.scale:
        return 350;
      case NotificationAnimation.confetti:
        return 2000;
      case NotificationAnimation.fireworks:
        return 3000;
      case NotificationAnimation.particles:
        return 1500;
    }
  }

  String _getAnimationEasing() {
    switch (animation) {
      case NotificationAnimation.bounce:
        return 'easeOutBounce';
      case NotificationAnimation.scale:
        return 'easeOutBack';
      case NotificationAnimation.slide:
        return 'easeOutCubic';
      default:
        return 'easeInOut';
    }
  }

  /// Gets share configuration
  Map<String, dynamic> getShareConfig() {
    return {
      'options': shareOptions.map((option) => option.name).toList(),
      'title': title,
      'message': message,
      'image_url': imageUrl,
      'share_text': getShareText(),
      'hashtags': _getShareHashtags(),
    };
  }

  String getShareText() {
    switch (type) {
      case CelebrationType.tierPromotion:
        return 'Just reached a new tier in Dabbler! 🎉 $title';
      case CelebrationType.rareBadge:
        return 'Unlocked a rare badge in Dabbler! ⭐ $title';
      case CelebrationType.achievementComplete:
        return 'Achievement unlocked in Dabbler! 🏆 $title';
      case CelebrationType.leaderboardMilestone:
        return 'Climbing the leaderboards in Dabbler! 📈 $title';
      default:
        return 'New milestone in Dabbler! 🎮 $title';
    }
  }

  List<String> _getShareHashtags() {
    final hashtags = ['#Dabbler', '#Gaming'];
    
    switch (type) {
      case CelebrationType.tierPromotion:
        hashtags.addAll(['#LevelUp', '#Achievement']);
        break;
      case CelebrationType.rareBadge:
        hashtags.addAll(['#RareBadge', '#Collector']);
        break;
      case CelebrationType.leaderboardMilestone:
        hashtags.addAll(['#Leaderboard', '#TopPlayer']);
        break;
      case CelebrationType.specialEvent:
        hashtags.addAll(['#SpecialEvent', '#Limited']);
        break;
      default:
        hashtags.add('#Achievement');
    }
    
    return hashtags;
  }

  /// Marks the notification as read
  RewardNotificationModel markAsRead() {
    if (isRead) return this;
    
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Marks the notification as shared
  RewardNotificationModel markAsShared() {
    if (isShared) return this;
    
    return copyWith(
      isShared: true,
      sharedAt: DateTime.now(),
    );
  }

  /// Gets notification summary for display
  Map<String, dynamic> getSummary() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'is_read': isRead,
      'is_shared': isShared,
      'is_expired': isExpired,
      'is_high_priority': isHighPriority,
      'priority_score': getCelebrationPriority(),
      'duration_ms': getDurationInMilliseconds(),
      'animation': animation.name,
      'sound': sound.name,
      'created_at': createdAt.toIso8601String(),
      'share_options': shareOptions.map((o) => o.name).toList(),
    };
  }

  @override
  String toString() {
    return 'RewardNotificationModel(id: $id, type: $type, title: $title, '
           'isRead: $isRead, priority: ${getCelebrationPriority()})';
  }
}