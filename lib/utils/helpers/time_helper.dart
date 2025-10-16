import 'package:intl/intl.dart';

/// Utility class for time-related operations in games
class TimeHelper {

  /// Format game time range (6:00 PM - 8:00 PM)
  static String formatGameTimeRange(
    DateTime startTime,
    DateTime endTime, {
    bool use24Hour = false,
  }) {
    final timeFormat = use24Hour 
        ? DateFormat('HH:mm')
        : DateFormat('h:mm a');
    
    final startFormatted = timeFormat.format(startTime);
    final endFormatted = timeFormat.format(endTime);
    
    // If same day, show time range
    if (startTime.day == endTime.day &&
        startTime.month == endTime.month &&
        startTime.year == endTime.year) {
      return '$startFormatted - $endFormatted';
    }
    
    // If different days, include date
    final dateFormat = DateFormat('MMM d');
    final startDate = dateFormat.format(startTime);
    final endDate = dateFormat.format(endTime);
    
    return '$startDate $startFormatted - $endDate $endFormatted';
  }

  /// Calculate duration between two times
  static Duration calculateDuration(DateTime startTime, DateTime endTime) {
    return endTime.difference(startTime);
  }

  /// Format duration in human-readable format
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours == 0) {
      return '${minutes}min';
    } else if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}min';
    }
  }

  /// Get next available time slot based on current time and constraints
  static DateTime getNextAvailableTimeSlot({
    DateTime? baseTime,
    int intervalMinutes = 30,
    int minAdvanceMinutes = 60,
    BusinessHours? businessHours,
  }) {
    baseTime ??= DateTime.now();
    
    // Add minimum advance time
    DateTime nextSlot = baseTime.add(Duration(minutes: minAdvanceMinutes));
    
    // Round up to next interval
    final minutes = nextSlot.minute;
    final remainder = minutes % intervalMinutes;
    if (remainder != 0) {
      nextSlot = nextSlot.add(Duration(minutes: intervalMinutes - remainder));
    }
    
    // Reset seconds and milliseconds
    nextSlot = DateTime(
      nextSlot.year,
      nextSlot.month,
      nextSlot.day,
      nextSlot.hour,
      nextSlot.minute,
    );
    
    // Check business hours if provided
    if (businessHours != null) {
      nextSlot = _adjustForBusinessHours(nextSlot, businessHours);
    }
    
    return nextSlot;
  }

  /// Format relative time (in 2 hours, tomorrow, next week)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    // Past times
    if (difference.isNegative) {
      final pastDifference = now.difference(dateTime);
      
      if (pastDifference.inMinutes < 1) {
        return 'just now';
      } else if (pastDifference.inMinutes < 60) {
        return '${pastDifference.inMinutes}min ago';
      } else if (pastDifference.inHours < 24) {
        return '${pastDifference.inHours}h ago';
      } else if (pastDifference.inDays == 1) {
        return 'yesterday';
      } else if (pastDifference.inDays < 7) {
        return '${pastDifference.inDays} days ago';
      } else {
        return DateFormat('MMM d, y').format(dateTime);
      }
    }
    
    // Future times
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'tomorrow';
    } else if (difference.inDays < 7) {
      return 'in ${difference.inDays} days';
    } else if (difference.inDays < 14) {
      return 'next week';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  /// Check if current time is within business hours
  static bool isWithinBusinessHours(
    BusinessHours businessHours, {
    DateTime? checkTime,
  }) {
    checkTime ??= DateTime.now();
    final weekday = checkTime.weekday;
    
    // Check if day is operating day
    if (!businessHours.operatingDays.contains(weekday)) {
      return false;
    }
    
    final timeOfDay = TimeOfDay.fromDateTime(checkTime);
    return _isTimeWithinRange(
      timeOfDay,
      businessHours.openTime,
      businessHours.closeTime,
    );
  }

  /// Get formatted business hours for display
  static String formatBusinessHours(BusinessHours businessHours) {
    if (businessHours.operatingDays.isEmpty) {
      return 'Closed';
    }
    
    // Group consecutive days with same hours
    final dayGroups = <String, List<int>>{};
    final hoursKey = '${_formatTime(businessHours.openTime)} - ${_formatTime(businessHours.closeTime)}';
    
    for (final day in businessHours.operatingDays) {
      dayGroups[hoursKey] ??= [];
      dayGroups[hoursKey]!.add(day);
    }
    
    final formatted = dayGroups.entries.map((entry) {
      final days = entry.value..sort();
      final hours = entry.key;
      
  if (days.length == 7) {
        return 'Daily $hours';
  } else if (days.length == 5 &&
         {1, 2, 3, 4, 5}.every(days.contains)) {
        return 'Mon-Fri $hours';
      } else {
        final dayNames = days.map(_getDayName).join(', ');
        return '$dayNames $hours';
      }
    }).join('\n');
    
    return formatted;
  }

  /// Convert time to user's timezone
  static DateTime convertToUserTimezone(
    DateTime utcTime,
    String userTimezone,
  ) {
    // This is a simplified implementation
    // In a real app, you'd use a proper timezone library
    final userOffset = _getTimezoneOffset(userTimezone);
    return utcTime.add(Duration(hours: userOffset));
  }

  /// Get user's current timezone
  static String getUserTimezone() {
    // This would be determined from device settings or user preference
    // For now, return UTC
    return 'UTC';
  }

  /// Parse time string to DateTime
  static DateTime? parseTimeString(String timeStr, DateTime baseDate) {
    try {
      // Handle various time formats
      final formats = [
        'h:mm a',     // 6:30 PM
        'HH:mm',      // 18:30
        'h a',        // 6 PM
        'HH',         // 18
      ];
      
      for (final format in formats) {
        try {
          final parsed = DateFormat(format).parse(timeStr);
          return DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            parsed.hour,
            parsed.minute,
          );
        } catch (_) {
          continue;
        }
      }
      
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get suggested time slots for a venue
  static List<DateTime> getSuggestedTimeSlots(
    DateTime date,
    BusinessHours businessHours, {
    int intervalMinutes = 60,
    int slotDurationMinutes = 120,
  }) {
    final slots = <DateTime>[];
    
    if (!businessHours.operatingDays.contains(date.weekday)) {
      return slots;
    }
    
    final openDateTime = DateTime(
      date.year,
      date.month, 
      date.day,
      businessHours.openTime.hour,
      businessHours.openTime.minute,
    );
    
    final closeDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      businessHours.closeTime.hour,
      businessHours.closeTime.minute,
    );
    
    DateTime currentSlot = openDateTime;
    while (currentSlot.add(Duration(minutes: slotDurationMinutes))
           .isBefore(closeDateTime)) {
      slots.add(currentSlot);
      currentSlot = currentSlot.add(Duration(minutes: intervalMinutes));
    }
    
    return slots;
  }

  /// Private helper methods
  static DateTime _adjustForBusinessHours(
    DateTime time,
    BusinessHours businessHours,
  ) {
    // If not an operating day, find next operating day
    if (!businessHours.operatingDays.contains(time.weekday)) {
      return _findNextOperatingDay(time, businessHours);
    }
    
    // If before opening, adjust to opening time
    final timeOfDay = TimeOfDay.fromDateTime(time);
    if (_isTimeBefore(timeOfDay, businessHours.openTime)) {
      return DateTime(
        time.year,
        time.month,
        time.day,
        businessHours.openTime.hour,
        businessHours.openTime.minute,
      );
    }
    
    // If after closing, move to next operating day
    if (_isTimeAfter(timeOfDay, businessHours.closeTime)) {
      final nextDay = time.add(const Duration(days: 1));
      return _adjustForBusinessHours(nextDay, businessHours);
    }
    
    return time;
  }

  static DateTime _findNextOperatingDay(
    DateTime startDate,
    BusinessHours businessHours,
  ) {
    DateTime nextDay = startDate;
    
    for (int i = 0; i < 7; i++) {
      if (businessHours.operatingDays.contains(nextDay.weekday)) {
        return DateTime(
          nextDay.year,
          nextDay.month,
          nextDay.day,
          businessHours.openTime.hour,
          businessHours.openTime.minute,
        );
      }
      nextDay = nextDay.add(const Duration(days: 1));
    }
    
    return startDate; // Fallback if no operating days found
  }

  static bool _isTimeWithinRange(
    TimeOfDay time,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  static bool _isTimeBefore(TimeOfDay time, TimeOfDay reference) {
    final timeMinutes = time.hour * 60 + time.minute;
    final refMinutes = reference.hour * 60 + reference.minute;
    return timeMinutes < refMinutes;
  }

  static bool _isTimeAfter(TimeOfDay time, TimeOfDay reference) {
    final timeMinutes = time.hour * 60 + time.minute;
    final refMinutes = reference.hour * 60 + reference.minute;
    return timeMinutes > refMinutes;
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String _getDayName(int weekday) {
    const dayNames = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return dayNames[weekday - 1];
  }

  static int _getTimezoneOffset(String timezone) {
    // Simplified timezone offsets (in hours from UTC)
    const offsets = {
      'America/New_York': -5,
      'America/Chicago': -6,
      'America/Denver': -7,
      'America/Los_Angeles': -8,
      'Europe/London': 0,
      'Europe/Paris': 1,
      'Asia/Tokyo': 9,
    };
    return offsets[timezone] ?? 0;
  }
}

/// Business hours configuration
class BusinessHours {
  final List<int> operatingDays; // 1=Monday, 7=Sunday
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  const BusinessHours({
    required this.operatingDays,
    required this.openTime,
    required this.closeTime,
  });

  factory BusinessHours.weekdays({
    required TimeOfDay openTime,
    required TimeOfDay closeTime,
  }) {
    return BusinessHours(
      operatingDays: [1, 2, 3, 4, 5], // Monday to Friday
      openTime: openTime,
      closeTime: closeTime,
    );
  }

  factory BusinessHours.everyday({
    required TimeOfDay openTime,
    required TimeOfDay closeTime,
  }) {
    return BusinessHours(
      operatingDays: [1, 2, 3, 4, 5, 6, 7], // All days
      openTime: openTime,
      closeTime: closeTime,
    );
  }

  factory BusinessHours.weekends({
    required TimeOfDay openTime,
    required TimeOfDay closeTime,
  }) {
    return BusinessHours(
      operatingDays: [6, 7], // Saturday and Sunday
      openTime: openTime,
      closeTime: closeTime,
    );
  }
}

/// Time of day helper class
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(
      hour: dateTime.hour,
      minute: dateTime.minute,
    );
  }

  int get hourOfPeriod => hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  DayPeriod get period => hour < 12 ? DayPeriod.am : DayPeriod.pm;

  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

enum DayPeriod { am, pm }
