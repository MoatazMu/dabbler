import 'dart:async';
import 'package:flutter/foundation.dart';

// Booking conflict resolution and payment processing service
class BookingsService {
  final BookingsRepository _bookingsRepository;
  final PaymentService _paymentService;
  final VenuesService _venuesService;
  final NotificationService _notificationService;
  final CancellationPolicyService _cancellationPolicyService;

  BookingsService({
    required BookingsRepository bookingsRepository,
    required PaymentService paymentService,
    required VenuesService venuesService,
    required NotificationService notificationService,
    required CancellationPolicyService cancellationPolicyService,
  }) : _bookingsRepository = bookingsRepository,
       _paymentService = paymentService,
       _venuesService = venuesService,
       _notificationService = notificationService,
       _cancellationPolicyService = cancellationPolicyService;

  // BOOKING CREATION WITH CONFLICT RESOLUTION
  Future<BookingResult> createBooking({
    required String gameId,
    required String venueId,
    required DateTime dateTime,
    required Duration duration,
    required String organizerId,
    required PaymentDetails paymentDetails,
    bool autoResolveConflicts = false,
  }) async {
    try {
      // Step 1: Check for conflicts
      final conflictResult = await _checkBookingConflicts(
        venueId: venueId,
        dateTime: dateTime,
        duration: duration,
        excludeGameId: gameId,
      );

      if (conflictResult.hasConflicts && !autoResolveConflicts) {
        return BookingResult.conflict(
          conflicts: conflictResult.conflicts,
          suggestedAlternatives: conflictResult.alternatives,
        );
      }

      // Step 2: Resolve conflicts if auto-resolve is enabled
      DateTime finalDateTime = dateTime;
      if (conflictResult.hasConflicts && autoResolveConflicts) {
        final resolution = await _resolveBookingConflicts(conflictResult);
        if (resolution.isSuccess) {
          finalDateTime = resolution.newDateTime!;
        } else {
          return BookingResult.failure(
            error: 'Unable to auto-resolve booking conflicts',
            suggestedAlternatives: conflictResult.alternatives,
          );
        }
      }

      // Step 3: Calculate pricing
      final pricing = await _venuesService.calculateDynamicPricing(
        venueId: venueId,
        dateTime: finalDateTime,
        duration: duration,
        sport: 'basketball', // This should come from game data
      );

      // Step 4: Process payment
      final paymentResult = await _processBookingPayment(
        amount: pricing.totalPrice,
        paymentDetails: paymentDetails,
        gameId: gameId,
        venueId: venueId,
      );

      if (!paymentResult.isSuccess) {
        return BookingResult.failure(
          error: 'Payment failed: ${paymentResult.errorMessage}',
        );
      }

      // Step 5: Create the booking
      final booking = VenueBooking(
        id: _generateBookingId(),
        gameId: gameId,
        venueId: venueId,
        organizerId: organizerId,
        dateTime: finalDateTime,
        duration: duration,
        status: BookingStatus.confirmed,
        paymentId: paymentResult.paymentId!,
        totalAmount: pricing.totalPrice,
        cancellationPolicy: await _getCancellationPolicy(venueId),
        createdAt: DateTime.now(),
      );

      // Step 6: Save to repository
      final savedBooking = await _bookingsRepository.createBooking(booking);

      // Step 7: Send confirmation notification
      await _notificationService.sendBookingConfirmation(
        organizerId: organizerId,
        booking: savedBooking,
        venue: await _venuesService.getVenueById(venueId),
      );

      return BookingResult.success(booking: savedBooking);

    } catch (e, stackTrace) {
      debugPrint('Error creating booking: $e\n$stackTrace');
      return BookingResult.failure(
        error: 'Failed to create booking: $e',
      );
    }
  }

