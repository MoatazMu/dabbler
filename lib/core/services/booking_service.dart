import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

class BookingService extends ChangeNotifier {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  static const String _dismissedBookingsKey = 'dismissed_bookings';
  static const String _lastDismissDateKey = 'last_dismiss_date';

  List<BookingModel> _todaysBookings = [];
  Set<String> _dismissedBookingIds = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BookingModel> get todaysBookings => List.unmodifiable(_todaysBookings);
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get bookings that should show reminder (not dismissed and within next 24h)
  List<BookingModel> get activeReminders {
    final now = DateTime.now();
    return _todaysBookings
        .where((booking) => 
            booking.isConfirmed && 
            !_dismissedBookingIds.contains(booking.id) &&
            booking.dateTime.isAfter(now) &&
            booking.dateTime.isBefore(now.add(const Duration(hours: 24))))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  // Get the next upcoming booking for countdown
  BookingModel? get nextBooking {
    final reminders = activeReminders;
    return reminders.isNotEmpty ? reminders.first : null;
  }

  bool get hasActiveReminders => activeReminders.isNotEmpty;

  Future<void> init() async {
    await _loadDismissedBookings();
    await _checkAndResetDismissals();
    await fetchTodaysBookings();
  }

  // Fetch today's confirmed bookings
  Future<void> fetchTodaysBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call - replace with actual API implementation
      await Future.delayed(const Duration(milliseconds: 800));
      
      _todaysBookings = await _generateMockBookings();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch bookings: $e';
      _todaysBookings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate mock bookings for demonstration
  Future<List<BookingModel>> _generateMockBookings() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      BookingModel(
        id: 'booking_1',
        title: 'Football Match',
        venue: 'Central Sports Complex',
        sport: 'Football',
        dateTime: today.add(const Duration(hours: 18, minutes: 30)), // 6:30 PM today
        duration: const Duration(hours: 1, minutes: 30),
        isConfirmed: true,
        playerCount: 10,
        price: 25.0,
        organizerId: 'organizer_1',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      BookingModel(
        id: 'booking_2',
        title: 'Tennis Singles',
        venue: 'Riverside Tennis Club',
        sport: 'Tennis',
        dateTime: today.add(const Duration(days: 1, hours: 9)), // 9 AM tomorrow
        duration: const Duration(hours: 1),
        isConfirmed: true,
        playerCount: 2,
        price: 40.0,
        organizerId: 'organizer_2',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      BookingModel(
        id: 'booking_3',
        title: 'Basketball Game',
        venue: 'Downtown Court',
        sport: 'Basketball',
        dateTime: today.add(const Duration(hours: 14)), // 2 PM today
        duration: const Duration(hours: 2),
        isConfirmed: true,
        playerCount: 8,
        price: 20.0,
        organizerId: 'organizer_3',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  // Dismiss a specific booking reminder
  Future<void> dismissBooking(String bookingId) async {
    _dismissedBookingIds.add(bookingId);
    await _saveDismissedBookings();
    notifyListeners();
  }

  // Dismiss all current reminders
  Future<void> dismissAllReminders() async {
    for (final booking in activeReminders) {
      _dismissedBookingIds.add(booking.id);
    }
    await _saveDismissedBookings();
    notifyListeners();
  }

  // Calculate countdown to next booking
  Duration? getCountdownToNext() {
    final next = nextBooking;
    if (next == null) return null;
    
    final now = DateTime.now();
    final difference = next.dateTime.difference(now);
    
    return difference.isNegative ? null : difference;
  }

  // Format countdown as readable string
  String formatCountdown(Duration countdown) {
    if (countdown.inDays > 0) {
      return '${countdown.inDays}d ${countdown.inHours % 24}h ${countdown.inMinutes % 60}m';
    } else if (countdown.inHours > 0) {
      return '${countdown.inHours}h ${countdown.inMinutes % 60}m';
    } else {
      return '${countdown.inMinutes}m';
    }
  }

  // Load dismissed bookings from storage
  Future<void> _loadDismissedBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedList = prefs.getStringList(_dismissedBookingsKey) ?? [];
      _dismissedBookingIds = Set.from(dismissedList);
    } catch (e) {
      _dismissedBookingIds = {};
    }
  }

  // Save dismissed bookings to storage
  Future<void> _saveDismissedBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_dismissedBookingsKey, _dismissedBookingIds.toList());
      await prefs.setString(_lastDismissDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Handle error silently
    }
  }

  // Check if we need to reset dismissals (new day)
  Future<void> _checkAndResetDismissals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDismissStr = prefs.getString(_lastDismissDateKey);
      
      if (lastDismissStr != null) {
        final lastDismiss = DateTime.parse(lastDismissStr);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastDismissDay = DateTime(lastDismiss.year, lastDismiss.month, lastDismiss.day);
        
        // Reset dismissals if it's a new day
        if (today.isAfter(lastDismissDay)) {
          _dismissedBookingIds.clear();
          await prefs.remove(_dismissedBookingsKey);
          await prefs.remove(_lastDismissDateKey);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Refresh bookings (for pull-to-refresh)
  Future<void> refresh() async {
    await fetchTodaysBookings();
  }

  // Get booking by ID
  BookingModel? getBookingById(String id) {
    try {
      return _todaysBookings.firstWhere((booking) => booking.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if booking is happening soon (within 2 hours)
  bool isBookingSoon(BookingModel booking) {
    final now = DateTime.now();
    final difference = booking.dateTime.difference(now);
    return difference.inHours < 2 && difference.inMinutes > 0;
  }
} 