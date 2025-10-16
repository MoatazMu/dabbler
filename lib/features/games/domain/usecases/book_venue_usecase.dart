import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/authentication/domain/usecases/usecase.dart';
import '../entities/booking.dart';
import '../entities/venue.dart';
import '../repositories/bookings_repository.dart';
import '../repositories/venues_repository.dart';

// Game-specific failures
class GameFailure extends Failure {
  const GameFailure(super.message);
}

class BookVenueUseCase extends UseCase<Either<Failure, BookingResult>, BookVenueParams> {
  final BookingsRepository bookingsRepository;
  final VenuesRepository venuesRepository;

  BookVenueUseCase({
    required this.bookingsRepository,
    required this.venuesRepository,
  });

  @override
  Future<Either<Failure, BookingResult>> call(BookVenueParams params) async {
    // Validate parameters
    final validationResult = await _validateBookingParameters(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Get venue details
    final venueResult = await venuesRepository.getVenue(params.venueId);
    
    return venueResult.fold(
      (failure) => Left(failure),
      (venue) async {
        // Check venue availability
        final availabilityResult = await _checkVenueAvailability(params, venue);
        if (availabilityResult != null) {
          return Left(availabilityResult);
        }

        // Calculate total cost
        final costCalculation = await _calculateTotalCost(params, venue);
        if (costCalculation.isLeft()) {
          return Left(costCalculation.fold((l) => l, (r) => throw Exception()));
        }
        final totalCost = costCalculation.fold((l) => 0.0, (r) => r);

        // Create booking record
        final bookingData = _buildBookingData(params, venue, totalCost);
        final bookingResult = await bookingsRepository.createBooking(bookingData);
        
        return bookingResult.fold(
          (failure) => Left(failure),
          (booking) async {
            // Process payment (stub for now)
            final paymentResult = await _processPayment(booking, totalCost, params);
            if (paymentResult != null) {
              // Cancel the booking if payment fails
              await bookingsRepository.cancelBooking(booking.id, 'Payment failed');
              return Left(paymentResult);
            }

            return Right(BookingResult(
              booking: booking,
              totalCost: totalCost,
              paymentStatus: PaymentStatus.paid,
              confirmationMessage: _getConfirmationMessage(booking, venue),
            ));
          },
        );
      },
    );
  }

  /// Validates booking parameters
  Future<Failure?> _validateBookingParameters(BookVenueParams params) async {
    // Check required fields
    if (params.venueId.trim().isEmpty) {
      return const GameFailure('Venue ID cannot be empty');
    }

    if (params.userId.trim().isEmpty) {
      return const GameFailure('User ID cannot be empty');
    }

    // Validate date is not in the past
    final bookingDateTime = DateTime(
      params.date.year,
      params.date.month,
      params.date.day,
    ).add(_parseTime(params.startTime));

    if (bookingDateTime.isBefore(DateTime.now())) {
      return const GameFailure('Cannot book venue slots in the past');
    }

    // Validate time format and logic
    final startTime = _parseTime(params.startTime);
    final endTime = _parseTime(params.endTime);

    if (endTime.inMinutes <= startTime.inMinutes) {
      return const GameFailure('End time must be after start time');
    }

    // Validate duration limits
    final durationMinutes = params.durationMinutes;
    if (durationMinutes < 30) {
      return const GameFailure('Minimum booking duration is 30 minutes');
    }

    if (durationMinutes > 480) { // 8 hours
      return const GameFailure('Maximum booking duration is 8 hours');
    }

    // Validate calculated end time matches duration
    final calculatedEndMinutes = startTime.inMinutes + durationMinutes;
    final actualEndMinutes = endTime.inMinutes;
    
    if ((calculatedEndMinutes - actualEndMinutes).abs() > 1) { // Allow 1 minute tolerance
      return const GameFailure('Duration does not match start and end times');
    }

    return null;
  }

  /// Checks if venue is available for the requested time slot
  Future<Failure?> _checkVenueAvailability(BookVenueParams params, Venue venue) async {
    // For now, we'll assume all venues are active since isActive property doesn't exist
    // In a real implementation, you might add status checking
    
    // Check venue operating hours
    if (!_isWithinOperatingHours(params.startTime, params.endTime, venue)) {
      return const GameFailure('Requested time is outside venue operating hours');
    }
    // This would require venue entity to have operating hours
    
    // Check for booking conflicts
    final conflictsResult = await bookingsRepository.getBookingConflicts(
      params.venueId,
      params.date,
      params.startTime,
      params.endTime,
    );

    return conflictsResult.fold(
      (failure) => failure, // Return the failure as-is
      (conflicts) {
        if (conflicts.isNotEmpty) {
          return const GameFailure('The requested time slot is not available');
        }
        
        // Check specific court/field availability if specified
        if (params.courtNumber != null) {
          final courtConflicts = conflicts.where(
            (booking) => booking.courtNumber == params.courtNumber
          ).toList();
          
          if (courtConflicts.isNotEmpty) {
            return GameFailure('Court ${params.courtNumber} is not available at the requested time');
          }
        }
        
        return null; // No conflicts found
      },
    );
  }

  /// Calculates the total cost for the booking
  Future<Either<Failure, double>> _calculateTotalCost(BookVenueParams params, Venue venue) async {
    try {
      double baseCost = 0.0;
      
      // Calculate base cost based on venue pricing
      // This is a simplified calculation - real implementation would be more complex
      final durationHours = params.durationMinutes / 60.0;
      
      // Use venue's pricePerHour property
      baseCost = venue.pricePerHour * durationHours;

      // Apply peak hour multiplier (if applicable)
      final startHour = _parseTime(params.startTime).inHours;
      if (_isPeakHour(startHour)) {
        baseCost *= 1.5; // 50% surcharge for peak hours
      }

      // Apply weekend multiplier
      if (_isWeekend(params.date)) {
        baseCost *= 1.25; // 25% surcharge for weekends
      }

      // Court-specific pricing not available in current Venue entity
      // In a real implementation, you might extend the venue entity or
      // store court-specific rates separately

      // Add taxes and fees
      final tax = baseCost * 0.1; // 10% tax
      final serviceFee = 2.0; // $2 service fee
      
      final totalCost = baseCost + tax + serviceFee;

      return Right(totalCost);
    } catch (e) {
      return Left(GameFailure('Failed to calculate booking cost: ${e.toString()}'));
    }
  }

  /// Processes payment for the booking (stub implementation)
  Future<Failure?> _processPayment(Booking booking, double amount, BookVenueParams params) async {
    try {
      // This is a stub implementation
      // In a real app, this would integrate with payment providers like:
      // - Stripe
      // - PayPal
      // - Apple Pay / Google Pay
      // - Local payment gateways
      
      print('Processing payment of \$${amount.toStringAsFixed(2)} for booking ${booking.id}');
      
      // Simulate payment processing
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simulate payment success/failure based on some logic
      // In real implementation, this would handle actual payment processing
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      final paymentSuccess = random > 5; // 95% success rate for simulation
      
      if (!paymentSuccess) {
        return const GameFailure('Payment processing failed. Please try again or use a different payment method.');
      }

      // Update booking payment status
      await bookingsRepository.updatePaymentStatus(
        booking.id,
        PaymentStatus.paid,
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      );

      return null; // Success
    } catch (e) {
      return GameFailure('Payment processing error: ${e.toString()}');
    }
  }

  /// Builds booking data for creation
  Map<String, dynamic> _buildBookingData(BookVenueParams params, Venue venue, double totalCost) {
    return {
      'userId': params.userId,
      'venueId': params.venueId,
      'date': params.date.toIso8601String(),
      'startTime': params.startTime,
      'endTime': params.endTime,
      'durationMinutes': params.durationMinutes,
      'sport': params.sport,
      'courtNumber': params.courtNumber,
      'totalCost': totalCost,
      'status': BookingStatus.confirmed,
      'paymentStatus': PaymentStatus.pending,
      'bookingType': 'venue_rental',
      'notes': params.notes,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Gets confirmation message for successful booking
  String _getConfirmationMessage(Booking booking, Venue venue) {
    return 'Your booking at ${venue.name} has been confirmed! '
           'Booking ID: ${booking.id}. '
           'You will receive a confirmation email shortly.';
  }

  /// Utility methods
  Duration _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) {
      throw const GameFailure('Invalid time format. Use HH:mm');
    }
    
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    
    if (hours == null || minutes == null || hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
      throw const GameFailure('Invalid time format. Use HH:mm (24-hour format)');
    }
    
    return Duration(hours: hours, minutes: minutes);
  }

  bool _isPeakHour(int hour) {
    // Peak hours: 6-9 AM and 5-10 PM
    return (hour >= 6 && hour <= 9) || (hour >= 17 && hour <= 22);
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  bool _isWithinOperatingHours(String startTime, String endTime, Venue venue) {
    try {
      final startMinutes = _parseTime(startTime).inMinutes;
      final endMinutes = _parseTime(endTime).inMinutes;
      final openingMinutes = _parseTime(venue.openingTime).inMinutes;
      final closingMinutes = _parseTime(venue.closingTime).inMinutes;
      
      return startMinutes >= openingMinutes && endMinutes <= closingMinutes;
    } catch (e) {
      // If time parsing fails, allow the booking and let venue handle it
      return true;
    }
  }
}

class BookVenueParams {
  final String userId;
  final String venueId;
  final DateTime date;
  final String startTime; // Format: "HH:mm"
  final String endTime;   // Format: "HH:mm"
  final int durationMinutes;
  final String? sport;
  final String? courtNumber;
  final String? notes;

  BookVenueParams({
    required this.userId,
    required this.venueId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.sport,
    this.courtNumber,
    this.notes,
  });
}

class BookingResult {
  final Booking booking;
  final double totalCost;
  final PaymentStatus paymentStatus;
  final String confirmationMessage;

  BookingResult({
    required this.booking,
    required this.totalCost,
    required this.paymentStatus,
    required this.confirmationMessage,
  });

  // Convenience getters
  String get formattedCost => '\$${totalCost.toStringAsFixed(2)}';
  bool get isSuccessful => paymentStatus == PaymentStatus.paid;
}