  // BOOKING CONFLICT DETECTION
  Future<ConflictResolutionResult> _checkBookingConflicts({
    required String venueId,
    required DateTime dateTime,
    required Duration duration,
    String? excludeGameId,
  }) async {
    try {
      final endTime = dateTime.add(duration);
      
      // Get existing bookings for the venue in the time range
      final existingBookings = await _bookingsRepository.getVenueBookings(
        venueId: venueId,
        startTime: dateTime.subtract(duration),
        endTime: endTime,
        excludeGameId: excludeGameId,
      );

      final conflicts = <BookingConflict>[];
      
      for (final booking in existingBookings) {
        final bookingEnd = booking.dateTime.add(booking.duration);
        
        // Check for time overlap
        if (dateTime.isBefore(bookingEnd) && endTime.isAfter(booking.dateTime)) {
          conflicts.add(BookingConflict(
            conflictingBooking: booking,
            overlapStart: dateTime.isAfter(booking.dateTime) ? dateTime : booking.dateTime,
            overlapEnd: endTime.isBefore(bookingEnd) ? endTime : bookingEnd,
            conflictType: _determineConflictType(dateTime, endTime, booking),
          ));
        }
      }

      // Generate alternative time suggestions
      final alternatives = conflicts.isNotEmpty
          ? await _generateAlternativeBookingTimes(
              venueId: venueId,
              preferredDateTime: dateTime,
              duration: duration,
            )
          : <DateTime>[];

      return ConflictResolutionResult(
        hasConflicts: conflicts.isNotEmpty,
        conflicts: conflicts,
        alternatives: alternatives,
      );

    } catch (e) {
      debugPrint('Error checking booking conflicts: $e');
      return ConflictResolutionResult(
        hasConflicts: false,
        conflicts: [],
        alternatives: [],
      );
    }
  }

  // AUTOMATIC CONFLICT RESOLUTION
  Future<AutoResolveResult> _resolveBookingConflicts(
    ConflictResolutionResult conflictResult,
  ) async {
    if (!conflictResult.hasConflicts) {
      return AutoResolveResult.success();
    }

    // Try the first alternative time
    if (conflictResult.alternatives.isNotEmpty) {
      final newDateTime = conflictResult.alternatives.first;
      
      // Double-check the new time doesn't have conflicts
      final recheckResult = await _checkBookingConflicts(
        venueId: conflictResult.conflicts.first.conflictingBooking.venueId,
        dateTime: newDateTime,
        duration: conflictResult.conflicts.first.conflictingBooking.duration,
      );

      if (!recheckResult.hasConflicts) {
        return AutoResolveResult.success(newDateTime: newDateTime);
      }
    }

    return AutoResolveResult.failure('No available alternative times found');
  }

  // ALTERNATIVE TIME GENERATION
  Future<List<DateTime>> _generateAlternativeBookingTimes({
    required String venueId,
    required DateTime preferredDateTime,
    required Duration duration,
  }) async {
    final alternatives = <DateTime>[];
    final venue = await _venuesService.getVenueById(venueId);
    
    if (venue == null) return alternatives;

    // Get the preferred day and try different hours
    final baseDate = DateTime(
      preferredDateTime.year,
      preferredDateTime.month,
      preferredDateTime.day,
    );

    // Try same day alternatives
    await _findSameDayAlternatives(
      venue,
      baseDate,
      preferredDateTime,
      duration,
      alternatives,
    );

    // Try next day alternatives if same day doesn't work
    if (alternatives.length < 3) {
      await _findNextDayAlternatives(
        venue,
        baseDate.add(const Duration(days: 1)),
        duration,
        alternatives,
      );
    }

    // Try previous day if still not enough alternatives
    if (alternatives.length < 3 && baseDate.isAfter(DateTime.now())) {
      await _findNextDayAlternatives(
        venue,
        baseDate.subtract(const Duration(days: 1)),
        duration,
        alternatives,
      );
    }

    return alternatives.take(5).toList();
  }

  Future<void> _findSameDayAlternatives(
    Venue venue,
    DateTime baseDate,
    DateTime preferredTime,
    Duration duration,
    List<DateTime> alternatives,
  ) async {
    final preferredHour = preferredTime.hour;
    
    // Try 1-2 hours before and after the preferred time
    final candidateHours = [
      preferredHour - 2,
      preferredHour - 1,
      preferredHour + 1,
      preferredHour + 2,
    ].where((hour) => hour >= 6 && hour <= 22).toList();

    for (final hour in candidateHours) {
      final candidateTime = baseDate.add(Duration(hours: hour));
      
      if (await _isTimeSlotAvailable(venue.id, candidateTime, duration)) {
        alternatives.add(candidateTime);
        if (alternatives.length >= 3) break;
      }
    }
  }

