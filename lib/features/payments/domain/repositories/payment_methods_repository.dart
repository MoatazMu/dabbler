import 'package:fpdart/fpdart.dart';
import 'package:dabbler/core/fp/failure.dart';
import '../entities/payment_method.dart';

/// Payment methods repository interface
abstract class PaymentMethodsRepository {
  /// Get all payment methods for a user
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods(String userId);

  /// Get the default payment method for a user
  Future<Either<Failure, PaymentMethod?>> getDefaultPaymentMethod(String userId);

  /// Add a new payment method
  Future<Either<Failure, PaymentMethod>> addPaymentMethod(PaymentMethod paymentMethod);

  /// Update an existing payment method
  Future<Either<Failure, PaymentMethod>> updatePaymentMethod(PaymentMethod paymentMethod);

  /// Delete a payment method
  Future<Either<Failure, void>> deletePaymentMethod(String paymentMethodId);

  /// Set a payment method as default
  Future<Either<Failure, void>> setDefaultPaymentMethod(String userId, String paymentMethodId);
}
