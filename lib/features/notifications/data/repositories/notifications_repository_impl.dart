import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_datasource.dart';
import '../models/notification_model.dart';

/// Implementation of notifications repository
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsDataSource dataSource;

  NotificationsRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<Notification>>> getNotifications(String userId) async {
    try {
      final models = await dataSource.getNotifications(userId);
      return Right(models.map((m) => m.toEntity()).toList().cast<Notification>());
    } on NotificationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get notifications: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getUnreadNotifications(String userId) async {
    try {
      final models = await dataSource.getUnreadNotifications(userId);
      return Right(models.map((m) => m.toEntity()).toList().cast<Notification>());
    } on NotificationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get unread notifications: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getNotificationsByType(
    String userId,
    NotificationType type,
  ) async {
    try {
      final models = await dataSource.getNotificationsByType(userId, type.value);
      return Right(models.map((m) => m.toEntity()).toList());
    } on NotificationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get notifications by type: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await dataSource.markAsRead(notificationId);
      return const Right(null);
    } on NotificationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to mark notification as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      await dataSource.markAllAsRead(userId);
      return const Right(null);
    } on NotificationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to mark all as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    try {
      await dataSource.deleteNotification(notificationId);
      return const Right(null);
    } on NotificationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete notification: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllNotifications(String userId) async {
    try {
      await dataSource.deleteAllNotifications(userId);
      return const Right(null);
    } on NotificationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to delete all notifications: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Notification>> createNotification(Notification notification) async {
    try {
      final model = NotificationModel.fromEntity(notification);
      final result = await dataSource.createNotification(model);
      return Right(result.toEntity());
    } on NotificationException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create notification: ${e.toString()}'));
    }
  }
}