  Future<void> _findNextDayAlternatives(
    Venue venue,
    DateTime baseDate,
    Duration duration,
    List<DateTime> alternatives,
  ) async {
    // Try popular booking hours
    final popularHours = [9, 10, 14, 15, 18, 19, 20];
    
    for (final hour in popularHours) {
      final candidateTime = baseDate.add(Duration(hours: hour));
      
      if (candidateTime.isAfter(DateTime.now()) &&
          await _isTimeSlotAvailable(venue.id, candidateTime, duration)) {
        alternatives.add(candidateTime);
        if (alternatives.length >= 5) break;
      }
    }
  }

  Future<bool> _isTimeSlotAvailable(
    String venueId,
    DateTime dateTime,
    Duration duration,
  ) async {
    final availability = await _venuesService.checkAvailability(
      venueId: venueId,
      dateTime: dateTime,
      duration: duration,
    );
    return availability.isAvailable;
  }

  // PAYMENT PROCESSING
  Future<PaymentResult> _processBookingPayment({
    required double amount,
    required PaymentDetails paymentDetails,
    required String gameId,
    required String venueId,
  }) async {
    try {
      // Create payment intent
      final paymentIntent = await _paymentService.createPaymentIntent(
        amount: amount,
        currency: 'usd',
        metadata: {
          'gameId': gameId,
          'venueId': venueId,
          'type': 'venue_booking',
        },
      );

      // Process the payment
      final paymentResult = await _paymentService.processPayment(
        paymentIntentId: paymentIntent.id,
        paymentDetails: paymentDetails,
      );

      return paymentResult;

    } catch (e) {
      debugPrint('Payment processing error: $e');
      return PaymentResult.failure('Payment processing failed: $e');
    }
  }

  // BOOKING CANCELLATION
  Future<CancellationResult> cancelBooking({
    required String bookingId,
    required String userId,
    String? reason,
  }) async {
    try {
      // Get the booking
      final booking = await _bookingsRepository.getBookingById(bookingId);
      if (booking == null) {
        return CancellationResult.failure('Booking not found');
      }

      // Check user permission
      if (booking.organizerId != userId) {
        return CancellationResult.failure('Not authorized to cancel this booking');
      }

      // Check if booking can be cancelled
      final policy = booking.cancellationPolicy;
      final canCancel = _canCancelBooking(booking, policy);
      
      if (!canCancel.allowed) {
        return CancellationResult.failure(canCancel.reason!);
      }

      // Calculate refund amount
      final refundCalculation = await _calculateRefundAmount(booking, policy);

      // Process refund if applicable
      String? refundId;
      if (refundCalculation.refundAmount > 0) {
        final refundResult = await _paymentService.processRefund(
          paymentId: booking.paymentId,
          amount: refundCalculation.refundAmount,
          reason: reason ?? 'Booking cancelled',
        );

        if (!refundResult.isSuccess) {
          return CancellationResult.failure(
            'Failed to process refund: ${refundResult.errorMessage}',
          );
        }
        refundId = refundResult.refundId;
      }

      // Update booking status
      final cancelledBooking = booking.copyWith(
        status: BookingStatus.cancelled,
        cancelledAt: DateTime.now(),
        cancellationReason: reason,
        refundId: refundId,
      );

      await _bookingsRepository.updateBooking(cancelledBooking);

      // Send cancellation notification
      await _notificationService.sendBookingCancellation(
        organizerId: userId,
        booking: cancelledBooking,
        refundAmount: refundCalculation.refundAmount,
      );

      return CancellationResult.success(
        booking: cancelledBooking,
        refundAmount: refundCalculation.refundAmount,
        refundId: refundId,
      );

    } catch (e, stackTrace) {
      debugPrint('Error cancelling booking: $e\n$stackTrace');
      return CancellationResult.failure('Failed to cancel booking: $e');
    }
  }

