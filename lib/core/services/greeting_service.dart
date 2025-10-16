import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';

class GreetingService {
  static final GreetingService _instance = GreetingService._internal();
  factory GreetingService({UserService? userService}) {
    if (userService != null) {
      _instance._userService = userService;
    }
    return _instance;
  }
  GreetingService._internal();

  UserService _userService = UserService();

  // English greetings
  static const Map<String, Map<String, String>> _englishGreetings = {
    'morning': {
      'formal': 'Good morning',
      'casual': 'Good morning',
      'friendly': 'Good morning',
      'energetic': 'Rise and shine',
    },
    'afternoon': {
      'formal': 'Good afternoon',
      'casual': 'Good afternoon',
      'friendly': 'Good afternoon',
      'energetic': 'Hey there',
    },
    'evening': {
      'formal': 'Good evening',
      'casual': 'Good evening',
      'friendly': 'Good evening',
      'energetic': 'Hey',
    },
    'night': {
      'formal': 'Good evening',
      'casual': 'Good evening',
      'friendly': 'Good evening',
      'energetic': 'Hey',
    },
  };

  // Arabic greetings
  static const Map<String, Map<String, String>> _arabicGreetings = {
    'morning': {
      'formal': 'صباح الخير',
      'casual': 'صباح الخير',
      'friendly': 'صباح الخير',
      'energetic': 'صباح النور',
    },
    'afternoon': {
      'formal': 'مساء الخير',
      'casual': 'مساء الخير',
      'friendly': 'مساء الخير',
      'energetic': 'أهلاً',
    },
    'evening': {
      'formal': 'مساء الخير',
      'casual': 'مساء الخير',
      'friendly': 'مساء الخير',
      'energetic': 'أهلاً',
    },
    'night': {
      'formal': 'مساء الخير',
      'casual': 'مساء الخير',
      'friendly': 'مساء الخير',
      'energetic': 'أهلاً',
    },
  };

  // Get personalized greeting
  String getPersonalizedGreeting({
    String? userName,
    String? language,
    String? tone,
  }) {
    final currentLanguage = language ?? _userService.getUserLanguage();
    final currentUserName = userName ?? _userService.getUserDisplayName();
    final currentTone = tone ?? _getDefaultTone();
    final timeOfDay = _getTimeOfDay();

    // Get base greeting
    final baseGreeting = _getBaseGreeting(currentLanguage, timeOfDay, currentTone);
    
    // Add personalized name if available
    if (currentUserName.isNotEmpty && currentUserName != 'Player') {
      return '$baseGreeting, $currentUserName!';
    }
    
    return '$baseGreeting!';
  }

  // Get cached greeting or generate new one
  String getGreeting() {
    // Check if we have a valid cached greeting
    if (_userService.isGreetingCacheValid && _userService.cachedGreeting != null) {
      return _userService.cachedGreeting!;
    }

    // Generate new greeting
    final greeting = getPersonalizedGreeting();
    
    // Cache the greeting (we'll need to add a public method for this)
    _cacheGreeting(greeting);
    
    return greeting;
  }

  // Cache greeting (public method)
  Future<void> _cacheGreeting(String greeting) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('greeting_cache', greeting);
      await prefs.setString('last_greeting_update', DateTime.now().toIso8601String());
    } catch (e) {
      // Handle storage error
    }
  }

  // Get time of day
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'evening';
    } else {
      return 'night';
    }
  }

  // Get default tone based on time and user preferences
  String _getDefaultTone() {
    final hour = DateTime.now().hour;
    
    // Morning: more energetic
    if (hour >= 5 && hour < 10) {
      return 'energetic';
    }
    // Late night: more casual
    else if (hour >= 22 || hour < 5) {
      return 'casual';
    }
    // Default: friendly
    else {
      return 'friendly';
    }
  }

  // Get base greeting based on language and time
  String _getBaseGreeting(String language, String timeOfDay, String tone) {
    final greetings = language == 'ar' ? _arabicGreetings : _englishGreetings;
    
    final timeGreetings = greetings[timeOfDay];
    if (timeGreetings == null) {
      // Fallback to friendly tone
      return language == 'ar' ? 'أهلاً' : 'Hello';
    }
    
    return timeGreetings[tone] ?? timeGreetings['friendly']!;
  }

  // Get greeting for specific time (for testing)
  String getGreetingForTime(DateTime time, {String? userName, String? language, String? tone}) {
    final hour = time.hour;
    String timeOfDay;
    
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17 && hour < 22) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }

    final currentLanguage = language ?? _userService.getUserLanguage();
    final currentUserName = userName ?? _userService.getUserDisplayName();
    final currentTone = tone ?? _getDefaultTone();

    final baseGreeting = _getBaseGreeting(currentLanguage, timeOfDay, currentTone);
    
    if (currentUserName.isNotEmpty && currentUserName != 'Player') {
      return '$baseGreeting, $currentUserName!';
    }
    
    return '$baseGreeting!';
  }

  // Clear greeting cache (useful when user info changes)
  Future<void> clearGreetingCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('greeting_cache');
      await prefs.remove('last_greeting_update');
    } catch (e) {
      // Handle storage error
    }
  }

  // Get all available tones for testing
  List<String> getAvailableTones() {
    return ['formal', 'casual', 'friendly', 'energetic'];
  }

  // Get all available languages
  List<String> getAvailableLanguages() {
    return ['en', 'ar'];
  }

  // Get greeting preview for different times
  Map<String, String> getGreetingPreview(String userName, String language) {
    final times = {
      'morning': DateTime(2024, 1, 1, 8, 0), // 8:00 AM
      'afternoon': DateTime(2024, 1, 1, 14, 0), // 2:00 PM
      'evening': DateTime(2024, 1, 1, 19, 0), // 7:00 PM
      'night': DateTime(2024, 1, 1, 23, 0), // 11:00 PM
    };

    final previews = <String, String>{};
    
    for (final entry in times.entries) {
      previews[entry.key] = getGreetingForTime(
        entry.value,
        userName: userName,
        language: language,
      );
    }

    return previews;
  }
} 