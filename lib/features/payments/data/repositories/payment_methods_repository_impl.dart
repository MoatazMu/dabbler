import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_methods_repository.dart';
import '../datasources/payment_methods_datasource.dart';
import '../models/payment_method_model.dart';

/// Implementation of payment methods repository
class PaymentMethodsRepositoryImpl implements PaymentMethodsRepository {
  final PaymentMethodsDataSource dataSource;

  PaymentMethodsRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods(String userId) async {
    try {
      final models = await dataSource.getPaymentMethods(userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on PaymentMethodsException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get payment methods: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaymentMethod?>> getDefaultPaymentMethod(String userId) async {
    try {
      final model = await dataSource.getDefaultPaymentMethod(userId);
      return Right(model?.toEntity());
    } on PaymentMethodsException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get default payment method: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      final model = PaymentMethodModel.fromEntity(paymentMethod);
      final result = await dataSource.addPaymentMethod(model);
      return Right(result.toEntity());
    } on PaymentMethodsException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to add payment method: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> updatePaymentMethod(PaymentMethod paymentMethod) async {
    try {
      final model = PaymentMethodModel.fromEntity(paymentMethod);
      final result = await dataSource.updatePaymentMethod(model);
      return Right(result.toEntity());
    } on PaymentMethodsException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update payment method: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePaymentMethod(String paymentMethodId) async {
    try {
      await dataSource.deletePaymentMethod(paymentMethodId);
      return const Right(null);
    } on PaymentMethodsException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete payment method: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultPaymentMethod(String userId, String paymentMethodId) async {
    try {
      await dataSource.setDefaultPaymentMethod(userId, paymentMethodId);
      return const Right(null);
    } on PaymentMethodsException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to set default payment method: ${e.toString()}'));
    }
  }
}