  // REFUND CALCULATIONS
  Future<RefundCalculation> _calculateRefundAmount(
    VenueBooking booking,
    CancellationPolicy policy,
  ) async {
    final timeUntilGame = booking.dateTime.difference(DateTime.now());
    final totalAmount = booking.totalAmount;

    // Full refund if within policy window
    if (timeUntilGame >= policy.fullRefundWindow) {
      return RefundCalculation(
        refundAmount: totalAmount,
        refundPercentage: 1.0,
        fees: 0.0,
        reason: 'Full refund - cancelled within policy window',
      );
    }

    // Partial refund based on policy tiers
    for (final tier in policy.partialRefundTiers) {
      if (timeUntilGame >= tier.minimumNotice) {
        final refundAmount = totalAmount * tier.refundPercentage;
        final fees = totalAmount - refundAmount;
        
        return RefundCalculation(
          refundAmount: refundAmount,
          refundPercentage: tier.refundPercentage,
          fees: fees,
          reason: tier.description,
        );
      }
    }

    // No refund
    return RefundCalculation(
      refundAmount: 0.0,
      refundPercentage: 0.0,
      fees: totalAmount,
      reason: 'No refund - cancelled too close to game time',
    );
  }

  // CANCELLATION POLICY CHECKS
  CancellationCheck _canCancelBooking(
    VenueBooking booking,
    CancellationPolicy policy,
  ) {
    // Check if booking is already cancelled
    if (booking.status == BookingStatus.cancelled) {
      return CancellationCheck(
        allowed: false,
        reason: 'Booking is already cancelled',
      );
    }

    // Check if game has already started
    if (booking.dateTime.isBefore(DateTime.now())) {
      return CancellationCheck(
        allowed: false,
        reason: 'Cannot cancel - game has already started',
      );
    }

    // Check against minimum cancellation window
    final timeUntilGame = booking.dateTime.difference(DateTime.now());
    if (timeUntilGame < policy.minimumCancellationNotice) {
      return CancellationCheck(
        allowed: false,
        reason: 'Cannot cancel - minimum notice period not met (${policy.minimumCancellationNotice.inHours} hours required)',
      );
    }

    return CancellationCheck(allowed: true);
  }

  // POLICY MANAGEMENT
  Future<CancellationPolicy> _getCancellationPolicy(String venueId) async {
    try {
      // Use the injected service to get venue-specific policy
      return await _cancellationPolicyService.getPolicyForVenue(venueId);
    } catch (e) {
      // Fallback to default policy if service fails
      debugPrint('Failed to fetch cancellation policy for venue $venueId: $e');
      return CancellationPolicy.defaultPolicy();
    }
  }

