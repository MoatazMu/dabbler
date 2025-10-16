/// Extension methods for DateTime manipulation
extension DateTimeExtensions on DateTime {
  /// Returns true if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Returns true if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Returns a "time ago" string (e.g. "2 hours ago")
  String timeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }

  /// Returns the start of day (00:00:00)
  DateTime startOfDay() {
    return DateTime(year, month, day);
  }

  /// Returns the end of day (23:59:59)
  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Returns the start of week (Sunday)
  DateTime startOfWeek() {
    final difference = weekday - DateTime.sunday;
    return subtract(Duration(days: difference)).startOfDay();
  }

  /// Returns the end of week (Saturday)
  DateTime endOfWeek() {
    final difference = DateTime.saturday - weekday;
    return add(Duration(days: difference)).endOfDay();
  }

  /// Returns the start of month
  DateTime startOfMonth() {
    return DateTime(year, month);
  }

  /// Returns the end of month
  DateTime endOfMonth() {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Returns true if the date is a weekend
  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// Returns true if the date is a weekday
  bool get isWeekday => !isWeekend;

  /// Returns the date in a readable format (e.g. "Jan 1, 2025")
  String get readableDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $day, $year';
  }

  /// Returns the time in 12-hour format (e.g. "2:30 PM")
  String get readableTime {
    final hour12 = hour > 12 ? hour - 12 : hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $amPm';
  }

  /// Returns true if the date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Returns true if the date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Returns true if the date is within a given duration from now
  bool isWithin(Duration duration) {
    final now = DateTime.now();
    return isAfter(now.subtract(duration)) && isBefore(now.add(duration));
  }

  /// Returns the age in years from this date
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }

  /// Returns a new DateTime with added business days
  DateTime addBusinessDays(int days) {
    var date = this;
    var daysAdded = 0;
    while (daysAdded < days) {
      date = date.add(const Duration(days: 1));
      if (!date.isWeekend) {
        daysAdded++;
      }
    }
    return date;
  }

  /// Returns true if the date falls on a holiday (example implementation)
  bool get isHoliday {
    // Add your holiday logic here
    // This is just an example with major US holidays
    final holidays = [
      DateTime(year, 1, 1),   // New Year's Day
      DateTime(year, 7, 4),   // Independence Day
      DateTime(year, 12, 25), // Christmas
      // Add more holidays as needed
    ];

    return holidays.any((holiday) =>
      holiday.year == year && holiday.month == month && holiday.day == day);
  }
}
