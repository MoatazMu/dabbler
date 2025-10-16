/// Enum defining different types of user activities that can become posts
enum PostActivityType {
  originalPost,    // Regular user post
  comment,         // Comment on another post
  venueRating,     // Rating a venue
  gameCreation,    // Creating a game
  checkIn,         // Check-in to location
  venueBooking,    // Booking a venue
  gameJoin,        // Joining a game
  achievement,     // User achievement
}

/// Privacy levels for posts
enum PostPrivacy {
  public,          // Everyone can see
  friends,         // Friends only
  thread,          // Only people in the thread/conversation
}

/// Extension methods for PostActivityType
extension PostActivityTypeExtension on PostActivityType {
  String get name {
    switch (this) {
      case PostActivityType.originalPost:
        return 'originalPost';
      case PostActivityType.comment:
        return 'comment';
      case PostActivityType.venueRating:
        return 'venueRating';
      case PostActivityType.gameCreation:
        return 'gameCreation';
      case PostActivityType.checkIn:
        return 'checkIn';
      case PostActivityType.venueBooking:
        return 'venueBooking';
      case PostActivityType.gameJoin:
        return 'gameJoin';
      case PostActivityType.achievement:
        return 'achievement';
    }
  }

  static PostActivityType fromString(String value) {
    switch (value) {
      case 'originalPost':
        return PostActivityType.originalPost;
      case 'comment':
        return PostActivityType.comment;
      case 'venueRating':
        return PostActivityType.venueRating;
      case 'gameCreation':
        return PostActivityType.gameCreation;
      case 'checkIn':
        return PostActivityType.checkIn;
      case 'venueBooking':
        return PostActivityType.venueBooking;
      case 'gameJoin':
        return PostActivityType.gameJoin;
      case 'achievement':
        return PostActivityType.achievement;
      default:
        return PostActivityType.originalPost;
    }
  }
}

/// Extension methods for PostPrivacy
extension PostPrivacyExtension on PostPrivacy {
  String get name {
    switch (this) {
      case PostPrivacy.public:
        return 'public';
      case PostPrivacy.friends:
        return 'friends';
      case PostPrivacy.thread:
        return 'thread';
    }
  }

  static PostPrivacy fromString(String value) {
    switch (value) {
      case 'public':
        return PostPrivacy.public;
      case 'friends':
        return PostPrivacy.friends;
      case 'thread':
        return PostPrivacy.thread;
      default:
        return PostPrivacy.public;
    }
  }
}