  // BOOKING QUERIES
  Future<List<VenueBooking>> getUserBookings({
    required String userId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _bookingsRepository.getUserBookings(
      userId: userId,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<VenueBooking?> getBookingById(String bookingId) async {
    return await _bookingsRepository.getBookingById(bookingId);
  }

  // HELPER METHODS
  ConflictType _determineConflictType(
    DateTime newStart,
    DateTime newEnd,
    VenueBooking existingBooking,
  ) {
    final existingStart = existingBooking.dateTime;
    final existingEnd = existingBooking.dateTime.add(existingBooking.duration);

    if (newStart == existingStart && newEnd == existingEnd) {
      return ConflictType.exactOverlap;
    } else if (newStart.isBefore(existingStart) && newEnd.isAfter(existingEnd)) {
      return ConflictType.contains;
    } else if (newStart.isAfter(existingStart) && newEnd.isBefore(existingEnd)) {
      return ConflictType.containedBy;
    } else if (newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart)) {
      return ConflictType.partialOverlap;
    }

    return ConflictType.partialOverlap;
  }

  String _generateBookingId() {
    return 'booking_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// Result classes
abstract class BookingResult {
  final bool isSuccess;
  final String? error;

  BookingResult._(this.isSuccess, this.error);

  factory BookingResult.success({required VenueBooking booking}) = BookingSuccess;
  factory BookingResult.conflict({
    required List<BookingConflict> conflicts,
    required List<DateTime> suggestedAlternatives,
  }) = BookingConflictResult;
  factory BookingResult.failure({
    required String error,
    List<DateTime>? suggestedAlternatives,
  }) = BookingFailure;
}

class BookingSuccess extends BookingResult {
  final VenueBooking booking;

  BookingSuccess({required this.booking}) : super._(true, null);
}

class BookingConflictResult extends BookingResult {
  final List<BookingConflict> conflicts;
  final List<DateTime> suggestedAlternatives;

  BookingConflictResult({
    required this.conflicts,
    required this.suggestedAlternatives,
  }) : super._(false, 'Booking conflicts detected');
}

class BookingFailure extends BookingResult {
  final List<DateTime>? suggestedAlternatives;

  BookingFailure({
    required String error,
    this.suggestedAlternatives,
  }) : super._(false, error);
}

class ConflictResolutionResult {
  final bool hasConflicts;
  final List<BookingConflict> conflicts;
  final List<DateTime> alternatives;

  ConflictResolutionResult({
    required this.hasConflicts,
    required this.conflicts,
    required this.alternatives,
  });
}

class AutoResolveResult {
  final bool isSuccess;
  final DateTime? newDateTime;
  final String? error;

  AutoResolveResult._(this.isSuccess, this.newDateTime, this.error);

  factory AutoResolveResult.success({DateTime? newDateTime}) {
    return AutoResolveResult._(true, newDateTime, null);
  }

  factory AutoResolveResult.failure(String error) {
    return AutoResolveResult._(false, null, error);
  }
}

class CancellationResult {
  final bool isSuccess;
  final String? error;
  final VenueBooking? booking;
  final double? refundAmount;
  final String? refundId;

  CancellationResult._({
    required this.isSuccess,
    this.error,
    this.booking,
    this.refundAmount,
    this.refundId,
  });

  factory CancellationResult.success({
    required VenueBooking booking,
    required double refundAmount,
    String? refundId,
  }) {
    return CancellationResult._(
      isSuccess: true,
      booking: booking,
      refundAmount: refundAmount,
      refundId: refundId,
    );
  }

  factory CancellationResult.failure(String error) {
    return CancellationResult._(isSuccess: false, error: error);
  }
}

class RefundCalculation {
  final double refundAmount;
  final double refundPercentage;
  final double fees;
  final String reason;

  RefundCalculation({
    required this.refundAmount,
    required this.refundPercentage,
    required this.fees,
    required this.reason,
  });
}

class CancellationCheck {
  final bool allowed;
  final String? reason;

  CancellationCheck({
    required this.allowed,
    this.reason,
  });
}

// Data classes
class BookingConflict {
  final VenueBooking conflictingBooking;
  final DateTime overlapStart;
  final DateTime overlapEnd;
  final ConflictType conflictType;

  BookingConflict({
    required this.conflictingBooking,
    required this.overlapStart,
    required this.overlapEnd,
    required this.conflictType,
  });
}

class VenueBooking {
  final String id;
  final String gameId;
  final String venueId;
  final String organizerId;
  final DateTime dateTime;
  final Duration duration;
  final BookingStatus status;
  final String paymentId;
  final double totalAmount;
  final CancellationPolicy cancellationPolicy;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? refundId;

  VenueBooking({
    required this.id,
    required this.gameId,
    required this.venueId,
    required this.organizerId,
    required this.dateTime,
    required this.duration,
    required this.status,
    required this.paymentId,
    required this.totalAmount,
    required this.cancellationPolicy,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
    this.refundId,
  });

  VenueBooking copyWith({
    String? id,
    String? gameId,
    String? venueId,
    String? organizerId,
    DateTime? dateTime,
    Duration? duration,
    BookingStatus? status,
    String? paymentId,
    double? totalAmount,
    CancellationPolicy? cancellationPolicy,
    DateTime? createdAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? refundId,
  }) {
    return VenueBooking(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      venueId: venueId ?? this.venueId,
      organizerId: organizerId ?? this.organizerId,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      totalAmount: totalAmount ?? this.totalAmount,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      refundId: refundId ?? this.refundId,
    );
  }
}

class CancellationPolicy {
  final Duration minimumCancellationNotice;
  final Duration fullRefundWindow;
  final List<RefundTier> partialRefundTiers;

  CancellationPolicy({
    required this.minimumCancellationNotice,
    required this.fullRefundWindow,
    required this.partialRefundTiers,
  });

  factory CancellationPolicy.defaultPolicy() {
    return CancellationPolicy(
      minimumCancellationNotice: const Duration(hours: 2),
      fullRefundWindow: const Duration(hours: 24),
      partialRefundTiers: [
        RefundTier(
          minimumNotice: const Duration(hours: 12),
          refundPercentage: 0.75,
          description: '75% refund - cancelled 12+ hours before',
        ),
        RefundTier(
          minimumNotice: const Duration(hours: 4),
          refundPercentage: 0.50,
          description: '50% refund - cancelled 4+ hours before',
        ),
        RefundTier(
          minimumNotice: const Duration(hours: 2),
          refundPercentage: 0.25,
          description: '25% refund - cancelled 2+ hours before',
        ),
      ],
    );
  }
}

class RefundTier {
  final Duration minimumNotice;
  final double refundPercentage;
  final String description;

  RefundTier({
    required this.minimumNotice,
    required this.refundPercentage,
    required this.description,
  });
}

// Enums
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

enum ConflictType {
  exactOverlap,
  partialOverlap,
  contains,
  containedBy,
}

// Placeholder classes
class PaymentDetails {
  final String cardToken;
  final String? billingAddress;

  PaymentDetails({
    required this.cardToken,
    this.billingAddress,
  });
}

class PaymentIntent {
  final String id;
  final double amount;

  PaymentIntent({required this.id, required this.amount});
}

class PaymentResult {
  final bool isSuccess;
  final String? paymentId;
  final String? errorMessage;
  final String? refundId;

  PaymentResult._({
    required this.isSuccess,
    this.paymentId,
    this.errorMessage,
    this.refundId,
  });

  factory PaymentResult.success({required String paymentId}) {
    return PaymentResult._(isSuccess: true, paymentId: paymentId);
  }

  factory PaymentResult.failure(String error) {
    return PaymentResult._(isSuccess: false, errorMessage: error);
  }

  factory PaymentResult.refundSuccess({required String refundId}) {
    return PaymentResult._(isSuccess: true, refundId: refundId);
  }
}

class Venue {
  final String id;
  final String name;

  Venue({required this.id, required this.name});
}

// Abstract dependencies
abstract class BookingsRepository {
  Future<VenueBooking> createBooking(VenueBooking booking);
  Future<VenueBooking?> getBookingById(String bookingId);
  Future<VenueBooking> updateBooking(VenueBooking booking);
  Future<List<VenueBooking>> getVenueBookings({
    required String venueId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeGameId,
  });
  Future<List<VenueBooking>> getUserBookings({
    required String userId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });
}

abstract class PaymentService {
  Future<PaymentIntent> createPaymentIntent({
    required double amount,
    required String currency,
    Map<String, String>? metadata,
  });
  Future<PaymentResult> processPayment({
    required String paymentIntentId,
    required PaymentDetails paymentDetails,
  });
  Future<PaymentResult> processRefund({
    required String paymentId,
    required double amount,
    String? reason,
  });
}

abstract class VenuesService {
  Future<dynamic> calculateDynamicPricing({
    required String venueId,
    required DateTime dateTime,
    required Duration duration,
    required String sport,
  });
  Future<dynamic> checkAvailability({
    required String venueId,
    required DateTime dateTime,
    required Duration duration,
  });
  Future<Venue?> getVenueById(String venueId);
}

abstract class NotificationService {
  Future<void> sendBookingConfirmation({
    required String organizerId,
    required VenueBooking booking,
    required Venue? venue,
  });
  Future<void> sendBookingCancellation({
    required String organizerId,
    required VenueBooking booking,
    required double refundAmount,
  });
}

abstract class CancellationPolicyService {
  Future<CancellationPolicy> getPolicyForVenue(String venueId);
}
