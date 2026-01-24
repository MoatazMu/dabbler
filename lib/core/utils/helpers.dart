import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Added for Timer
import 'dart:math';

class AppHelpers {
  /// Capitalize the first letter of a string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Format a date to a readable string
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }

  /// Format a time to a readable string
  static String formatTime(DateTime time, {String format = 'HH:mm'}) {
    return DateFormat(format).format(time);
  }

  /// Format a date and time to a readable string
  static String formatDateTime(
    DateTime dateTime, {
    String format = 'MMM dd, yyyy HH:mm',
  }) {
    return DateFormat(format).format(dateTime);
  }

  /// Get relative time (e.g., "2 hours ago", "yesterday")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return formatDate(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  /// Format a number with commas
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Format currency
  static String formatCurrency(double amount, {String currency = 'AED'}) {
    return NumberFormat.currency(symbol: currency).format(amount);
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimalPlaces = 1}) {
    return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
  }

  /// Get initials from a name
  static String getInitials(String name) {
    if (name.isEmpty) return '';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Generate a random string
  static String generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      buffer.write(chars[random % chars.length]);
    }

    return buffer.toString();
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  /// Get file extension from filename
  static String getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  /// Get file size in human readable format
  static String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Show a snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: textColor)),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show a loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Get sport icon
  static IconData getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'badminton':
        return Icons.sports_handball;
      case 'table_tennis':
        return Icons.sports_tennis;
      case 'cricket':
        return Icons.sports_cricket;
      case 'baseball':
        return Icons.sports_baseball;
      case 'rugby':
        return Icons.sports_rugby;
      case 'hockey':
        return Icons.sports_hockey;
      default:
        return Icons.sports;
    }
  }

  /// Get sport emoji
  static String getSportEmoji(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
      case 'soccer':
        return '⚽️';
      case 'basketball':
        return '🏀';
      case 'tennis':
        return '🎾';
      case 'cricket':
        return '🏏';
      case 'volleyball':
        return '🏐';
      case 'padel':
      case 'paddle':
        return '🎾';
      case 'badminton':
        return '🏸';
      case 'table_tennis':
        return '🏓';
      case 'baseball':
        return '⚾️';
      case 'rugby':
      case 'rugby_union':
      case 'rugby_sevens':
        return '🏉';
      case 'hockey':
      case 'field_hockey':
      case 'ice_hockey':
        return '🏒';
      case 'running':
      case 'sprinting':
      case 'marathon':
      case 'trail_running':
      case 'cross_country_running':
        return '🏃';
      case 'swimming':
      case 'open_water_swimming':
        return '🏊';
      case 'equestrianism':
      case 'horse_racing':
      case 'dressage':
      case 'show_jumping':
      case 'eventing':
      case 'polo':
      case 'rodeo':
      case 'vaulting':
      case 'endurance_riding':
      case 'driving':
        return '🏇';
      case 'shooting':
      case 'archery':
        return '🎯';
      case 'boxing':
      case 'kickboxing':
      case 'muay_thai':
        return '🥊';
      case 'cycling':
      case 'road_cycling':
      case 'mountain_biking':
      case 'track_cycling':
      case 'gravel_cycling':
      case 'bmx':
        return '🚴';
      case 'weightlifting':
      case 'powerlifting':
      case 'olympic_weightlifting':
        return '🏋️';
      case 'golf':
        return '⛳️';
      case 'surfing':
      case 'bodyboarding':
        return '🏄';
      case 'skiing':
      case 'snowboarding':
        return '⛷️';
      case 'skateboarding':
      case 'longboarding':
        return '🛹';
      case 'gymnastics':
        return '🤸';
      case 'martial_arts':
      case 'karate':
      case 'judo':
      case 'taekwondo':
      case 'mma':
      case 'bjj':
      case 'wrestling':
      case 'fencing':
      case 'kendo':
      case 'aikido':
      case 'kung_fu':
      case 'sambo':
      case 'sumo':
        return '🥋';
      case 'yoga':
      case 'pilates':
      case 'barre':
        return '🧘';
      case 'hiking':
      case 'mountaineering':
      case 'trekking':
        return '🥾';
      case 'rock_climbing':
      case 'indoor_climbing':
      case 'bouldering':
        return '🧗';
      case 'rowing':
      case 'kayaking':
      case 'canoeing':
        return '🚣';
      case 'sailing':
      case 'windsurfing':
        return '⛵️';
      case 'motorsport':
      case 'formula_racing':
      case 'rally':
      case 'karting':
      case 'motocross':
      case 'drift_racing':
      case 'motorcycling':
      case 'enduro':
      case 'enduro_motorcycling':
      case 'atv_quad':
        return '🏎️';
      case 'chess':
      case 'blitz_chess':
      case 'rapid_chess':
        return '♟️';
      case 'esports':
      case 'fps_games':
      case 'moba_games':
      case 'fighting_games':
      case 'sports_simulation':
        return '🎮';
      case 'gym_training':
      case 'fitness':
      case 'functional_training':
      case 'personal_training':
        return '💪';
      case 'crossfit':
      case 'hiit':
      case 'calisthenics':
        return '🔥';
      case 'dance':
      case 'dance_fitness':
      case 'zumba':
        return '💃';
      case 'meditation':
      case 'mindfulness':
        return '🧠';
      case 'parkour':
        return '🤾';
      case 'american_football':
      case 'flag_football':
        return '🏈';
      case 'handball':
        return '🤾';
      case 'lacrosse':
        return '🥍';
      case 'softball':
        return '🥎';
      case 'squash':
      case 'racquetball':
        return '🎾';
      case 'diving':
      case 'freediving':
      case 'snorkeling':
        return '🤿';
      case 'triathlon':
      case 'duathlon':
      case 'modern_pentathlon':
        return '🏅';
      case 'kitesurfing':
      case 'wakeboarding':
      case 'waterskiing':
      case 'stand_up_paddleboarding':
        return '🏄';
      case 'pickleball':
      case 'beach_tennis':
      case 'platform_tennis':
        return '🏓';
      case 'beach_volleyball':
        return '🏐';
      case 'dodgeball':
        return '🎯';
      case 'ultimate_frisbee':
        return '🥏';
      case 'water_polo':
        return '🤽';
      case 'netball':
      case 'kabaddi':
      case 'street_basketball':
        return '🏀';
      case 'pool_billiards':
      case 'snooker':
        return '🎱';
      case 'darts':
        return '🎯';
      case 'poker':
      case 'bridge':
      case 'checkers':
      case 'go':
        return '🃏';
      case 'inline_skating':
      case 'roller_skating':
        return '⛸️';
      case 'scootering':
        return '🛴';
      case 'aerobics':
      case 'bodybuilding':
      case 'stretching_mobility':
        return '💪';
      case 'athletics':
      case 'race_walking':
      case 'obstacle_course_racing':
        return '🏃';
      case 'canyoning':
      case 'orienteering':
      case 'ziplining':
        return '🧭';
      default:
        return '⚽️';
    }
  }

  /// Get sport display name
  static String getSportDisplayName(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return 'Football';
      case 'basketball':
        return 'Basketball';
      case 'tennis':
        return 'Tennis';
      case 'volleyball':
        return 'Volleyball';
      case 'badminton':
        return 'Badminton';
      case 'table_tennis':
        return 'Table Tennis';
      case 'cricket':
        return 'Cricket';
      case 'baseball':
        return 'Baseball';
      case 'rugby':
      case 'rugby_union':
        return 'Rugby';
      case 'rugby_sevens':
        return 'Rugby Sevens';
      case 'hockey':
        return 'Hockey';
      case 'field_hockey':
        return 'Field Hockey';
      case 'ice_hockey':
        return 'Ice Hockey';
      case 'padel':
      case 'paddle':
        return 'Padel';
      case 'running':
        return 'Running';
      case 'swimming':
        return 'Swimming';
      case 'equestrianism':
        return 'Equestrianism';
      case 'shooting':
        return 'Shooting';
      case 'aerobics':
        return 'Aerobics';
      case 'aikido':
        return 'Aikido';
      case 'american_football':
        return 'American Football';
      case 'archery':
        return 'Archery';
      case 'athletics':
        return 'Athletics';
      case 'atv_quad':
        return 'ATV / Quad';
      case 'barre':
        return 'Barre';
      case 'beach_tennis':
        return 'Beach Tennis';
      case 'beach_volleyball':
        return 'Beach Volleyball';
      case 'blitz_chess':
        return 'Blitz Chess';
      case 'bmx':
        return 'BMX';
      case 'bodyboarding':
        return 'Bodyboarding';
      case 'bodybuilding':
        return 'Bodybuilding';
      case 'bouldering':
        return 'Bouldering';
      case 'boxing':
        return 'Boxing';
      case 'bjj':
        return 'Brazilian Jiu-Jitsu';
      case 'bridge':
        return 'Bridge';
      case 'calisthenics':
        return 'Calisthenics';
      case 'canoeing':
        return 'Canoeing';
      case 'canyoning':
        return 'Canyoning';
      case 'checkers':
        return 'Checkers';
      case 'chess':
        return 'Chess';
      case 'indoor_climbing':
        return 'Climbing (Indoor)';
      case 'cross_country_running':
        return 'Cross Country';
      case 'crossfit':
        return 'CrossFit';
      case 'road_cycling':
        return 'Cycling (Road)';
      case 'dance_fitness':
        return 'Dance Fitness';
      case 'darts':
        return 'Darts';
      case 'diving':
        return 'Diving';
      case 'dodgeball':
        return 'Dodgeball';
      case 'dressage':
        return 'Dressage';
      case 'drift_racing':
        return 'Drift Racing';
      case 'driving':
        return 'Driving';
      case 'duathlon':
        return 'Duathlon';
      case 'endurance_riding':
        return 'Endurance Riding';
      case 'enduro':
        return 'Enduro';
      case 'enduro_motorcycling':
        return 'Enduro Motorcycling';
      case 'esports':
        return 'Esports';
      case 'eventing':
        return 'Eventing';
      case 'fencing':
        return 'Fencing';
      case 'fighting_games':
        return 'Fighting Games';
      case 'flag_football':
        return 'Flag Football';
      case 'formula_racing':
        return 'Formula Racing';
      case 'fps_games':
        return 'FPS Games';
      case 'freediving':
        return 'Freediving';
      case 'functional_training':
        return 'Functional Training';
      case 'go':
        return 'Go (Baduk)';
      case 'gravel_cycling':
        return 'Gravel Cycling';
      case 'gym_training':
        return 'Gym Training';
      case 'handball':
        return 'Handball';
      case 'hiit':
        return 'HIIT';
      case 'hiking':
        return 'Hiking';
      case 'horse_racing':
        return 'Horse Racing';
      case 'inline_skating':
        return 'Inline Skating';
      case 'judo':
        return 'Judo';
      case 'kabaddi':
        return 'Kabaddi';
      case 'karate':
        return 'Karate';
      case 'karting':
        return 'Karting';
      case 'kayaking':
        return 'Kayaking';
      case 'kendo':
        return 'Kendo';
      case 'kickboxing':
        return 'Kickboxing';
      case 'kitesurfing':
        return 'Kitesurfing';
      case 'kung_fu':
        return 'Kung Fu';
      case 'lacrosse':
        return 'Lacrosse';
      case 'longboarding':
        return 'Longboarding';
      case 'marathon':
        return 'Marathon';
      case 'meditation':
        return 'Meditation';
      case 'mindfulness':
        return 'Mindfulness';
      case 'mma':
        return 'Mixed Martial Arts';
      case 'moba_games':
        return 'MOBA Games';
      case 'modern_pentathlon':
        return 'Modern Pentathlon';
      case 'motocross':
        return 'Motocross';
      case 'motorcycling':
        return 'Motorcycling';
      case 'mountain_biking':
        return 'Mountain Biking';
      case 'mountaineering':
        return 'Mountaineering';
      case 'muay_thai':
        return 'Muay Thai';
      case 'netball':
        return 'Netball';
      case 'obstacle_course_racing':
        return 'Obstacle Course Racing';
      case 'olympic_weightlifting':
        return 'Olympic Weightlifting';
      case 'open_water_swimming':
        return 'Open Water Swimming';
      case 'orienteering':
        return 'Orienteering';
      case 'parkour':
        return 'Parkour';
      case 'personal_training':
        return 'Personal Training';
      case 'pickleball':
        return 'Pickleball';
      case 'pilates':
        return 'Pilates';
      case 'platform_tennis':
        return 'Platform Tennis';
      case 'poker':
        return 'Poker';
      case 'polo':
        return 'Polo';
      case 'pool_billiards':
        return 'Pool / Billiards';
      case 'powerlifting':
        return 'Powerlifting';
      case 'race_walking':
        return 'Race Walking';
      case 'racquetball':
        return 'Racquetball';
      case 'rally':
        return 'Rally Racing';
      case 'rapid_chess':
        return 'Rapid Chess';
      case 'rock_climbing':
        return 'Rock Climbing';
      case 'rodeo':
        return 'Rodeo';
      case 'roller_skating':
        return 'Roller Skating';
      case 'rowing':
        return 'Rowing';
      case 'sailing':
        return 'Sailing';
      case 'sambo':
        return 'Sambo';
      case 'scootering':
        return 'Scootering';
      case 'show_jumping':
        return 'Show Jumping';
      case 'skateboarding':
        return 'Skateboarding';
      case 'snooker':
        return 'Snooker';
      case 'snorkeling':
        return 'Snorkeling';
      case 'softball':
        return 'Softball';
      case 'sports_simulation':
        return 'Sports Simulation';
      case 'sprinting':
        return 'Sprinting';
      case 'squash':
        return 'Squash';
      case 'stand_up_paddleboarding':
        return 'Stand-Up Paddleboarding';
      case 'street_basketball':
        return 'Street Basketball';
      case 'stretching_mobility':
        return 'Stretching & Mobility';
      case 'sumo':
        return 'Sumo';
      case 'surfing':
        return 'Surfing';
      case 't20_cricket':
        return 'T20 Cricket';
      case 'taekwondo':
        return 'Taekwondo';
      case 'track_cycling':
        return 'Track Cycling';
      case 'trail_running':
        return 'Trail Running';
      case 'trekking':
        return 'Trekking';
      case 'triathlon':
        return 'Triathlon';
      case 'ultimate_frisbee':
        return 'Ultimate Frisbee';
      case 'vaulting':
        return 'Vaulting';
      case 'wakeboarding':
        return 'Wakeboarding';
      case 'water_polo':
        return 'Water Polo';
      case 'waterskiing':
        return 'Waterskiing';
      case 'weightlifting':
        return 'Weightlifting';
      case 'windsurfing':
        return 'Windsurfing';
      case 'wrestling':
        return 'Wrestling';
      case 'yoga':
        return 'Yoga';
      case 'ziplining':
        return 'Ziplining';
      case 'zumba':
        return 'Zumba';
      default:
        return capitalize(sport);
    }
  }

  /// Get intent display name
  static String getIntentDisplayName(String intent) {
    switch (intent.toLowerCase()) {
      case 'competitive':
        return 'Competitive';
      case 'casual':
        return 'Casual';
      case 'training':
        return 'Training';
      case 'social':
        return 'Social';
      case 'fitness':
        return 'Fitness';
      default:
        return capitalize(intent);
    }
  }

  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'inactive':
        return Colors.red;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get status display name
  static String getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'ongoing':
        return 'Ongoing';
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      default:
        return capitalize(status);
    }
  }

  /// Calculate distance between two coordinates
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final a =
        pow(sin(dLat / 2), 2) +
        cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);
    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Format distance
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()}m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceInKm.round()}km';
    }
  }

  /// Debounce function
  static Function debounce(Function func, Duration wait) {
    Timer? timer;
    return ([List<dynamic>? args]) {
      timer?.cancel();
      timer = Timer(wait, () => Function.apply(func, args ?? []));
    };
  }

  /// Throttle function
  static Function throttle(Function func, Duration wait) {
    DateTime? lastCall;
    return ([List<dynamic>? args]) {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) >= wait) {
        lastCall = now;
        Function.apply(func, args ?? []);
      }
    };
  }
}
